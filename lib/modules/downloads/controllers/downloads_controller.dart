import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/permission_service.dart';
import '../../../data/models/video_info_model.dart';
import '../../../data/models/download_task_model.dart';
import '../../../data/models/download_model.dart';
import '../../../core/services/download_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/storage_service.dart';
import 'dart:async';

class DownloadsController extends GetxController {
  final activeDownloads = <DownloadTaskModel>[].obs;
  final downloadHistory = <DownloadModel>[].obs;
  final _uuid = const Uuid();
  int _notificationIdCounter = 1000;

  @override
  void onInit() {
    super.onInit();
    loadDownloadHistory();
  }

  Future<void> loadDownloadHistory() async {
    try {
      final history = await DatabaseService.getDownloadHistory();
      downloadHistory.value = history;
    } catch (e) {
      print('Error loading download history: $e');
    }
  }

  Future<void> refreshDownloads() async {
    await loadDownloadHistory();
  }

  Future<void> startDownload({
    required VideoInfoModel videoInfo,
    required DownloadType type,
    required String quality,
  }) async {
    try {
      // Check storage permission first
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        Get.snackbar(
          'Permission Required',
          'Storage permission is needed to download files',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }
      
      // Check for duplicate
      final existingDownload = await DatabaseService.findDownloadByUrl(videoInfo.url);

      if (existingDownload != null &&
          existingDownload.type == (type == DownloadType.audio ? 'audio' : 'video') &&
          existingDownload.quality == quality) {
        _showDuplicateDialog(videoInfo, type, quality, existingDownload);
        return;
      }

      // Create download task
      final task = DownloadTaskModel(
        id: _uuid.v4(),
        url: videoInfo.url,
        title: videoInfo.title,
        thumbnail: videoInfo.thumbnail,
        type: type,
        quality: quality,
        platform: videoInfo.platform,
        notificationId: _notificationIdCounter++,
      );

      activeDownloads.add(task);

      // Save to database
      final downloadModel = DownloadModel(
        id: task.id,
        url: task.url,
        title: task.title,
        thumbnail: task.thumbnail,
        type: task.typeString,
        quality: task.quality,
        status: 'downloading',
        platform: task.platform,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await DatabaseService.saveDownload(downloadModel);

      // Start download
      _performDownload(task);

      Get.snackbar(
        'Download Started',
        task.title,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start download: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showDuplicateDialog(
    VideoInfoModel videoInfo,
    DownloadType type,
    String quality,
    DownloadModel existingDownload,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Duplicate Download'),
        content: Text(
          'This ${type == DownloadType.audio ? 'audio' : 'video'} already exists.\nDo you want to download it again?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _forceDownload(videoInfo, type, quality);
            },
            child: const Text('Download Again'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _forceDownload(
    VideoInfoModel videoInfo,
    DownloadType type,
    String quality,
  ) async {
    final task = DownloadTaskModel(
      id: _uuid.v4(),
      url: videoInfo.url,
      title: videoInfo.title,
      thumbnail: videoInfo.thumbnail,
      type: type,
      quality: quality,
      platform: videoInfo.platform,
      notificationId: _notificationIdCounter++,
    );

    activeDownloads.add(task);

    final downloadModel = DownloadModel(
      id: task.id,
      url: task.url,
      title: task.title,
      thumbnail: task.thumbnail,
      type: task.typeString,
      quality: task.quality,
      status: 'downloading',
      platform: task.platform,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DatabaseService.saveDownload(downloadModel);
    _performDownload(task);
  }

  Future<void> _performDownload(DownloadTaskModel task) async {
    try {
      task.status = DownloadStatus.downloading;
      activeDownloads.refresh();

      final filePath = await DownloadService.downloadVideo(
        task: task,
        onProgress: (progress) {
          final index = activeDownloads.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            activeDownloads[index].progress = progress;
            activeDownloads.refresh();

            // Update database
            DatabaseService.updateDownloadStatus(
              id: task.id,
              status: 'downloading',
              progress: progress,
            );
          }
        },
      );

      if (filePath != null) {
        // Download completed
        task.status = DownloadStatus.completed;
        task.filePath = filePath;
        task.progress = 100;

        // Update database
        await DatabaseService.updateDownloadStatus(
          id: task.id,
          status: 'completed',
          progress: 100,
          filePath: filePath,
        );

        // Move to history
        activeDownloads.removeWhere((t) => t.id == task.id);
        await loadDownloadHistory();

        Get.snackbar(
          'Download Complete',
          task.title,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        // Download failed
        task.status = DownloadStatus.failed;
        activeDownloads.refresh();

        await DatabaseService.updateDownloadStatus(
          id: task.id,
          status: 'failed',
        );
        
        Get.snackbar(
          'Download Failed',
          'Could not download ${task.title}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      print('Download error: $e');
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      activeDownloads.refresh();

      await DatabaseService.updateDownloadStatus(
        id: task.id,
        status: 'failed',
      );
      
      Get.snackbar(
        'Download Failed',
        e.toString().contains('permission') 
          ? 'Storage permission required'
          : 'Error: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void pauseDownload(String taskId) {
    final index = activeDownloads.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      activeDownloads[index].status = DownloadStatus.paused;
      activeDownloads.refresh();
      DownloadService.pauseDownload(taskId);

      DatabaseService.updateDownloadStatus(
        id: taskId,
        status: 'paused',
      );
    }
  }

  void resumeDownload(String taskId) {
    final index = activeDownloads.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = activeDownloads[index];
      _performDownload(task);
    }
  }

  void cancelDownload(String taskId) {
    final index = activeDownloads.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      activeDownloads[index].status = DownloadStatus.cancelled;
      DownloadService.cancelDownload(taskId);

      DatabaseService.updateDownloadStatus(
        id: taskId,
        status: 'cancelled',
      );

      activeDownloads.removeAt(index);
    }
  }

  void retryDownload(String taskId) {
    final index = activeDownloads.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = activeDownloads[index];
      task.status = DownloadStatus.pending;
      task.progress = 0;
      task.error = null;
      activeDownloads.refresh();
      _performDownload(task);
    }
  }

  Future<void> deleteFromHistory(String downloadId) async {
    try {
      final download = downloadHistory.firstWhereOrNull((d) => d.id == downloadId);
      
      if (download == null) {
        Get.snackbar(
          'Error',
          'Download not found',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Delete file if exists
      if (download.filePath != null && download.filePath!.isNotEmpty) {
        try {
          await StorageService.deleteFile(download.filePath!);
        } catch (e) {
          print('Error deleting file: $e');
        }
      }

      // Delete from database
      await DatabaseService.deleteDownload(downloadId);

      // Remove from list
      downloadHistory.removeWhere((d) => d.id == downloadId);

      Get.snackbar(
        'Deleted',
        'Download removed from history',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error in deleteFromHistory: $e');
      Get.snackbar(
        'Error',
        'Failed to delete download',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void showClearHistoryDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all download history?\nFiles will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              clearHistory();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> clearHistory() async {
    try {
      await DatabaseService.clearDownloadHistory();
      downloadHistory.clear();

      Get.snackbar(
        'History Cleared',
        'Download history has been cleared',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear history',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  Future<bool> _checkStoragePermission() async {
    try {
      return await PermissionService.hasStoragePermission();
    } catch (e) {
      print('Permission check error: $e');
      return false;
    }
  }
}
