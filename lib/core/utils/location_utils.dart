import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/location_info.dart';

class LocationUtils {
  static Future<LocationInfo?> getCurrentLocationInfo() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final p = placemarks.isNotEmpty ? placemarks.first : null;

      final address = [
        if ((p?.subThoroughfare ?? '').isNotEmpty) p?.subThoroughfare,
        if ((p?.thoroughfare ?? '').isNotEmpty) p?.thoroughfare,
        if ((p?.subLocality ?? '').isNotEmpty) p?.subLocality,
        if ((p?.locality ?? '').isNotEmpty) p?.locality,
        if ((p?.administrativeArea ?? '').isNotEmpty) p?.administrativeArea,
        if ((p?.postalCode ?? '').isNotEmpty) p?.postalCode,
        if ((p?.country ?? '').isNotEmpty) p?.country,
      ].whereType<String>().join(', ');

      return LocationInfo.fromPosition(
          pos, address.isEmpty ? 'Location unavailable' : address);
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
