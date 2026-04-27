import 'location_info.dart';

enum MediaType { photo, video }

class CapturedMedia {
  const CapturedMedia({
    required this.id,
    required this.filePath,
    required this.type,
    this.videoDuration,
    required this.locationInfo,
    required this.capturedAt,
  });

  final String id;
  final String filePath;
  final MediaType type;
  final Duration? videoDuration;
  final LocationInfo locationInfo;
  final DateTime capturedAt;

  String get thumbnailPath => filePath;

  CapturedMedia copyWith({
    String? id,
    String? filePath,
    MediaType? type,
    Duration? videoDuration,
    LocationInfo? locationInfo,
    DateTime? capturedAt,
  }) {
    return CapturedMedia(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      videoDuration: videoDuration ?? this.videoDuration,
      locationInfo: locationInfo ?? this.locationInfo,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'type': type.name,
        'videoDurationMs': videoDuration?.inMilliseconds,
        'locationInfo': locationInfo.toJson(),
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory CapturedMedia.fromJson(Map<String, dynamic> json) {
    return CapturedMedia(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      type: MediaType.values.byName(json['type'] as String),
      videoDuration: json['videoDurationMs'] != null
          ? Duration(milliseconds: json['videoDurationMs'] as int)
          : null,
      locationInfo:
          LocationInfo.fromJson(json['locationInfo'] as Map<String, dynamic>),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
    );
  }
}
