import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_static_maps_controller/google_static_maps_controller.dart' as static_maps;
import 'package:http/http.dart' as http;

/// Generates and downloads Google Static Maps thumbnails for the burned overlay.
class GoogleMapService {
  const GoogleMapService({http.Client? client, String? apiKey})
      : _client = client,
        _apiKey = apiKey ?? const String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  final http.Client? _client;
  final String _apiKey;

  Uri staticMapUri({
    required double latitude,
    required double longitude,
    int width = 640,
    int height = 420,
    int zoom = 16,
  }) {
    final controller = static_maps.StaticMapController(
      googleApiKey: _apiKey,
      width: width,
      height: height,
      zoom: zoom,
      center: static_maps.Location(latitude, longitude),
      markers: [
        static_maps.Marker(
          color: Colors.red,
          locations: [static_maps.Location(latitude, longitude)],
        ),
      ],
    );

    final url = controller.url;
    return url.replace(
      queryParameters: {
        ...url.queryParameters,
        'scale': '2',
        'maptype': 'hybrid',
      },
    );
  }

  Future<Uint8List?> fetchThumbnail({
    required double latitude,
    required double longitude,
    int width = 640,
    int height = 420,
  }) async {
    if (_apiKey.trim().isEmpty || _apiKey == 'YOUR_API_KEY') {
      return null;
    }

    final client = _client ?? http.Client();
    final response = await client.get(
      staticMapUri(
        latitude: latitude,
        longitude: longitude,
        width: width,
        height: height,
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    return response.bodyBytes;
  }
}
