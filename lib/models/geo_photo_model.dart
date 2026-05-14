import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

/// Immutable metadata used to permanently burn a geo-tag overlay into a photo.
class GeoPhotoModel {
  const GeoPhotoModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.capturedAt,
    this.placeName,
    this.locality,
    this.administrativeArea,
    this.country,
    this.postalCode,
    this.altitude,
    this.speedMetersPerSecond,
    this.heading,
    this.accuracy,
    this.weatherLabel = 'Weather --',
    this.compassLabel = 'Compass --',
    this.note = 'Captured by GPS Map Camera',
  });

  final double latitude;
  final double longitude;
  final String address;
  final DateTime capturedAt;
  final String? placeName;
  final String? locality;
  final String? administrativeArea;
  final String? country;
  final String? postalCode;
  final double? altitude;
  final double? speedMetersPerSecond;
  final double? heading;
  final double? accuracy;
  final String weatherLabel;
  final String compassLabel;
  final String note;

  String get formattedDateTime =>
      DateFormat('EEEE, dd/MM/yyyy  hh:mm a').format(capturedAt.toLocal());

  String get shortTitle {
    final candidates = [
      placeName,
      locality,
      administrativeArea,
      country,
    ].where((value) => (value ?? '').trim().isNotEmpty).cast<String>().toList();

    if (candidates.isEmpty) return 'GPS Map Camera';
    return candidates.take(3).join(', ');
  }

  String get formattedLatitude => latitude.toStringAsFixed(6);
  String get formattedLongitude => longitude.toStringAsFixed(6);

  String get altitudeLabel => altitude == null
      ? 'Alt --'
      : '${altitude!.round().toString()} m';

  String get speedLabel => speedMetersPerSecond == null
      ? 'Speed --'
      : '${(speedMetersPerSecond! * 3.6).round()} km/h';

  String get headingLabel => heading == null
      ? compassLabel
      : '${heading!.round()}°';

  factory GeoPhotoModel.fromPosition({
    required Position position,
    required String address,
    String? placeName,
    String? locality,
    String? administrativeArea,
    String? country,
    String? postalCode,
    DateTime? capturedAt,
  }) {
    return GeoPhotoModel(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      capturedAt: capturedAt ?? DateTime.now(),
      placeName: placeName,
      locality: locality,
      administrativeArea: administrativeArea,
      country: country,
      postalCode: postalCode,
      altitude: position.altitude.isFinite ? position.altitude : null,
      speedMetersPerSecond: position.speed.isFinite ? position.speed : null,
      heading: position.heading.isFinite ? position.heading : null,
      accuracy: position.accuracy.isFinite ? position.accuracy : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'capturedAt': capturedAt.toIso8601String(),
        'placeName': placeName,
        'locality': locality,
        'administrativeArea': administrativeArea,
        'country': country,
        'postalCode': postalCode,
        'altitude': altitude,
        'speedMetersPerSecond': speedMetersPerSecond,
        'heading': heading,
        'accuracy': accuracy,
        'weatherLabel': weatherLabel,
        'compassLabel': compassLabel,
        'note': note,
      };
}
