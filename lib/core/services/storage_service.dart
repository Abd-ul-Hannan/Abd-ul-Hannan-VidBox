import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class StorageService {
  static Future<String> getDownloadDirectory() async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        // Get external storage directory for Android
        directory = await getExternalStorageDirectory();

        if (directory != null) {
          // Create VidBox Downloads folder
          final downloadPath = Directory('${directory.path}/${AppConstants.downloadFolderName}');

          if (!await downloadPath.exists()) {
            await downloadPath.create(recursive: true);
          }

          return downloadPath.path;
        }
      }

      // Fallback to application documents directory
      directory = await getApplicationDocumentsDirectory();
      final downloadPath = Directory('${directory.path}/${AppConstants.downloadFolderName}');

      if (!await downloadPath.exists()) {
        await downloadPath.create(recursive: true);
      }

      return downloadPath.path;
    } catch (e) {
      print('Error getting download directory: $e');
      rethrow;
    }
  }

  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  static String sanitizeFileName(String fileName) {
    // Remove invalid characters and handle path traversal
    String sanitized = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\.\.'), '_') // Prevent path traversal
        .replaceAll(RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$', caseSensitive: false), '_reserved_'); // Windows reserved names
    
    // Limit length and ensure not empty
    if (sanitized.isEmpty) sanitized = 'download';
    if (sanitized.length > 100) sanitized = sanitized.substring(0, 100);
    
    return sanitized;
  }
}
