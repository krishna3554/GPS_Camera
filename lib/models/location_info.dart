import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class LocationInfo {
  const LocationInfo({
    required this.address,
    required this.date,
    required this.time,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.locality,
    this.administrativeArea,
    this.country,
    this.postalCode,
    this.altitude,
    this.speedMetersPerSecond,
    this.heading,
    this.accuracy,
  });

  final String address;
  final String date;
  final String time;
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? locality;
  final String? administrativeArea;
  final String? country;
  final String? postalCode;
  final double? altitude;
  final double? speedMetersPerSecond;
  final double? heading;
  final double? accuracy;

  factory LocationInfo.fromPosition(Position pos, String resolvedAddress) {
    final now = DateTime.now();
    return LocationInfo(
      address: resolvedAddress,
      date: DateFormat('MM/dd/yyyy').format(now),
      time: DateFormat('hh:mm a').format(now),
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude.isFinite ? pos.altitude : null,
      speedMetersPerSecond: pos.speed.isFinite ? pos.speed : null,
      heading: pos.heading.isFinite ? pos.heading : null,
      accuracy: pos.accuracy.isFinite ? pos.accuracy : null,
    );
  }

  LocationInfo copyWith({
    String? address,
    String? date,
    String? time,
    double? latitude,
    double? longitude,
    String? placeName,
    String? locality,
    String? administrativeArea,
    String? country,
    String? postalCode,
    double? altitude,
    double? speedMetersPerSecond,
    double? heading,
    double? accuracy,
  }) {
    return LocationInfo(
      address: address ?? this.address,
      date: date ?? this.date,
      time: time ?? this.time,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeName: placeName ?? this.placeName,
      locality: locality ?? this.locality,
      administrativeArea: administrativeArea ?? this.administrativeArea,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      altitude: altitude ?? this.altitude,
      speedMetersPerSecond: speedMetersPerSecond ?? this.speedMetersPerSecond,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'date': date,
        'time': time,
        'latitude': latitude,
        'longitude': longitude,
        'placeName': placeName,
        'locality': locality,
        'administrativeArea': administrativeArea,
        'country': country,
        'postalCode': postalCode,
        'altitude': altitude,
        'speedMetersPerSecond': speedMetersPerSecond,
        'heading': heading,
        'accuracy': accuracy,
      };

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      address: json['address'] as String? ?? 'Location not available',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      placeName: json['placeName'] as String?,
      locality: json['locality'] as String?,
      administrativeArea: json['administrativeArea'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      altitude: (json['altitude'] as num?)?.toDouble(),
      speedMetersPerSecond: (json['speedMetersPerSecond'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );
  }
}
