import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Lightweight Google Maps preview widget for UI screens that want to mirror
/// the burned-in static-map thumbnail before/after capture.
class MapPreviewWidget extends StatelessWidget {
  const MapPreviewWidget({
    required this.latitude,
    required this.longitude,
    this.height = 140,
    super.key,
  });

  final double latitude;
  final double longitude;
  final double height;

  @override
  Widget build(BuildContext context) {
    final position = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 16),
          markers: {
            Marker(markerId: const MarkerId('current-location'), position: position),
          },
          compassEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          liteModeEnabled: true,
        ),
      ),
    );
  }
}
