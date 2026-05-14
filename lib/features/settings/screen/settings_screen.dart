import 'package:flutter/material.dart';

import '../../../models/app_settings.dart';
import '../../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = const SettingsService();
  AppSettings _settings = const AppSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _settingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(AppSettings settings) async {
    setState(() => _settings = settings);
    await _settingsService.save(settings);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _dropdown(
            title: 'Map Style',
            value: _settings.mapStyle,
            items: const {'standard': 'Standard', 'satellite': 'Satellite', 'terrain': 'Terrain'},
            onChanged: (value) => _save(_settings.copyWith(mapStyle: value)),
          ),
          _dropdown(
            title: 'Overlay Position',
            value: _settings.overlayPosition,
            items: const {'bottom': 'Bottom', 'top': 'Top'},
            onChanged: (value) => _save(_settings.copyWith(overlayPosition: value)),
          ),
          SwitchListTile(
            title: const Text('Show Coordinates'),
            value: _settings.showCoordinates,
            onChanged: (value) => _save(_settings.copyWith(showCoordinates: value)),
          ),
          SwitchListTile(
            title: const Text('Show Compass/Speed/Altitude'),
            subtitle: const Text('Shows or hides the W/C/S/A status row.'),
            value: _settings.showCompassSpeedAltitude,
            onChanged: (value) => _save(_settings.copyWith(showCompassSpeedAltitude: value)),
          ),
          _dropdown(
            title: 'Photo Quality',
            value: _settings.photoQuality,
            items: const {'high': 'High', 'medium': 'Medium', 'low': 'Low'},
            onChanged: (value) => _save(_settings.copyWith(photoQuality: value)),
          ),
          SwitchListTile(
            title: const Text('Auto-save to Gallery'),
            value: _settings.autoSaveToGallery,
            onChanged: (value) => _save(_settings.copyWith(autoSaveToGallery: value)),
          ),
          _dropdown(
            title: 'Date Format',
            value: _settings.dateFormat,
            items: const {'DD/MM/YYYY': 'DD/MM/YYYY', 'YYYY-MM-DD': 'YYYY-MM-DD'},
            onChanged: (value) => _save(_settings.copyWith(dateFormat: value)),
          ),
          ListTile(
            title: const Text('Map Zoom Level'),
            subtitle: Slider(
              value: _settings.mapZoomLevel,
              min: 10,
              max: 18,
              divisions: 8,
              label: _settings.mapZoomLevel.round().toString(),
              onChanged: (value) => _save(_settings.copyWith(mapZoomLevel: value.roundToDouble())),
            ),
            trailing: Text(_settings.mapZoomLevel.round().toString()),
          ),
          SwitchListTile(
            title: const Text('App Theme'),
            subtitle: Text(_settings.darkTheme ? 'Dark' : 'Light'),
            value: _settings.darkTheme,
            onChanged: (value) => _save(_settings.copyWith(darkTheme: value)),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String title,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        items: items.entries
            .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}
