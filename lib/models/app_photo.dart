import 'location_info.dart';

class AppPhoto {
  const AppPhoto({
    required this.id,
    required this.filePath,
    required this.locationInfo,
    required this.capturedAt,
  });

  final String id;
  final String filePath;
  final LocationInfo locationInfo;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'locationInfo': locationInfo.toJson(),
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory AppPhoto.fromJson(Map<String, dynamic> json) {
    return AppPhoto(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      locationInfo:
          LocationInfo.fromJson(json['locationInfo'] as Map<String, dynamic>),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
    );
  }
}
