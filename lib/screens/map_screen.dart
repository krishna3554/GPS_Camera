import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/geo_photo_provider.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GeoPhotoProvider>(
      builder: (context, provider, _) {
        final photos = provider.photos;
        final center = photos.isEmpty
            ? const LatLng(20.5937, 78.9629)
            : LatLng(photos.first.latitude, photos.first.longitude);

        return Scaffold(
          appBar: AppBar(title: const Text('Photo Map')),
          body: FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 4),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gps_camera_app',
              ),
              MarkerLayer(
                markers: photos
                    .map(
                      (p) => Marker(
                        width: 40,
                        height: 40,
                        point: LatLng(p.latitude, p.longitude),
                        child: const Icon(Icons.location_pin,
                            color: Colors.red, size: 36),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
