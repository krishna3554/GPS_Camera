import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/location_info.dart';

class LocationStampCard extends StatelessWidget {
  const LocationStampCard({
    required this.locationInfo,
    this.showMap = true,
    this.cardWidth = 260,
    super.key,
  });

  final LocationInfo? locationInfo;
  final bool showMap;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final info = locationInfo;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: ClipRRect(
        key: ValueKey(info?.address ?? 'fallback'),
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: info == null ? _fallback() : _content(info),
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.location_off),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📍 Location unavailable'),
              TextButton(
                onPressed: openAppSettings,
                child: const Text('Enable location'),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _content(LocationInfo info) {
    return Row(
      children: [
        if (showMap)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 70,
              height: 70,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(info.latitude, info.longitude),
                  initialZoom: 14,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(info.latitude, info.longitude),
                      width: 24,
                      height: 24,
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 16),
                    )
                  ])
                ],
              ),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Icon(Icons.location_on, color: Colors.red, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    info.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                )
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade700, size: 12),
                const SizedBox(width: 4),
                Text(info.date,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.access_time, color: Colors.grey.shade700, size: 12),
                const SizedBox(width: 4),
                Text(info.time,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
