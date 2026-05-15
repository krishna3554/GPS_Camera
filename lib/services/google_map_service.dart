import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_static_maps_controller/google_static_maps_controller.dart' as static_maps;
import 'package:http/http.dart' as http;

/// Generates and downloads Google Static Maps thumbnails for the burned overlay.
class GoogleMapService {
  const GoogleMapService({
    http.Client? client,
    BaseCacheManager? cacheManager,
    String? apiKey,
  })  : _client = client,
        _cacheManager = cacheManager,
        _apiKey = apiKey ?? const String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  final http.Client? _client;
  final BaseCacheManager? _cacheManager;
  final String _apiKey;

  Uri staticMapUri({
    required double latitude,
    required double longitude,
    int width = 640,
    int height = 420,
    int zoom = 16,
    String mapStyle = 'satellite',
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
        'maptype': mapStyle == 'standard' ? 'roadmap' : mapStyle,
      },
    );
  }

  Future<Uint8List?> fetchThumbnail({
    required double latitude,
    required double longitude,
    int width = 640,
    int height = 420,
    int zoom = 16,
    String mapStyle = 'satellite',
  }) async {
    if (_apiKey.trim().isEmpty || _apiKey == 'YOUR_API_KEY') {
      return null;
    }

    final uri = staticMapUri(
      latitude: latitude,
      longitude: longitude,
      width: width,
      height: height,
      zoom: zoom,
      mapStyle: mapStyle,
    );

    if (_client != null) {
      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return response.bodyBytes;
    }

    final file = await (_cacheManager ?? DefaultCacheManager()).getSingleFile(
      uri.toString(),
    );
    return file.readAsBytes();
  }
}
