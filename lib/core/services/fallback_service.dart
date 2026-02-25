import 'package:dio/dio.dart';
import 'dart:math';

class FallbackService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      followRedirects: true,
      maxRedirects: 5,
    ),
  );

  static final List<String> _userAgents = [
    'VidBox/1.0',
  ];

  static String _getRandomUserAgent() {
    return _userAgents.first;
  }

  static Map<String, String> _getHeaders() {
    return {
      'User-Agent': _getRandomUserAgent(),
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  static bool _isValidResponseUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty &&
             !url.contains('localhost') &&
             !url.contains('127.0.0.1') &&
             !url.contains('..');
    } catch (e) {
      return false;
    }
  }

  // Free Instagram downloader service
  static Future<Map<String, dynamic>?> downloadInstagram(String url) async {
    try {
      print('Fallback: Trying Instagram services...');
      
      final services = [
        {'url': 'https://api.saveig.app/api/ajaxSearch', 'type': 'saveig'},
      ];
      
      for (final service in services) {
        try {
          final response = await _dio.post(
            service['url']!,
            data: {'q': url, 'lang': 'en'},
            options: Options(
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'VidBox/1.0',
                'Accept': 'application/json',
              },
            ),
          );
          
          if (response.statusCode == 200 && response.data != null) {
            final parsed = _parseInstagramResponse(response.data);
            if (parsed != null && _isValidResponseUrl(parsed['url'])) {
              return parsed;
            }
          }
        } catch (e) {
          print('Service ${service['type']} failed: $e');
        }
      }
      
      return null;
    } catch (e) {
      print('Fallback Instagram error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> downloadTikTok(String url) async {
    try {
      print('Fallback: Trying TikTok services...');
      
      final services = [
        {'url': 'https://api.tiklydown.eu.org/api/download', 'type': 'tiklydown'},
      ];
      
      for (final service in services) {
        try {
          final response = await _dio.post(
            service['url']!,
            data: {'url': url},
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'VidBox/1.0',
                'Accept': 'application/json',
              },
            ),
          );
          
          if (response.statusCode == 200 && response.data != null) {
            final parsed = _parseTikTokResponse(response.data);
            if (parsed != null && _isValidResponseUrl(parsed['url'])) {
              return parsed;
            }
          }
        } catch (e) {
          print('Service ${service['type']} failed: $e');
        }
      }
      
      return null;
    } catch (e) {
      print('Fallback TikTok error: $e');
      return null;
    }
  }

  // Extract Instagram post ID from URL
  static String? _extractInstagramPostId(String url) {
    try {
      final patterns = [
        RegExp(r'/p/([A-Za-z0-9_-]+)'),
        RegExp(r'/reel/([A-Za-z0-9_-]+)'),
        RegExp(r'/tv/([A-Za-z0-9_-]+)'),
      ];
      
      for (final pattern in patterns) {
        final match = pattern.firstMatch(url);
        if (match != null) {
          return match.group(1);
        }
      }
      
      return null;
    } catch (e) {
      print('Error extracting Instagram post ID: $e');
      return null;
    }
  }

  // Parse Instagram response
  static Map<String, dynamic>? _parseInstagramResponse(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        String? videoUrl;
        
        // Multiple response format checks
        if (data['data'] != null) {
          final responseData = data['data'];
          if (responseData is List && responseData.isNotEmpty) {
            videoUrl = responseData[0]['url'] ?? responseData[0]['download_url'];
          } else if (responseData is Map) {
            videoUrl = responseData['url'] ?? responseData['video_url'];
          }
        }
        
        videoUrl ??= data['url'] ?? data['video_url'] ?? data['download_url'];
        
        // Filter out m3u8 if possible, prefer mp4
        if (videoUrl != null && videoUrl.contains('.m3u8')) {
          print('⚠ Warning: Instagram returned HLS stream (.m3u8)');
        }
        
        if (videoUrl != null && videoUrl.isNotEmpty) {
          return {
            'url': videoUrl,
            'title': data['title'] ?? 'Instagram Video',
            'thumbnail': data['thumbnail'] ?? data['cover'],
            'isHLS': videoUrl.contains('.m3u8'),
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Error parsing Instagram response: $e');
      return null;
    }
  }

  // Parse TikTok response
  static Map<String, dynamic>? _parseTikTokResponse(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        String? videoUrl;
        
        // Check multiple response structures
        if (data['data']?['play'] != null) {
          videoUrl = data['data']['play'];
        } else if (data['data']?['hdplay'] != null) {
          videoUrl = data['data']['hdplay'];
        } else if (data['play'] != null) {
          videoUrl = data['play'];
        } else if (data['video'] != null) {
          videoUrl = data['video'];
        } else if (data['data']?['wmplay'] != null) {
          videoUrl = data['data']['wmplay'];
        }
        
        // Filter out m3u8 if possible
        if (videoUrl != null && videoUrl.contains('.m3u8')) {
          print('⚠ Warning: TikTok returned HLS stream (.m3u8)');
        }
        
        if (videoUrl != null && videoUrl.isNotEmpty) {
          return {
            'url': videoUrl,
            'title': data['title'] ?? data['data']?['title'] ?? 'TikTok Video',
            'thumbnail': data['cover'] ?? data['thumbnail'] ?? data['data']?['cover'],
            'isHLS': videoUrl.contains('.m3u8'),
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Error parsing TikTok response: $e');
      return null;
    }
  }

  // Generic video downloader for other platforms
  static Future<Map<String, dynamic>?> downloadGeneric(String url) async {
    try {
      print('Fallback: Trying generic video service...');
      
      // This is a placeholder for other free services
      // You can add more free APIs here as needed
      
      return null;
    } catch (e) {
      print('Fallback generic error: $e');
      return null;
    }
  }
}