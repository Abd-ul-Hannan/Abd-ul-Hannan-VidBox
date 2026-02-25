class DownloadModel {
  final String id;
  final String url;
  final String title;
  final String thumbnail;
  final String type;
  final String quality;
  final String status;
  final int progress;
  final String? filePath;
  final String platform;
  final DateTime createdAt;
  final DateTime updatedAt;

  DownloadModel({
    required this.id,
    required this.url,
    required this.title,
    required this.thumbnail,
    required this.type,
    required this.quality,
    required this.status,
    this.progress = 0,
    this.filePath,
    required this.platform,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DownloadModel.fromJson(Map<String, dynamic> json) {
    return DownloadModel(
      id: json['id'],
      url: json['url'],
      title: json['title'],
      thumbnail: json['thumbnail'] ?? '',
      type: json['type'],
      quality: json['quality'],
      status: json['status'],
      progress: json['progress'] ?? 0,
      filePath: json['file_path'],
      platform: json['platform'] ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'thumbnail': thumbnail,
      'type': type,
      'quality': quality,
      'status': status,
      'progress': progress,
      'file_path': filePath,
      'platform': platform,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DownloadModel copyWith({
    String? id,
    String? url,
    String? title,
    String? thumbnail,
    String? type,
    String? quality,
    String? status,
    int? progress,
    String? filePath,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DownloadModel(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      type: type ?? this.type,
      quality: quality ?? this.quality,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
