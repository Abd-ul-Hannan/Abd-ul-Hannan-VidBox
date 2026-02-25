class VideoInfoModel {
  final String url;
  final String title;
  final String thumbnail;
  final int duration;
  final String author;
  final List<String> videoQualities;
  final List<String> audioQualities;
  final String platform;

  VideoInfoModel({
    required this.url,
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.author,
    required this.videoQualities,
    required this.audioQualities,
    required this.platform,
  });

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
