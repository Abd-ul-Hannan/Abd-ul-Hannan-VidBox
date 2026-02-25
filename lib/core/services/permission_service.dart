import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static Future<void> requestAllPermissions() async {
    try {
      // Request storage permissions
      await _requestStoragePermissions();

      // Request notification permission (Android 13+)
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // Request media permissions (Android 13+)
      if (await Permission.videos.isDenied) {
        await Permission.videos.request();
      }
      if (await Permission.audio.isDenied) {
        await Permission.audio.request();
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  static Future<void> _requestStoragePermissions() async {
    if (await Permission.storage.isDenied) {
      final status = await Permission.storage.request();

      if (status.isPermanentlyDenied) {
        await _showPermissionDialog();
      }
    }

    // For Android 13+ (API 33+)
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }

  static Future<void> _showPermissionDialog() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'VidBox needs storage permission to save downloaded files. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Future.delayed(const Duration(milliseconds: 300), () {
                openAppSettings();
              });
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  static Future<bool> hasStoragePermission() async {
    // Check Android 13+ permissions first
    final hasMediaPermissions = await Permission.videos.isGranted && 
                                 await Permission.audio.isGranted;
    
    // Fall back to legacy storage permission
    final hasLegacyStorage = await Permission.storage.isGranted ||
                             await Permission.manageExternalStorage.isGranted;
    
    return hasMediaPermissions || hasLegacyStorage;
  }

  static Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }
}
