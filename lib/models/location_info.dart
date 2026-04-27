import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class LocationInfo {
  const LocationInfo({
    required this.address,
    required this.date,
    required this.time,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final String date;
  final String time;
  final double latitude;
  final double longitude;

  factory LocationInfo.fromPosition(Position pos, String resolvedAddress) {
    final now = DateTime.now();
    return LocationInfo(
      address: resolvedAddress,
      date: DateFormat('MM/dd/yyyy').format(now),
      time: DateFormat('hh:mm a').format(now),
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }

  LocationInfo copyWith({
    String? address,
    String? date,
    String? time,
    double? latitude,
    double? longitude,
  }) {
    return LocationInfo(
      address: address ?? this.address,
      date: date ?? this.date,
      time: time ?? this.time,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'date': date,
        'time': time,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      address: json['address'] as String? ?? 'Location not available',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
