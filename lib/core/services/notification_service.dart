import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Navigate to downloads screen when notification is tapped
    Get.toNamed('/downloads');
  }

  static Future<void> showDownloadStartedNotification({
    required int id,
    required String title,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: 0,
        onlyAlertOnce: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.show(
        id,
        'Starting Download',
        title.length > 50 ? '${title.substring(0, 50)}...' : title,
        details,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static Future<void> showDownloadProgressNotification({
    required int id,
    required String title,
    required int progress,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        onlyAlertOnce: true,
        silent: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      final shortTitle = title.length > 40 ? '${title.substring(0, 40)}...' : title;
      await _notifications.show(
        id,
        'Downloading',
        '$shortTitle - $progress%',
        details,
      );
    } catch (e) {
      print('Error showing progress notification: $e');
    }
  }

  static Future<void> showDownloadCompletedNotification({
    required int id,
    required String title,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.show(
        id,
        'Download Complete',
        title.length > 50 ? '${title.substring(0, 50)}...' : title,
        details,
      );
    } catch (e) {
      print('Error showing completion notification: $e');
    }
  }

  static Future<void> showDownloadFailedNotification({
    required int id,
    required String title,
    required String error,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      final shortTitle = title.length > 30 ? '${title.substring(0, 30)}...' : title;
      final shortError = error.length > 50 ? '${error.substring(0, 50)}...' : error;
      await _notifications.show(
        id,
        'Download Failed',
        '$shortTitle - $shortError',
        details,
      );
    } catch (e) {
      print('Error showing failure notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
