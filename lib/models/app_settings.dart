import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class OverlayTemplateIds {
  static const classicDark = 'classic_dark';
  static const minimalStrip = 'minimal_strip';
  static const fieldReport = 'field_report';

  static const all = [classicDark, minimalStrip, fieldReport];

  static String label(String id) => switch (id) {
        minimalStrip => 'Minimal Strip',
        fieldReport => 'Field Report',
        _ => 'Classic Dark',
      };

  static String description(String id) => switch (id) {
        minimalStrip => 'Slim address and time strip without a map.',
        fieldReport => 'Structured GPS-stamped field documentation card.',
        _ => 'Map thumbnail with metadata on a dark card.',
      };
}

class AppSettings {
  const AppSettings({
    this.mapStyle = 'standard',
    this.overlayPosition = 'bottom',
    this.showCoordinates = true,
    this.showCompassSpeedAltitude = true,
    this.photoQuality = 'high',
    this.autoSaveToGallery = true,
    this.dateFormat = 'DD/MM/YYYY',
    this.mapZoomLevel = 15,
    this.darkTheme = true,
    this.overlayTemplate = OverlayTemplateIds.classicDark,
  });

  final String mapStyle;
  final String overlayPosition;
  final bool showCoordinates;
  final bool showCompassSpeedAltitude;
  final String photoQuality;
  final bool autoSaveToGallery;
  final String dateFormat;
  final double mapZoomLevel;
  final bool darkTheme;
  final String overlayTemplate;

  ResolutionPreset get resolutionPreset => switch (photoQuality) {
        'medium' => ResolutionPreset.medium,
        'low' => ResolutionPreset.low,
        _ => ResolutionPreset.max,
      };

  ThemeMode get themeMode => darkTheme ? ThemeMode.dark : ThemeMode.light;

  AppSettings copyWith({
    String? mapStyle,
    String? overlayPosition,
    bool? showCoordinates,
    bool? showCompassSpeedAltitude,
    String? photoQuality,
    bool? autoSaveToGallery,
    String? dateFormat,
    double? mapZoomLevel,
    bool? darkTheme,
    String? overlayTemplate,
  }) {
    return AppSettings(
      mapStyle: mapStyle ?? this.mapStyle,
      overlayPosition: overlayPosition ?? this.overlayPosition,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showCompassSpeedAltitude:
          showCompassSpeedAltitude ?? this.showCompassSpeedAltitude,
      photoQuality: photoQuality ?? this.photoQuality,
      autoSaveToGallery: autoSaveToGallery ?? this.autoSaveToGallery,
      dateFormat: dateFormat ?? this.dateFormat,
      mapZoomLevel: mapZoomLevel ?? this.mapZoomLevel,
      darkTheme: darkTheme ?? this.darkTheme,
      overlayTemplate: overlayTemplate ?? this.overlayTemplate,
    );
  }
}
