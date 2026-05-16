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

  static const _classicCardColor = Color.fromRGBO(0, 0, 0, 0.70);
  static const _fieldCardColor = Color.fromRGBO(8, 14, 20, 0.84);
  static const _minimalCardColor = Color.fromRGBO(0, 0, 0, 0.78);
  static const _mapFallbackColor = Color(0xFF263038);
  static const _accent = Color(0xFFF5A623);
  static const _coordinateColor = Color(0xFF80D8FF);
  static const _badgeFill = Color.fromRGBO(29, 185, 84, 0.27);
  static const _badgeStroke = Color(0xFF1DB954);
  static const _badgeText = Color(0xFF8DFFB0);

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

  Widget _content(LocationInfo info, AppSettings settings) {
    return switch (settings.overlayTemplate) {
      OverlayTemplateIds.minimalStrip => _minimalStrip(info),
      OverlayTemplateIds.fieldReport => _fieldReport(info, settings),
      _ => _classicDark(info, settings),
    };
  }

  Widget _fallback(AppSettings settings) {
    final height = switch (settings.overlayTemplate) {
      OverlayTemplateIds.minimalStrip => _minimalStripHeight,
      OverlayTemplateIds.fieldReport => _fieldReportHeight,
      _ => _classicHeight,
    };
    return _savedPhotoShell(
      color: settings.overlayTemplate == OverlayTemplateIds.fieldReport
          ? _fieldCardColor
          : settings.overlayTemplate == OverlayTemplateIds.minimalStrip
              ? _minimalCardColor
              : _classicCardColor,
      height: height,
      radius: _cardRadius(height),
      padding: EdgeInsets.all(_innerPadding(height)),
      child: Row(
        children: [
          if (settings.overlayTemplate != OverlayTemplateIds.minimalStrip) ...[
            _mapPlaceholder(width: height * 0.66, height: height * 0.66),
            SizedBox(width: _innerPadding(height)),
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

  Widget _classicDark(LocationInfo info, AppSettings settings) {
    final height = _classicHeight;
    final inner = _innerPadding(height);
    final mapWidth = showMap ? (cardWidth * 0.32).clamp(58.0, 140.0) : 0.0;
    final mapHeight = height - (inner * 2);

    return _savedPhotoShell(
      color: _classicCardColor,
      height: height,
      radius: _cardRadius(height),
      padding: EdgeInsets.all(inner),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showMap) ...[
            _StaticMap(
              info: info,
              settings: settings,
              width: mapWidth,
              height: mapHeight,
              googleLabel: !compactPreview,
            ),
            SizedBox(width: inner),
          ],
          Expanded(child: _classicTextBlock(info, settings, height)),
        ],
      ),
    );
  }

  Widget _classicTextBlock(LocationInfo info, AppSettings settings, double height) {
    final titleSize = compactPreview ? 9.5 : 15.5;
    final bodySize = compactPreview ? 8.5 : 12.5;
    final lineGap = compactPreview ? 2.0 : 5.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _shortTitle(info),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        SizedBox(height: lineGap),
        Text(
          info.address,
          maxLines: compactPreview ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFFEBEEF2),
            fontSize: bodySize,
            fontWeight: FontWeight.w700,
            height: 1.12,
          ),
        ),
        if (settings.showCoordinates) ...[
          SizedBox(height: lineGap),
          Text(
            'Lat ${info.latitude.toStringAsFixed(5)}°   Long ${info.longitude.toStringAsFixed(5)}°',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _coordinateColor,
              fontSize: bodySize,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ],
        SizedBox(height: lineGap),
        Text(
          _formattedDateTime(info),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFFE0E7EE),
            fontSize: bodySize,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        if (settings.showCompassSpeedAltitude && !compactPreview) ...[
          SizedBox(height: lineGap),
          _footerMetrics(info, bodySize - 1),
        ],
      ],
    );
  }

  Widget _minimalStrip(LocationInfo info) {
    final height = _minimalStripHeight;
    return _savedPhotoShell(
      color: _minimalCardColor,
      height: height,
      radius: height * 0.28,
      padding: EdgeInsets.symmetric(
        horizontal: compactPreview ? 8 : 18,
        vertical: compactPreview ? 6 : 10,
      ),
      child: Row(
        children: [
          Text(
            '•',
            style: TextStyle(
              color: _accent,
              fontSize: compactPreview ? 18 : 30,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(width: compactPreview ? 5 : 10),
          Expanded(
            child: Text(
              info.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compactPreview ? 9.5 : 15,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          SizedBox(width: compactPreview ? 6 : 14),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compactPreview ? cardWidth * 0.32 : cardWidth * 0.34),
            child: Text(
              _formattedDateTime(info),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFFDCE2E8),
                fontSize: compactPreview ? 7.5 : 11.5,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldReport(LocationInfo info, AppSettings settings) {
    final height = _fieldReportHeight;
    final inner = _innerPadding(height);
    final mapSize = height - (inner * 2);

    return _savedPhotoShell(
      color: _fieldCardColor,
      height: height,
      radius: _cardRadius(height),
      padding: EdgeInsets.all(inner),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showMap) ...[
            _StaticMap(
              info: info,
              settings: settings,
              width: mapSize,
              height: mapSize,
              googleLabel: !compactPreview,
            ),
            SizedBox(width: inner),
          ],
          Expanded(child: _fieldReportTextBlock(info, settings, height)),
        ],
      ),
    );
  }

  Widget _fieldReportTextBlock(LocationInfo info, AppSettings settings, double height) {
    final titleSize = compactPreview ? 9.5 : 15.5;
    final bodySize = compactPreview ? 8 : 12;
    if (compactPreview) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _badgeFill,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _badgeStroke, width: 0.7),
            ),
            child: const Text(
              'GPS-STAMPED',
              style: TextStyle(
                color: _badgeText,
                fontSize: 6.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 3),
          if (settings.showCoordinates)
            Text(
              '${info.latitude.toStringAsFixed(5)}°, ${info.longitude.toStringAsFixed(5)}°',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _coordinateColor,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compactPreview ? 5 : 10,
                vertical: compactPreview ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: _badgeFill,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _badgeStroke, width: compactPreview ? 0.7 : 1),
              ),
              child: Text(
                'GPS-STAMPED',
                style: TextStyle(
                  color: _badgeText,
                  fontSize: compactPreview ? 6.5 : 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            const Spacer(),
            if (!compactPreview)
              Text(
                info.time,
                style: const TextStyle(
                  color: Color(0xFFE0E7EE),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        SizedBox(height: compactPreview ? 4 : 10),
        Text(
          info.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        SizedBox(height: compactPreview ? 4 : 9),
        Divider(color: Colors.white.withValues(alpha: 0.22), height: 1, thickness: 1),
        SizedBox(height: compactPreview ? 4 : 9),
        if (settings.showCoordinates) ...[
          Text(
            'COORDINATES',
            style: TextStyle(
              color: _coordinateColor,
              fontSize: compactPreview ? 6.5 : 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: compactPreview ? 2 : 5),
          Text(
            '${info.latitude.toStringAsFixed(5)}°, ${info.longitude.toStringAsFixed(5)}°',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _coordinateColor,
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          SizedBox(height: compactPreview ? 3 : 8),
        ],
        Text(
          _formattedDateTime(info),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFFE0E7EE),
            fontSize: bodySize,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ],
    );
  }

  Widget _footerMetrics(LocationInfo info, double fontSize) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _footerMetric('W', '--', _accent, fontSize),
        _footerMetric('C', '${info.heading?.toStringAsFixed(0) ?? '--'}°', const Color(0xFF82DCFF), fontSize),
        _footerMetric('S', info.speedMetersPerSecond?.toStringAsFixed(1) ?? '--', const Color(0xFF00D2FF), fontSize),
        _footerMetric('A', '${info.altitude?.toStringAsFixed(0) ?? '--'}m', const Color(0xFFFFA050), fontSize),
      ],
    );
  }

  Widget _footerMetric(String icon, String label, Color iconColor, double fontSize) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$icon ',
            style: TextStyle(color: iconColor, fontSize: fontSize, fontWeight: FontWeight.w900),
          ),
          TextSpan(
            text: label,
            style: TextStyle(color: const Color(0xFFEBEEF2), fontSize: fontSize, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _savedPhotoShell({
    required Widget child,
    required Color color,
    required double height,
    required double radius,
    required EdgeInsets padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          width: cardWidth,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _mapPlaceholder({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _mapFallbackColor,
        borderRadius: BorderRadius.circular(_mapRadius(height)),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
    );
  }

  double get _classicHeight => compactPreview ? cardWidth * 0.58 : cardWidth * 0.34;

  double get _minimalStripHeight => compactPreview ? cardWidth * 0.32 : cardWidth * 0.21;

  double get _fieldReportHeight => compactPreview ? cardWidth * 0.58 : cardWidth * 0.58;

  double _innerPadding(double height) => (height * 0.08).clamp(compactPreview ? 5.0 : 10.0, compactPreview ? 10.0 : 44.0);

  double _cardRadius(double height) => (height * 0.08).clamp(compactPreview ? 8.0 : 20.0, compactPreview ? 16.0 : 44.0);

  double _mapRadius(double height) => (height * 0.08).clamp(compactPreview ? 6.0 : 14.0, compactPreview ? 12.0 : 32.0);

  String _formattedDateTime(LocationInfo info) {
    final date = info.date.trim();
    final time = info.time.trim();
    if (date.isEmpty) return time;
    if (time.isEmpty) return date;
    return '$date  $time';
  }

  String _shortTitle(LocationInfo info) {
    final place = info.placeName?.trim();
    if (place != null && place.isNotEmpty) return place;
    final locality = info.locality?.trim();
    if (locality != null && locality.isNotEmpty) return locality;
    final parts = info.address.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'GPS Location' : parts.first;
  }
}

class _StaticMap extends StatelessWidget {
  const _StaticMap({
    required this.info,
    required this.settings,
    required this.width,
    required this.height,
    required this.googleLabel,
  });

  final LocationInfo info;
  final AppSettings settings;
  final double width;
  final double height;
  final bool googleLabel;

  @override
  Widget build(BuildContext context) {
    final uri = const GoogleMapService().staticMapUri(
      latitude: info.latitude,
      longitude: info.longitude,
      width: 640,
      height: 420,
      zoom: settings.mapZoomLevel.round(),
      mapStyle: settings.mapStyle,
    );
    final radius = (height * 0.08).clamp(10.0, 24.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: LocationStampCard._mapFallbackColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              uri.toString(),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.map_outlined, color: Colors.white70),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.31), width: 1.5),
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            if (googleLabel)
              Positioned(
                left: 10,
                bottom: 8,
                child: Text(
                  'Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (width * 0.12).clamp(10.0, 16.0),
                    fontWeight: FontWeight.w700,
                    shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
