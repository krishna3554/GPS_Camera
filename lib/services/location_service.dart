import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_photo_model.dart';

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Handles high-accuracy GPS lookup and reverse geocoding for geo-tagged photos.
class LocationService {
  const LocationService();

  Future<GeoPhotoModel> getCurrentGeoPhoto({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException('GPS is disabled. Turn on Location Services and try again.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException('Location permission is permanently denied. Enable it in app settings.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: timeout,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(timeout);
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final address = _formatAddress(place);

      return GeoPhotoModel.fromPosition(
        position: position,
        address: address.isEmpty ? 'Address unavailable' : address,
        placeName: _firstNonEmpty([
          place?.name,
          place?.subLocality,
          place?.locality,
        ]),
        locality: place?.locality,
        administrativeArea: place?.administrativeArea,
        country: place?.country,
        postalCode: place?.postalCode,
      );
    } on TimeoutException {
      throw const LocationServiceException('Location request timed out. Move outdoors and try again.');
    } catch (error) {
      throw LocationServiceException('Unable to get current location: $error');
    }
  }

  String _formatAddress(Placemark? place) {
    if (place == null) return '';
    return [
      place.subThoroughfare,
      place.thoroughfare,
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.postalCode,
      place.country,
    ].where((value) => (value ?? '').trim().isNotEmpty).cast<String>().join(', ');
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
