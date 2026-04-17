import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<void> ensurePermission() async {
    final locationStatus = await Permission.locationWhenInUse.request();
    if (!locationStatus.isGranted) {
      throw Exception('Location permission denied');
    }
  }

  Future<Position> getCurrentPosition() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> reverseGeocode(double lat, double lng) async {
    final places = await placemarkFromCoordinates(lat, lng);
    if (places.isEmpty) return 'Unknown location';
    final p = places.first;
    return [p.street, p.locality, p.administrativeArea, p.country]
        .where((e) => e != null && e!.trim().isNotEmpty)
        .map((e) => e!.trim())
        .join(', ');
  }
}
