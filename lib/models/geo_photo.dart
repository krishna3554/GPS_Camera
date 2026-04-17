class GeoPhoto {
  GeoPhoto({
    this.id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.address,
    required this.altitude,
    required this.accuracy,
  });

  final int? id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String address;
  final double altitude;
  final double accuracy;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      'altitude': altitude,
      'accuracy': accuracy,
    };
  }

  factory GeoPhoto.fromMap(Map<String, dynamic> map) {
    return GeoPhoto(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      address: map['address'] as String? ?? 'Unknown location',
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
    );
  }
}
