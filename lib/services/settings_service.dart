import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsService {
  static const mapStyleKey = 'settings_map_style';
  static const overlayPositionKey = 'settings_overlay_position';
  static const showCoordinatesKey = 'settings_show_coordinates';
  static const showCompassSpeedAltitudeKey = 'settings_show_compass_speed_altitude';
  static const photoQualityKey = 'settings_photo_quality';
  static const autoSaveToGalleryKey = 'settings_auto_save_to_gallery';
  static const dateFormatKey = 'settings_date_format';
  static const mapZoomLevelKey = 'settings_map_zoom_level';
  static const darkThemeKey = 'settings_dark_theme';
  static const overlayTemplateKey = 'settings_overlay_template';

  const SettingsService();

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      mapStyle: prefs.getString(mapStyleKey) ?? 'standard',
      overlayPosition: prefs.getString(overlayPositionKey) ?? 'bottom',
      showCoordinates: prefs.getBool(showCoordinatesKey) ?? true,
      showCompassSpeedAltitude:
          prefs.getBool(showCompassSpeedAltitudeKey) ?? true,
      photoQuality: prefs.getString(photoQualityKey) ?? 'high',
      autoSaveToGallery: prefs.getBool(autoSaveToGalleryKey) ?? true,
      dateFormat: prefs.getString(dateFormatKey) ?? 'DD/MM/YYYY',
      mapZoomLevel: prefs.getDouble(mapZoomLevelKey) ?? 15,
      darkTheme: prefs.getBool(darkThemeKey) ?? true,
      overlayTemplate: prefs.getString(overlayTemplateKey) ?? OverlayTemplateIds.classicDark,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(mapStyleKey, settings.mapStyle);
    await prefs.setString(overlayPositionKey, settings.overlayPosition);
    await prefs.setBool(showCoordinatesKey, settings.showCoordinates);
    await prefs.setBool(
        showCompassSpeedAltitudeKey, settings.showCompassSpeedAltitude);
    await prefs.setString(photoQualityKey, settings.photoQuality);
    await prefs.setBool(autoSaveToGalleryKey, settings.autoSaveToGallery);
    await prefs.setString(dateFormatKey, settings.dateFormat);
    await prefs.setDouble(mapZoomLevelKey, settings.mapZoomLevel);
    await prefs.setBool(darkThemeKey, settings.darkTheme);
    await prefs.setString(overlayTemplateKey, settings.overlayTemplate);
  }
}
