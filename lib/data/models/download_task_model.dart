enum DownloadType { video, audio }

enum DownloadStatus { pending, downloading, paused, completed, failed, cancelled }

class DownloadTaskModel {
  final String id;
  final String url;
  final String title;
  final String thumbnail;
  final DownloadType type;
  final String quality;
  final String platform;
  final int notificationId;
  DownloadStatus status;
  int progress;
  String? filePath;
  String? error;

  DownloadTaskModel({
    required this.id,
    required this.url,
    required this.title,
    required this.thumbnail,
    required this.type,
    required this.quality,
    required this.platform,
    required this.notificationId,
    this.status = DownloadStatus.pending,
    this.progress = 0,
    this.filePath,
    this.error,
  });

  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isCancelled => status == DownloadStatus.cancelled;

  String get typeString => type == DownloadType.audio ? 'audio' : 'video';

  String get statusString {
    switch (status) {
      case DownloadStatus.pending:
        return 'Pending';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  DownloadTaskModel copyWith({
    String? id,
    String? url,
    String? title,
    String? thumbnail,
    DownloadType? type,
    String? quality,
    String? platform,
    int? notificationId,
    DownloadStatus? status,
    int? progress,
    String? filePath,
    String? error,
  }) {
    return DownloadTaskModel(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      type: type ?? this.type,
      quality: quality ?? this.quality,
      platform: platform ?? this.platform,
      notificationId: notificationId ?? this.notificationId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
    );
  }
}
