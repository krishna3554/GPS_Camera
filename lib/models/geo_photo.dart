import 'package:intl/intl.dart';

class GeoPhoto {
  const GeoPhoto({
    this.id,
    required this.imagePath,
    this.thumbPath,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.heading,
    this.speed,
    this.address,
    this.city,
    this.country,
    this.caption,
    required this.timestamp,
    this.tripId,
    this.isSynced = false,
    required this.createdAt,
  });

  final int? id;
  final String imagePath;
  final String? thumbPath;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final String? address;
  final String? city;
  final String? country;
  final String? caption;
  final DateTime timestamp;
  final int? tripId;
  final bool isSynced;
  final DateTime createdAt;

  String get formattedCoords =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get formattedDate =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp.toLocal());

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'image_path': imagePath,
      'thumb_path': thumbPath,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'address': address,
      'city': city,
      'country': country,
      'caption': caption,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'trip_id': tripId,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory GeoPhoto.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value)?.toUtc() ??
            (fallback ?? DateTime.now().toUtc());
      }
      return fallback ?? DateTime.now().toUtc();
    }

    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    return GeoPhoto(
      id: map['id'] as int?,
      imagePath: (map['image_path'] ?? map['imagePath'] ?? '') as String,
      thumbPath: (map['thumb_path'] ?? map['thumbPath']) as String?,
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      altitude: map['altitude'] == null ? null : parseDouble(map['altitude']),
      accuracy: map['accuracy'] == null ? null : parseDouble(map['accuracy']),
      heading: map['heading'] == null ? null : parseDouble(map['heading']),
      speed: map['speed'] == null ? null : parseDouble(map['speed']),
      address: (map['address'] as String?)?.trim(),
      city: (map['city'] as String?)?.trim(),
      country: (map['country'] as String?)?.trim(),
      caption: (map['caption'] as String?)?.trim(),
      timestamp: parseDate(map['timestamp']),
      tripId: map['trip_id'] as int? ?? map['tripId'] as int?,
      isSynced: ((map['is_synced'] ?? map['isSynced']) ?? 0) == 1,
      createdAt: parseDate(map['created_at'], fallback: parseDate(map['timestamp'])),
    );
  }

  GeoPhoto copyWith({
    int? id,
    String? imagePath,
    String? thumbPath,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    double? heading,
    double? speed,
    String? address,
    String? city,
    String? country,
    String? caption,
    DateTime? timestamp,
    int? tripId,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return GeoPhoto(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      thumbPath: thumbPath ?? this.thumbPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      caption: caption ?? this.caption,
      timestamp: timestamp ?? this.timestamp,
      tripId: tripId ?? this.tripId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
