import 'dart:async';

import '../../models/location_info.dart';
import '../../services/location_service.dart';

class LocationUtils {
  static const LocationService _locationService = LocationService();

  static Future<LocationInfo?> getCurrentLocationInfo() async {
    try {
      final geoPhoto = await _locationService.getCurrentGeoPhoto();
      return LocationInfo(
        address: geoPhoto.address,
        date: geoPhoto.capturedAt.toLocal().toString().split(' ').first,
        time: geoPhoto.formattedDateTime.split('  ').last,
        latitude: geoPhoto.latitude,
        longitude: geoPhoto.longitude,
        placeName: geoPhoto.placeName,
        locality: geoPhoto.locality,
        administrativeArea: geoPhoto.administrativeArea,
        country: geoPhoto.country,
        postalCode: geoPhoto.postalCode,
        altitude: geoPhoto.altitude,
        speedMetersPerSecond: geoPhoto.speedMetersPerSecond,
        heading: geoPhoto.heading,
        accuracy: geoPhoto.accuracy,
      );
    } catch (_) {
      return null;
    }
  }

  static Stream<LocationInfo?> locationStream() async* {
    while (true) {
      yield await getCurrentLocationInfo();
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }
}
