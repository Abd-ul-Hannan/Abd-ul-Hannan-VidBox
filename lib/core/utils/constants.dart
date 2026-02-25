import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY';

  // App Configuration
  static const String appName = 'VidBox';
  static const String downloadFolderName = 'VidBox Downloads';

  // Notification Channel
  static const String notificationChannelId = 'vidbox_downloads';
  static const String notificationChannelName = 'VidBox Downloads';
  static const String notificationChannelDescription = 'Notifications for download progress';

  // RapidAPI Configuration
  static String get rapidApiKey => dotenv.env['RAPIDAPI_KEY'] ?? 'YOUR_RAPIDAPI_KEY';

  // Download Configuration
  static const int maxFileSizeMB = 500; // Maximum file size in MB
  static const int networkTimeoutSeconds = 15;
  static const int receiveTimeoutMinutes = 5;
  static const List<String> allowedVideoTypes = ['video/mp4', 'video/webm', 'video/avi'];
  static const List<String> allowedAudioTypes = ['audio/mpeg', 'audio/mp4', 'audio/wav'];

  // Supported Platforms
  static const List<String> supportedPlatforms = [
    'youtube.com',
    'youtu.be',
    'instagram.com',
    'tiktok.com',
    'facebook.com',
    'fb.watch',
    'twitter.com',
    'x.com',
    'vimeo.com',
    'dailymotion.com',
    'reddit.com',
  ];

  // Quality Options
  static const List<String> videoQualities = [
    '360p',
    '480p',
    '720p',
    '1080p',
    '1440p',
    '2160p',
  ];

  static const List<String> audioQualities = [
    '128kbps',
    '192kbps',
    '256kbps',
    '320kbps',
  ];
}
