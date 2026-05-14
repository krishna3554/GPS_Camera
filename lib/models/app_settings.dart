import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
    );
  }
}
