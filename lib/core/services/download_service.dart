import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/download_task_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'social_media_downloader_service.dart';
import 'permission_service.dart';

class DownloadService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: AppConstants.networkTimeoutSeconds),
    receiveTimeout: Duration(minutes: AppConstants.receiveTimeoutMinutes),
    sendTimeout: Duration(seconds: AppConstants.networkTimeoutSeconds),
    followRedirects: true,
    maxRedirects: 5,
    validateStatus: (status) => status != null && status >= 200 && status < 300,
  ));
  static final YoutubeExplode _youtube = YoutubeExplode();
  static final Map<String, CancelToken> _cancelTokens = {};

  static Future<String?> downloadVideo({
    required DownloadTaskModel task,
    required Function(int) onProgress,
  }) async {
    try {
      print('=== Starting download for: ${task.title} ===');
      
      // Check storage permission first
      final hasPermission = await PermissionService.hasStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission not granted');
      }
      
      final fileName = StorageService.sanitizeFileName(
        '${task.title}_${task.quality}',
      );
      final extension = task.type == DownloadType.audio ? 'mp3' : 'mp4';
      print('File name: $fileName.$extension');

      final cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      await NotificationService.showDownloadStartedNotification(
        id: task.notificationId,
        title: task.title,
      );

      String? downloadUrl = await _getDownloadUrl(task);
      
      if (downloadUrl == null || downloadUrl.isEmpty) {
        throw Exception('Could not extract download URL');
      }
      
      // Validate URL
      if (!_isValidDownloadUrl(downloadUrl)) {
        throw Exception('Invalid or unsafe download URL');
      }
      
      print('Starting download from: ${downloadUrl.substring(0, downloadUrl.length > 50 ? 50 : downloadUrl.length)}...');

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName.$extension';
      
      await _downloadWithRetry(downloadUrl, tempPath, cancelToken, task, onProgress);
      
      // Validate downloaded file
      final file = File(tempPath);
      if (!await file.exists()) {
        throw Exception('Download failed - file not created');
      }
      
      if (!await _validateDownloadedFile(file, task.type)) {
        await file.delete();
        throw Exception('Downloaded file validation failed');
      }
      
      // Save to Downloads folder with streaming
      final filePath = await _saveFileToDownloads(file, fileName, extension, task.type);
      
      if (filePath == null) {
        throw Exception('Failed to save file to downloads folder');
      }
      
      // Clean up temp file
      await _cleanupTempFile(file);

      await NotificationService.showDownloadCompletedNotification(
        id: task.notificationId,
        title: task.title,
      );

      _cancelTokens.remove(task.id);
      return filePath;
    } catch (e, stackTrace) {
      print('=== DOWNLOAD FAILED ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      await NotificationService.showDownloadFailedNotification(
        id: task.notificationId,
        title: task.title,
        error: e.toString(),
      );

      _cancelTokens.remove(task.id);
      rethrow; // Re-throw to let controller handle it
    }
  }

  static Future<String?> _getDownloadUrl(DownloadTaskModel task) async {
    if (task.platform == 'YouTube') {
      return await _getYouTubeDownloadUrl(task);
    } else if (SocialMediaDownloaderService.isSupportedPlatform(task.url)) {
      print('Fetching download URL for ${task.platform}...');
      final videoData = await SocialMediaDownloaderService.getVideoData(task.url);
      
      if (videoData != null) {
        print('Video data received, extracting download URL...');
        final url = SocialMediaDownloaderService.extractDownloadUrl(
          videoData,
          quality: task.quality,
        );
        
        if (url == null || url.isEmpty) {
          print('Failed to extract download URL from video data');
          print('Video data keys: ${videoData.keys.toList()}');
          throw Exception('Could not extract download URL from ${task.platform}');
        }
        
        if (_isHLSStream(url)) {
          throw Exception('HLS streams are not supported for direct download');
        }
        
        print('Download URL extracted successfully');
        return url;
      } else {
        print('Video data is null');
        throw Exception('Failed to fetch video data from ${task.platform}');
      }
    }
    return task.url;
  }

  static bool _isValidDownloadUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty &&
             !url.contains('..') && // Prevent path traversal
             !url.contains('localhost') && // Prevent local access
             !url.contains('127.0.0.1');
    } catch (e) {
      return false;
    }
  }

  static Future<void> _downloadWithRetry(
    String url, 
    String path, 
    CancelToken cancelToken, 
    DownloadTaskModel task,
    Function(int) onProgress
  ) async {
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        await _dio.download(
          url,
          path,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              // Check file size limit
              if (received > AppConstants.maxFileSizeMB * 1024 * 1024) {
                cancelToken.cancel('File too large');
                return;
              }
              
              final progress = ((received / total) * 100).toInt();
              onProgress(progress);
              
              NotificationService.showDownloadProgressNotification(
                id: task.notificationId,
                title: task.title,
                progress: progress,
              );
            }
          },
        );
        return; // Success
      } catch (e) {
        retries++;
        if (_isPermanentError(e) || retries >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: retries * 2));
      }
    }
  }

  static bool _isPermanentError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode != null && (statusCode == 404 || statusCode == 403 || statusCode == 401);
    }
    return false;
  }

  static Future<bool> _validateDownloadedFile(File file, DownloadType type) async {
    try {
      if (!await file.exists()) return false;
      
      final size = await file.length();
      if (size == 0 || size > AppConstants.maxFileSizeMB * 1024 * 1024) {
        return false;
      }

      // Basic content type validation by reading first few bytes
      final bytes = await file.openRead(0, 12).toList();
      final header = bytes.expand((x) => x).toList();
      
      if (type == DownloadType.video) {
        // Check for common video file signatures
        return _isValidVideoFile(header);
      } else {
        // Check for common audio file signatures
        return _isValidAudioFile(header);
      }
    } catch (e) {
      return false;
    }
  }

  static bool _isValidVideoFile(List<int> header) {
    if (header.length < 12) return false;
    
    // MP4 signature
    if (header[4] == 0x66 && header[5] == 0x74 && header[6] == 0x79 && header[7] == 0x70) {
      return true;
    }
    
    // WebM signature
    if (header[0] == 0x1A && header[1] == 0x45 && header[2] == 0xDF && header[3] == 0xA3) {
      return true;
    }
    
    return false;
  }

  static bool _isValidAudioFile(List<int> header) {
    if (header.length < 4) return false;
    
    // MP3 signature
    if (header[0] == 0xFF && (header[1] & 0xE0) == 0xE0) {
      return true;
    }
    
    // MP4 audio
    if (header.length >= 8 && header[4] == 0x66 && header[5] == 0x74 && header[6] == 0x79 && header[7] == 0x70) {
      return true;
    }
    
    return false;
  }

  static Future<String?> _saveFileToDownloads(File tempFile, String fileName, String extension, DownloadType type) async {
    try {
      print('Saving file: $fileName.$extension');
      
      // Read file as bytes
      final bytes = await tempFile.readAsBytes();
      print('File size: ${bytes.length} bytes');
      
      if (bytes.isEmpty) {
        throw Exception('Downloaded file is empty');
      }
      
      final savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        ext: extension,
        mimeType: type == DownloadType.audio ? MimeType.mpeg : MimeType.other,
      );
      
      print('File saved to: $savedPath');
      return savedPath;
    } catch (e, stackTrace) {
      print('Error saving file: $e');
      print('Stack trace: $stackTrace');
      
      // Fallback: try to save to app directory
      try {
        print('Attempting fallback save method...');
        final appDir = await getApplicationDocumentsDirectory();
        final fallbackPath = '${appDir.path}/$fileName.$extension';
        await tempFile.copy(fallbackPath);
        print('File saved to fallback location: $fallbackPath');
        return fallbackPath;
      } catch (fallbackError) {
        print('Fallback save also failed: $fallbackError');
        return null;
      }
    }
  }

  static Future<void> _cleanupTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Warning: Failed to delete temp file: $e');
      // Don't throw - this is not critical
    }
  }

  static Future<String?> _getYouTubeDownloadUrl(DownloadTaskModel task) async {
    try {
      final normalizedUrl = _normalizeYouTubeUrl(task.url);
      final manifest = await _youtube.videos.streamsClient.getManifest(normalizedUrl);

      if (task.type == DownloadType.audio) {
        final audioStreams = manifest.audioOnly.sortByBitrate();
        if (audioStreams.isNotEmpty) {
          return audioStreams.first.url.toString();
        }
      } else {
        // Prioritize muxed streams to avoid silent videos
        final muxedStreams = manifest.muxed;
        final muxedMatch = muxedStreams
            .where((s) => s.videoQuality.name.contains(task.quality))
            .firstOrNull;
        
        if (muxedMatch != null) {
          return muxedMatch.url.toString();
        }
        
        if (muxedStreams.isNotEmpty) {
          return muxedStreams.sortByVideoQuality().first.url.toString();
        }
      }

      return null;
    } catch (e) {
      print('Error getting YouTube download URL: $e');
      return null;
    }
  }
  
  static String _normalizeYouTubeUrl(String url) {
    final uri = Uri.parse(url);
    
    if (url.contains('/shorts/')) {
      final shortsMatch = RegExp(r'/shorts/([A-Za-z0-9_-]+)').firstMatch(url);
      if (shortsMatch != null) {
        final videoId = shortsMatch.group(1);
        return 'https://www.youtube.com/watch?v=$videoId';
      }
    }
    
    if (url.contains('youtu.be/')) {
      final youtubeMatch = RegExp(r'youtu\.be/([A-Za-z0-9_-]+)').firstMatch(url);
      if (youtubeMatch != null) {
        final videoId = youtubeMatch.group(1);
        return 'https://www.youtube.com/watch?v=$videoId';
      }
    }
    
    if (uri.queryParameters.containsKey('v')) {
      final videoId = uri.queryParameters['v'];
      return 'https://www.youtube.com/watch?v=$videoId';
    }
    
    return url;
  }
  
  static bool _isHLSStream(String url) {
    return url.contains('.m3u8') || url.contains('/hls/') || url.contains('manifest');
  }

  static void pauseDownload(String taskId) {
    final cancelToken = _cancelTokens[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download paused');
    }
  }

  static void cancelDownload(String taskId) {
    final cancelToken = _cancelTokens[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download cancelled');
      _cancelTokens.remove(taskId);
    }
  }

  static void dispose() {
    _youtube.close();
  }
}