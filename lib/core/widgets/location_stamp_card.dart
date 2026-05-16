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
    this.settings,
    this.compactPreview = false,
    super.key,
  });

  final LocationInfo? locationInfo;
  final bool showMap;
  final double cardWidth;
  final AppSettings? settings;
  final bool compactPreview;

  @override
  Widget build(BuildContext context) {
    final providedSettings = settings;
    if (providedSettings != null) {
      return _buildWithSettings(providedSettings);
    }

    return FutureBuilder<AppSettings>(
      future: const SettingsService().load(),
      builder: (context, snapshot) {
        return _buildWithSettings(snapshot.data ?? const AppSettings());
      },
    );
  }

  Widget _buildWithSettings(AppSettings settings) {
    final info = locationInfo;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey('${info?.address ?? 'fallback'}-${settings.overlayTemplate}'),
        child: info == null ? _fallback(settings) : _content(info, settings),
      ),
    );
  }

  Widget _fallback(AppSettings settings) {
    return _cardShell(
      height: settings.overlayTemplate == OverlayTemplateIds.minimalStrip ? 64 : null,
      child: Row(
        children: [
          if (settings.overlayTemplate != OverlayTemplateIds.minimalStrip) ...[
            _mapPlaceholder(size: compactPreview ? 44 : 78),
            const SizedBox(width: 12),
          ],
          const Expanded(
            child: Text(
              'Getting GPS and map...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(onPressed: openAppSettings, child: const Text('Enable')),
        ],
      ),
    );
  }

  Widget _content(LocationInfo info, AppSettings settings) {
    return switch (settings.overlayTemplate) {
      OverlayTemplateIds.minimalStrip => _minimalStrip(info),
      OverlayTemplateIds.fieldReport => _fieldReport(info, settings),
      _ => _classicDark(info, settings),
    };
  }

  Widget _classicDark(LocationInfo info, AppSettings settings) {
    return _cardShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showMap) _StaticMap(info: info, settings: settings, size: compactPreview ? 58 : 86),
          if (showMap) const SizedBox(width: 14),
          Expanded(child: _metadataColumn(info, settings, titleSize: compactPreview ? 11 : 15)),
        ],
      ),
    );
  }

  Widget _minimalStrip(LocationInfo info) {
    return _cardShell(
      height: compactPreview ? 54 : 76,
      padding: EdgeInsets.symmetric(
        horizontal: compactPreview ? 10 : 16,
        vertical: compactPreview ? 8 : 12,
      ),
      child: Row(
        children: [
          const Icon(Icons.place, color: Color(0xFFF5A623), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              info.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compactPreview ? 11 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            info.time.isEmpty ? info.date : '${info.date}  ${info.time}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: compactPreview ? 9 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldReport(LocationInfo info, AppSettings settings) {
    return _cardShell(
      padding: EdgeInsets.all(compactPreview ? 8 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showMap) _StaticMap(info: info, settings: settings, size: compactPreview ? 64 : 108),
          if (showMap) const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1DB954)),
                      ),
                      child: const Text(
                        'GPS-STAMPED',
                        style: TextStyle(
                          color: Color(0xFF8DFFB0),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      info.time,
                      style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _metadataColumn(info, settings, titleSize: compactPreview ? 11 : 16, structured: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadataColumn(
    LocationInfo info,
    AppSettings settings, {
    required double titleSize,
    bool structured = false,
  }) {
    final muted = Colors.white.withValues(alpha: 0.78);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.address,
          maxLines: structured ? 2 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            height: 1.16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: structured ? 8 : 6),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _metaPill(Icons.calendar_today, info.date, muted),
            _metaPill(Icons.access_time, info.time, muted),
          ],
        ),
        if (settings.showCoordinates) ...[
          SizedBox(height: structured ? 8 : 6),
          Text(
            '${info.latitude.toStringAsFixed(5)}, ${info.longitude.toStringAsFixed(5)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF80D8FF),
              fontSize: compactPreview ? 9.5 : 13,
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
            ),
          ),
        ],
        if (settings.showCompassSpeedAltitude && !compactPreview) ...[
          const SizedBox(height: 5),
          Text(
            'C ${info.heading?.toStringAsFixed(0) ?? '--'}°   S ${info.speedMetersPerSecond?.toStringAsFixed(1) ?? '--'}   A ${info.altitude?.toStringAsFixed(0) ?? '--'}m',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: muted, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _metaPill(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: compactPreview ? 10 : 13),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color, fontSize: compactPreview ? 9 : 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _cardShell({required Widget child, double? height, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(compactPreview ? 10 : 18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: cardWidth,
          height: height,
          padding: padding ?? EdgeInsets.all(compactPreview ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(compactPreview ? 10 : 18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _mapPlaceholder({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
    );
  }
}

class _StaticMap extends StatelessWidget {
  const _StaticMap({required this.info, required this.settings, required this.size});

  final LocationInfo info;
  final AppSettings settings;
  final double size;

  @override
  Widget build(BuildContext context) {
    final uri = const GoogleMapService().staticMapUri(
      latitude: info.latitude,
      longitude: info.longitude,
      width: 320,
      height: 320,
      zoom: settings.mapZoomLevel.round(),
      mapStyle: settings.mapStyle,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.2),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          uri.toString(),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : Container(
                  color: const Color(0xFF263238),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                ),
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF263238),
            child: const Icon(Icons.map_outlined, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
