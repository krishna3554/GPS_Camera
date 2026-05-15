import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MapThumbnail extends StatelessWidget {
  const MapThumbnail({
    required this.lat,
    required this.lng,
    super.key,
    this.zoom = 15,
    this.size = 80,
  });

  final double lat;
  final double lng;
  final int zoom;
  final double size;

  String get _tileUrl {
    final int x = _tileX(lng, zoom);
    final int y = _tileY(lat, zoom);

    return Uri.https('tile.openstreetmap.org', '/$zoom/$x/$y.png').toString();
  }

  int _tileX(double longitude, int z) {
    final double normalizedLng = ((longitude + 180) % 360 + 360) % 360 - 180;
    final double value = (normalizedLng + 180.0) / 360.0 * (1 << z);
    return value.floor();
  }

  int _tileY(double latitude, int z) {
    final double clippedLat = latitude.clamp(-85.05112878, 85.05112878);
    final double latRad = clippedLat * math.pi / 180.0;
    final double value =
        (1.0 - math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi) /
        2.0 *
        (1 << z);
    return value.floor();
  }

  @override
  Widget build(BuildContext context) {
    final String url = _tileUrl;
    debugPrint(
      '[MapThumbnail] Loading OpenStreetMap tile: $url '
      '(lat: $lat, lng: $lng, zoom: $zoom)',
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (context, _) => const ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, _, error) => const ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: Icon(Icons.map_outlined, color: Colors.white70, size: 22),
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.location_pin,
                color: Colors.redAccent,
                size: 22,
                shadows: <Shadow>[Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
