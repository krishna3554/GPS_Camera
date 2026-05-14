import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/app_settings.dart';
import '../../models/location_info.dart';
import '../../services/google_map_service.dart';
import '../../services/settings_service.dart';

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

    return FutureBuilder<AppSettings>(
      future: const SettingsService().load(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? const AppSettings();
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
                child: info == null ? _fallback() : _content(info, settings),
              ),
            ),
          ),
        );
      },
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
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Getting GPS and map...'),
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

  Widget _content(LocationInfo info, AppSettings settings) {
    return Row(
      children: [
        if (showMap) _StaticMap(info: info, settings: settings),
        if (showMap) const SizedBox(width: 8),
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
              if (settings.showCoordinates) ...[
                const SizedBox(height: 2),
                Text(
                  '${info.latitude.toStringAsFixed(5)}, ${info.longitude.toStringAsFixed(5)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ],
              if (settings.showCompassSpeedAltitude) ...[
                const SizedBox(height: 2),
                Text(
                  'W --  C ${info.heading?.toStringAsFixed(0) ?? '--'}°  S ${info.speedMetersPerSecond?.toStringAsFixed(1) ?? '--'}  A ${info.altitude?.toStringAsFixed(0) ?? '--'}m',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StaticMap extends StatelessWidget {
  const _StaticMap({required this.info, required this.settings});

  final LocationInfo info;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final uri = const GoogleMapService().staticMapUri(
      latitude: info.latitude,
      longitude: info.longitude,
      width: 200,
      height: 150,
      zoom: settings.mapZoomLevel.round(),
      mapStyle: settings.mapStyle,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 70,
        height: 70,
        child: Image.network(
          uri.toString(),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.map_outlined, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
