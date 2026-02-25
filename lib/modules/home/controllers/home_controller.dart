import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/video_info_service.dart';
import '../../../data/models/video_info_model.dart';
import '../widgets/video_info_bottom_sheet.dart';

class HomeController extends GetxController {
  final urlController = TextEditingController();
  final isLoading = false.obs;
  final urlError = ''.obs;
  final isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = Get.isDarkMode;
  }

  @override
  void onClose() {
    urlController.dispose();
    super.onClose();
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // Debug function to test RapidAPI
  Future<void> testRapidApi() async {
    Get.snackbar(
      'Testing API',
      'Running RapidAPI diagnostics...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
    
    
  }

  void clearUrl() {
    urlController.clear();
    urlError.value = '';
  }

  Future<void> pasteAndFetch() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        urlController.text = clipboardData.text!;
        await fetchVideoInfo();
      } else {
        Get.snackbar(
          'Error',
          'No URL found in clipboard',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to paste from clipboard',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> fetchVideoInfo() async {
    final url = urlController.text.trim();

    if (url.isEmpty) {
      urlError.value = 'Please enter a URL';
      return;
    }

    if (!VideoInfoService.isValidUrl(url)) {
      urlError.value = 'Please enter a valid URL';
      return;
    }

    urlError.value = '';
    isLoading.value = true;

    try {
      print('Attempting to fetch video info for: $url');
      final videoInfo = await VideoInfoService.getVideoInfo(url);

      if (videoInfo != null) {
        _showVideoInfoBottomSheet(videoInfo);
      } else {
        Get.snackbar(
          'Error',
          'Could not fetch video information. Please check the URL and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Error in fetchVideoInfo: $e');
      String errorMessage = 'Failed to fetch video info';
      
      if (e.toString().contains('VideoUnplayable')) {
        errorMessage = 'This video is not available or restricted';
      } else if (e.toString().contains('VideoRequiresPurchase')) {
        errorMessage = 'This video requires purchase';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showVideoInfoBottomSheet(VideoInfoModel videoInfo) {
    Get.bottomSheet(
      VideoInfoBottomSheet(videoInfo: videoInfo),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }
}
