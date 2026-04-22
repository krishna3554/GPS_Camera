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

  String get _staticMapUrl {
    final String coordinate = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

    return Uri.https('staticmap.openstreetmap.de', '/staticmap.php', <String, String>{
      'center': coordinate,
      'zoom': zoom.toString(),
      'size': '300x200',
      'markers': '$coordinate,red',
    }).toString();
  }

  @override
  Widget build(BuildContext context) {
    final String url = _staticMapUrl;
    debugPrint(
      '[MapThumbnail] Loading OpenStreetMap static image: $url '
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
        child: Image.network(
          url,
          headers: const <String, String>{'User-Agent': 'GPSCameraApp/1.0 (Flutter)'},
          fit: BoxFit.cover,
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) {
              debugPrint('[MapThumbnail] OpenStreetMap image loaded successfully.');
              return child;
            }

            final int? expected = loadingProgress.expectedTotalBytes;
            final int loaded = loadingProgress.cumulativeBytesLoaded;
            if (expected != null) {
              debugPrint('[MapThumbnail] Loading progress: $loaded / $expected bytes');
            } else {
              debugPrint('[MapThumbnail] Loading progress: $loaded bytes');
            }

            return const ColoredBox(
              color: Colors.black26,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            debugPrint('[MapThumbnail] Failed to load OpenStreetMap image.');
            debugPrint('[MapThumbnail] URL: $url');
            debugPrint('[MapThumbnail] Error: $error');
            if (stackTrace != null) {
              debugPrint('[MapThumbnail] StackTrace: $stackTrace');
            }

            return const ColoredBox(
              color: Colors.black45,
              child: Center(
                child: Icon(Icons.map_outlined, color: Colors.white70, size: 22),
              ),
            );
          },
        ),
      ),
    );
  }
}
