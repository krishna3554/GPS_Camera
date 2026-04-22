import 'package:geocoding/geocoding.dart';

class GeocodingService {
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 6));
      if (placemarks.isEmpty) {
        return _empty;
      }

      final Placemark p = placemarks.first;
      final String address = [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ].whereType<String>().where((String s) => s.trim().isNotEmpty).join(', ');

      return <String, String>{
        'address': address,
        'city': p.locality ?? '',
        'country': p.country ?? '',
      };
    } catch (_) {
      return _empty;
    }
  }

  static const Map<String, String> _empty = <String, String>{
    'address': '',
    'city': '',
    'country': '',
  };
}
