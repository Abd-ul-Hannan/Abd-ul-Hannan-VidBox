import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../data/models/video_info_model.dart';
import 'social_media_downloader_service.dart';

class VideoInfoService {
  static final YoutubeExplode _youtube = YoutubeExplode();

  static Future<VideoInfoModel?> getVideoInfo(String url) async {
    try {
      print('Fetching video info for: $url');
      if (_isYouTubeUrl(url)) {
        return await _getYouTubeInfo(url);
      } else if (SocialMediaDownloaderService.isSupportedPlatform(url)) {
        return await _getSocialMediaInfo(url);
      } else {
        return _getGenericInfo(url);
      }
    } catch (e, stackTrace) {
      print('Error getting video info: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  static String _normalizeYouTubeUrl(String url) {
    final uri = Uri.parse(url);
    
    // Handle YouTube Shorts
    if (url.contains('/shorts/')) {
      final shortsIndex = uri.pathSegments.indexOf('shorts');
      if (shortsIndex != -1 && shortsIndex + 1 < uri.pathSegments.length) {
        final videoId = uri.pathSegments[shortsIndex + 1].split('?').first;
        return 'https://www.youtube.com/watch?v=$videoId';
      }
    }
    
    // Handle youtu.be links
    if (url.contains('youtu.be/')) {
      final videoId = uri.pathSegments.isNotEmpty 
          ? uri.pathSegments.first.split('?').first 
          : '';
      if (videoId.isNotEmpty) {
        return 'https://www.youtube.com/watch?v=$videoId';
      }
    }
    
    // Handle regular YouTube links with v parameter
    if (uri.queryParameters.containsKey('v')) {
      final videoId = uri.queryParameters['v'];
      return 'https://www.youtube.com/watch?v=$videoId';
    }
    
    return url;
  }

  static Future<VideoInfoModel> _getYouTubeInfo(String url) async {
    try {
      final normalizedUrl = _normalizeYouTubeUrl(url);
      print('Normalized URL: $normalizedUrl');
      final video = await _youtube.videos.get(normalizedUrl);
      final manifest = await _youtube.videos.streamsClient.getManifest(video.id);

      // Extract available video qualities
      final videoQualities = <String>[];
      
      // Add video-only streams (for high quality like 1080p, 1440p, 4K)
      for (var stream in manifest.videoOnly) {
        final quality = '${stream.videoQuality.name}';
        if (!videoQualities.contains(quality)) {
          videoQualities.add(quality);
        }
      }
      
      // Add muxed streams (video + audio combined, usually up to 720p)
      for (var stream in manifest.muxed) {
        final quality = '${stream.videoQuality.name}';
        if (!videoQualities.contains(quality)) {
          videoQualities.add(quality);
        }
      }

      // Extract available audio qualities
      final audioQualities = <String>[];
      for (var stream in manifest.audioOnly) {
        final bitrate = '${(stream.bitrate.kiloBitsPerSecond).round()}kbps';
        if (!audioQualities.contains(bitrate)) {
          audioQualities.add(bitrate);
        }
      }

      return VideoInfoModel(
        url: url,
        title: video.title,
        thumbnail: video.thumbnails.highResUrl,
        duration: video.duration?.inSeconds ?? 0,
        author: video.author,
        videoQualities: videoQualities,
        audioQualities: audioQualities,
        platform: 'YouTube',
      );
    } catch (e) {
      print('Error getting YouTube info: $e');
      rethrow;
    }
  }

  static Future<VideoInfoModel> _getSocialMediaInfo(String url) async {
    try {
      final videoData = await SocialMediaDownloaderService.getVideoData(url);
      
      if (videoData != null) {
        // Get available qualities from RapidAPI response
        final availableQualities = SocialMediaDownloaderService.extractAvailableQualities(videoData);
        
        return VideoInfoModel(
          url: url,
          title: videoData['title'] ?? 'Downloaded Video',
          thumbnail: videoData['thumbnail'] ?? '',
          duration: SocialMediaDownloaderService.extractDuration(videoData),
          author: videoData['author'] ?? 'Unknown',
          videoQualities: availableQualities.isNotEmpty ? availableQualities : ['HD', 'SD'],
          audioQualities: ['128kbps', '192kbps'],
          platform: _getPlatformName(url),
        );
      }
    } catch (e) {
      print('Error getting social media info: $e');
    }
    
    return _getGenericInfo(url);
  }

  static VideoInfoModel _getGenericInfo(String url) {
    return VideoInfoModel(
      url: url,
      title: 'Video from ${_getPlatformName(url)}',
      thumbnail: '',
      duration: 0,
      author: 'Unknown',
      videoQualities: ['HD', 'SD', '720p', '480p'],
      audioQualities: ['128kbps', '192kbps'],
      platform: _getPlatformName(url),
    );
  }

  static String _getPlatformName(String url) {
    if (url.contains('instagram.com')) return 'Instagram';
    if (url.contains('tiktok.com')) return 'TikTok';
    if (url.contains('facebook.com') || url.contains('fb.watch')) return 'Facebook';
    if (url.contains('snapchat.com')) return 'Snapchat';
    if (url.contains('twitter.com') || url.contains('x.com')) return 'Twitter';
    if (url.contains('vimeo.com')) return 'Vimeo';
    return 'Unknown Platform';
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  static void dispose() {
    _youtube.close();
  }
}
