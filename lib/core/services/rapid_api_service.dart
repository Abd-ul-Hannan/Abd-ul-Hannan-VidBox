import 'package:dio/dio.dart';
import '../utils/constants.dart';

class RapidApiService {
  static String get _apiKey => AppConstants.rapidApiKey;
  static final String _apiHost = 'social-download-all-in-one.p.rapidapi.com';
  static final String _baseUrl = 'https://social-download-all-in-one.p.rapidapi.com';
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: AppConstants.networkTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConstants.networkTimeoutSeconds * 2),
      sendTimeout: Duration(seconds: AppConstants.networkTimeoutSeconds),
    ),
  );


  // Check if API key is valid
  static bool get hasValidApiKey {
    return _apiKey.isNotEmpty && 
           _apiKey != 'YOUR_RAPIDAPI_KEY' && 
           !_apiKey.startsWith('YOUR_') &&
           _apiKey.length > 30 && // RapidAPI keys are typically longer
           RegExp(r'^[a-zA-Z0-9]+$').hasMatch(_apiKey); // Alphanumeric check
  }

  // Test API connection
  static Future<bool> testConnection() async {
    if (!hasValidApiKey) {
      print('❌ Invalid API key format');
      return false;
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/v1/social/autolink',
        data: {'url': 'https://www.instagram.com/p/test/'},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-rapidapi-host': _apiHost,
            'x-rapidapi-key': _apiKey,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        print('✅ RapidAPI connection successful');
        return true;
      } else {
        print('❌ RapidAPI connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ RapidAPI connection error: $e');
      return false;
    }
  }

  // Social Download All-in-One API - Universal endpoint
  static Future<Map<String, dynamic>?> downloadVideo(String url) async {
    if (!hasValidApiKey) {
      print('Invalid or missing RapidAPI key');
      return null;
    }

    try {
      print('RapidAPI: Fetching video from $url');
      
      final response = await _dio.post(
        '$_baseUrl/v1/social/autolink',
        data: {'url': url},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-rapidapi-host': _apiHost,
            'x-rapidapi-key': _apiKey,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('RapidAPI Response Status: ${response.statusCode}');
      print('RapidAPI Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        print('RapidAPI: Success');
        return response.data;
      } else if (response.statusCode == 403) {
        print('RapidAPI: API Key invalid or subscription expired');
      } else if (response.statusCode == 429) {
        print('RapidAPI: Rate limit exceeded');
      }
      return null;
    } catch (e) {
      print('RapidAPI downloadVideo error: $e');
      if (e is DioException) {
        print('Status Code: ${e.response?.statusCode}');
        print('Response: ${e.response?.data}');
      }
      return null;
    }
  }

  // Instagram, TikTok, Facebook, Twitter - Use universal endpoint
  static Future<Map<String, dynamic>?> downloadInstagram(String url) async {
    return downloadVideo(url);
  }

  static Future<Map<String, dynamic>?> downloadTikTok(String url) async {
    return downloadVideo(url);
  }

  static Future<Map<String, dynamic>?> downloadFacebook(String url) async {
    return downloadVideo(url);
  }

  static Future<Map<String, dynamic>?> downloadTwitter(String url) async {
    return downloadVideo(url);
  }

  // Extract all available quality options from response
  static List<Map<String, String>> extractQualityOptions(Map<String, dynamic> data, String platform) {
    try {
      final qualities = <Map<String, String>>[];
      
      // New API response structure: data.medias array
      if (data['data']?['medias'] is List) {
        final medias = data['data']['medias'] as List;
        for (var media in medias) {
          if (media['url'] != null) {
            qualities.add({
              'quality': media['quality'] ?? 'HD',
              'url': media['url'],
            });
          }
        }
      }
      
      // Fallback patterns
      if (data['medias'] is List) {
        final medias = data['medias'] as List;
        for (var media in medias) {
          if (media['url'] != null) {
            qualities.add({
              'quality': media['quality'] ?? 'HD',
              'url': media['url'],
            });
          }
        }
      }
      
      if (data['links'] is List) {
        final links = data['links'] as List;
        for (var link in links) {
          if (link['url'] != null) {
            qualities.add({
              'quality': link['quality'] ?? 'HD',
              'url': link['url'],
            });
          }
        }
      }
      
      // Remove duplicates
      final uniqueQualities = <Map<String, String>>[];
      final seenUrls = <String>{};
      
      for (var quality in qualities) {
        if (!seenUrls.contains(quality['url'])) {
          seenUrls.add(quality['url']!);
          uniqueQualities.add(quality);
        }
      }
      
      return uniqueQualities;
    } catch (e) {
      print('Error extracting quality options: $e');
      return [];
    }
  }

  // Extract video URL from response
  static String? extractVideoUrl(Map<String, dynamic> data, String platform) {
    try {
      print('Extracting video URL for platform: $platform');
      print('Data keys: ${data.keys.toList()}');
      
      // New API: data.medias[0].url
      if (data['data']?['medias'] is List) {
        final medias = data['data']['medias'] as List;
        if (medias.isNotEmpty && medias.first['url'] != null) {
          print('Found URL in data.medias');
          return medias.first['url'];
        }
      }
      
      // Fallback: medias array
      if (data['medias'] is List && (data['medias'] as List).isNotEmpty) {
        final media = (data['medias'] as List).first;
        if (media['url'] != null) {
          print('Found URL in medias array');
          return media['url'];
        }
      }
      
      // Fallback: links array
      if (data['links'] is List && (data['links'] as List).isNotEmpty) {
        final link = (data['links'] as List).first;
        if (link is Map && link['url'] != null) return link['url'];
        if (link is String) return link;
      }
      
      // Generic fallbacks
      if (data['url'] != null) return data['url'];
      if (data['video_url'] != null) return data['video_url'];
      if (data['download_url'] != null) return data['download_url'];
      
      print('Could not extract video URL from data');
      return null;
    } catch (e) {
      print('Error extracting video URL: $e');
      return null;
    }
  }

  // Extract title from response
  static String? extractTitle(Map<String, dynamic> data) {
    return data['data']?['title'] ??
           data['title'] ?? 
           data['meta']?['title'] ?? 
           data['description'] ?? 
           data['caption'];
  }

  // Extract thumbnail from response
  static String? extractThumbnail(Map<String, dynamic> data) {
    return data['data']?['thumbnail'] ??
           data['thumbnail'] ?? 
           data['picture'] ?? 
           data['cover'] ?? 
           data['meta']?['image'];
  }

  // Extract author from response
  static String? extractAuthor(Map<String, dynamic> data) {
    return data['data']?['author'] ??
           data['author'] ?? 
           data['owner'] ?? 
           data['username'] ?? 
           data['user']?['username'];
  }

  // Get quality options for a specific platform URL
  static Future<List<String>> getAvailableQualities(String url) async {
    try {
      final platform = _getPlatformName(url);
      Map<String, dynamic>? data;
      
      if (url.contains('instagram.com')) {
        data = await downloadInstagram(url);
      } else if (url.contains('tiktok.com')) {
        data = await downloadTikTok(url);
      } else if (url.contains('facebook.com') || url.contains('fb.watch')) {
        data = await downloadFacebook(url);
      } else if (url.contains('twitter.com') || url.contains('x.com')) {
        data = await downloadTwitter(url);
      } else {
        data = await downloadVideo(url);
      }
      
      if (data != null) {
        final qualities = extractQualityOptions(data, platform);
        return qualities.map((q) => q['quality']!).toList();
      }
      
      return ['HD', 'SD'];
    } catch (e) {
      print('Error getting available qualities: $e');
      return ['HD', 'SD'];
    }
  }
  
  static String _getPlatformName(String url) {
    if (url.contains('instagram.com')) return 'Instagram';
    if (url.contains('tiktok.com')) return 'TikTok';
    if (url.contains('facebook.com') || url.contains('fb.watch')) return 'Facebook';
    if (url.contains('twitter.com') || url.contains('x.com')) return 'Twitter';
    if (url.contains('vimeo.com')) return 'Vimeo';
    if (url.contains('dailymotion.com')) return 'Dailymotion';
    if (url.contains('reddit.com')) return 'Reddit';
    if (url.contains('rapidvideo.com') || url.contains('rapidsave.com')) return 'RapidVideo';
    return 'Unknown';
  }
}
