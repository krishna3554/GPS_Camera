import 'package:flutter/material.dart';

import '../models/geo_photo_model.dart';
import 'map_preview_widget.dart';

/// On-screen preview equivalent of the geo metadata that is burned into output images.
class GeoInfoOverlay extends StatelessWidget {
  const GeoInfoOverlay({required this.geoPhoto, super.key});

  final GeoPhotoModel geoPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: MapPreviewWidget(
              latitude: geoPhoto.latitude,
              longitude: geoPhoto.longitude,
              height: 132,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 7,
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, height: 1.25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    geoPhoto.shortTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  Text(geoPhoto.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('Lat ${geoPhoto.formattedLatitude}°   Long ${geoPhoto.formattedLongitude}°'),
                  Text(geoPhoto.formattedDateTime),
                  Text('${geoPhoto.weatherLabel}   ${geoPhoto.speedLabel}   ${geoPhoto.altitudeLabel}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
