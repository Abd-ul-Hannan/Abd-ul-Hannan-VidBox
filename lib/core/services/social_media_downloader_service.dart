import 'rapid_api_service.dart';
import 'fallback_service.dart';

class SocialMediaDownloaderService {
  static Future<Map<String, dynamic>?> getVideoData(String url) async {
    try {
      print('=== Fetching video data for: $url ===');
      
      String platform = _getPlatformName(url);
      print('Detected platform: $platform');
      Map<String, dynamic>? data;
      
      // First try RapidAPI
      if (RapidApiService.hasValidApiKey) {
        if (url.contains('instagram.com')) {
          print('Trying Instagram-specific API...');
          data = await RapidApiService.downloadInstagram(url);
          if (data == null) {
            print('Instagram API failed, trying general API...');
            data = await RapidApiService.downloadVideo(url);
          }
        } else if (url.contains('tiktok.com')) {
          print('Trying TikTok-specific API...');
          data = await RapidApiService.downloadTikTok(url);
          if (data == null) {
            print('TikTok API failed, trying general API...');
            data = await RapidApiService.downloadVideo(url);
          }
        } else if (url.contains('facebook.com') || url.contains('fb.watch')) {
          print('Trying Facebook-specific API...');
          data = await RapidApiService.downloadFacebook(url);
          if (data == null) {
            print('Facebook API failed, trying general API...');
            data = await RapidApiService.downloadVideo(url);
          }
        } else if (url.contains('twitter.com') || url.contains('x.com')) {
          print('Trying Twitter-specific API...');
          data = await RapidApiService.downloadTwitter(url);
          if (data == null) {
            print('Twitter API failed, trying general API...');
            data = await RapidApiService.downloadVideo(url);
          }
        } else {
          print('Using general downloader API...');
          data = await RapidApiService.downloadVideo(url);
        }
      } else {
        print('No valid RapidAPI key, using fallback services...');
      }
      
      // If RapidAPI failed, try fallback services
      if (data == null) {
        print('RapidAPI failed, trying fallback services...');
        if (url.contains('instagram.com')) {
          data = await FallbackService.downloadInstagram(url);
        } else if (url.contains('tiktok.com')) {
          data = await FallbackService.downloadTikTok(url);
        } else {
          data = await FallbackService.downloadGeneric(url);
        }
        
        // If fallback returned data, normalize it
        if (data != null && data['url'] != null) {
          print('✓ Fallback service returned URL');
          return {
            'url': data['url'],
            'links': [{'link': data['url'], 'quality': 'HD'}],
            'title': data['title'] ?? 'Video from $platform',
            'thumbnail': data['thumbnail'],
            'author': data['author'],
            'platform': platform,
            'isHLS': data['isHLS'] ?? false,
          };
        }
      }
      
      if (data != null) {
        print('API returned data, extracting video URL...');
        print('Raw API data keys: ${data.keys.toList()}');
        
        final videoUrl = RapidApiService.extractVideoUrl(data, platform);
        final qualityOptions = RapidApiService.extractQualityOptions(data, platform);
        
        print('Extracted video URL: ${videoUrl?.substring(0, videoUrl.length > 50 ? 50 : videoUrl.length)}');
        print('Quality options count: ${qualityOptions.length}');
        
        if (videoUrl != null && videoUrl.isNotEmpty) {
          print('Successfully extracted video URL');
          
          // Build links array from quality options
          final links = qualityOptions.isNotEmpty 
            ? qualityOptions.map((q) => {'link': q['url'], 'url': q['url'], 'quality': q['quality']}).toList()
            : [{'link': videoUrl, 'url': videoUrl, 'quality': 'HD'}];
          
          return {
            'url': videoUrl,
            'links': links,
            'title': RapidApiService.extractTitle(data) ?? 'Video from $platform',
            'thumbnail': RapidApiService.extractThumbnail(data),
            'author': RapidApiService.extractAuthor(data),
            'platform': platform,
            'isHLS': videoUrl.contains('.m3u8'),
            'rawData': data, // Keep raw data for debugging
          };
        } else {
          print('✗ Could not extract video URL from API response');
          print('Raw data structure: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}');
        }
      } else {
        print('✗ All services returned null data');
      }
      
      print('Failed to fetch video data');
      return null;
    } catch (e, stackTrace) {
      print('=== ERROR fetching video data ===');
      print('Error: $e');
      
      // Categorize errors for better user experience
      String userMessage;
      if (e.toString().contains('SocketException')) {
        userMessage = 'Network connection failed. Please check your internet.';
      } else if (e.toString().contains('TimeoutException')) {
        userMessage = 'Request timed out. Please try again.';
      } else if (e.toString().contains('403') || e.toString().contains('401')) {
        userMessage = 'Access denied. Video may be private or restricted.';
      } else if (e.toString().contains('404')) {
        userMessage = 'Video not found. It may have been deleted.';
      } else {
        userMessage = 'Failed to fetch video data. Please try again later.';
      }
      
      print('User message: $userMessage');
      return null;
    }
  }

  static String? extractDownloadUrl(Map<String, dynamic> data, {String? quality}) {
    try {
      print('=== Extracting download URL ===');
      print('Data keys: ${data.keys.toList()}');
      print('Requested quality: $quality');
      
      final platform = data['platform'] ?? 'Unknown';
      final qualityOptions = RapidApiService.extractQualityOptions(data, platform);
      
      print('Found ${qualityOptions.length} quality options');
      
      if (qualityOptions.isNotEmpty) {
        // Find matching quality or get best available
        if (quality != null) {
          final match = qualityOptions.firstWhere(
            (q) => q['quality']?.toLowerCase() == quality.toLowerCase(),
            orElse: () => qualityOptions.first,
          );
          print('Selected quality option: ${match['quality']}');
          return match['url'];
        }
        print('Using first quality option: ${qualityOptions.first['quality']}');
        return qualityOptions.first['url'];
      }
      
      // Try direct URL from data
      if (data.containsKey('url') && data['url'] != null && data['url'].toString().isNotEmpty) {
        print('Found direct URL in data');
        return data['url'] as String;
      }
      
      // Fallback to legacy extraction
      if (data.containsKey('links')) {
        final links = data['links'] as List?;
        if (links != null && links.isNotEmpty) {
          print('Found ${links.length} links');
          if (quality != null) {
            final match = links.firstWhere(
              (link) => link['quality']?.toString().contains(quality) ?? false,
              orElse: () => links.first,
            );
            final url = match['link'] ?? match['url'];
            print('Selected link with quality match: $url');
            return url;
          }
          final url = links.first['link'] ?? links.first['url'];
          print('Using first link: $url');
          return url;
        }
      }
      
      if (data.containsKey('download_url')) {
        print('Found download_url');
        return data['download_url'] as String?;
      }

      if (data.containsKey('video_url')) {
        print('Found video_url');
        return data['video_url'] as String?;
      }

      print('✗ Could not extract download URL from response');
      return null;
    } catch (e) {
      print('Error extracting download URL: $e');
      return null;
    }
  }

  static List<String> extractAvailableQualities(Map<String, dynamic> data) {
    try {
      final platform = data['platform'] ?? 'Unknown';
      final qualityOptions = RapidApiService.extractQualityOptions(data, platform);
      
      if (qualityOptions.isNotEmpty) {
        return qualityOptions.map((q) => q['quality']!).toList();
      }
      
      // Fallback to checking for common quality indicators
      final qualities = <String>[];
      
      if (data.containsKey('links')) {
        final links = data['links'] as List?;
        if (links != null) {
          for (var link in links) {
            final quality = link['quality']?.toString();
            if (quality != null && !qualities.contains(quality)) {
              qualities.add(quality);
            }
          }
        }
      }
      
      // Check for HD/SD indicators
      if (data['hd'] != null || data['data']?['hdplay'] != null) {
        qualities.add('HD');
      }
      if (data['sd'] != null || data['data']?['play'] != null) {
        qualities.add('SD');
      }
      
      return qualities.isEmpty ? ['HD', 'SD'] : qualities;
    } catch (e) {
      print('Error extracting qualities: $e');
      return ['HD', 'SD'];
    }
  }

  static String? extractTitle(Map<String, dynamic> data) {
    return data['title'] as String? ?? 
           data['meta']?['title'] as String? ?? 
           'Downloaded Video';
  }

  static String? extractThumbnail(Map<String, dynamic> data) {
    return data['thumbnail'] as String? ?? 
           data['picture'] as String? ?? 
           data['meta']?['image'] as String?;
  }

  static String? extractAuthor(Map<String, dynamic> data) {
    return data['author'] as String? ?? 
           data['owner'] as String? ?? 
           data['meta']?['author'] as String? ?? 
           'Unknown';
  }

  static int extractDuration(Map<String, dynamic> data) {
    final duration = data['duration'] ?? data['meta']?['duration'];
    if (duration is int) return duration;
    if (duration is String) return int.tryParse(duration) ?? 0;
    return 0;
  }

  static bool isSupportedPlatform(String url) {
    final supportedDomains = [
      'instagram.com',
      'facebook.com',
      'fb.watch',
      'tiktok.com',
      'snapchat.com',
      'twitter.com',
      'x.com',
      'vimeo.com',
      'dailymotion.com',
      'reddit.com',
      'pinterest.com',
      'rapidvideo.com',
      'rapidsave.com',
    ];
    
    return supportedDomains.any((domain) => url.contains(domain));
  }
  
  static String _getPlatformName(String url) {
    if (url.contains('instagram.com')) return 'Instagram';
    if (url.contains('tiktok.com')) return 'TikTok';
    if (url.contains('facebook.com') || url.contains('fb.watch')) return 'Facebook';
    if (url.contains('snapchat.com')) return 'Snapchat';
    if (url.contains('twitter.com') || url.contains('x.com')) return 'Twitter';
    if (url.contains('vimeo.com')) return 'Vimeo';
    if (url.contains('dailymotion.com')) return 'Dailymotion';
    if (url.contains('reddit.com')) return 'Reddit';
    if (url.contains('pinterest.com')) return 'Pinterest';
    if (url.contains('rapidvideo.com') || url.contains('rapidsave.com')) return 'RapidVideo';
    return 'Unknown';
  }
}
