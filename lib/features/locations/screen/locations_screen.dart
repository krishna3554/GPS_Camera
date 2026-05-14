import 'package:flutter/material.dart';

import '../../../models/app_photo.dart';
import '../../../services/app_photo_store.dart';
import '../../gallery/screen/gallery_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final AppPhotoStore _photoStore = const AppPhotoStore();
  bool _loading = true;
  final Map<String, List<AppPhoto>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final photos = await _photoStore.loadPhotos();
    final grouped = <String, List<AppPhoto>>{};
    for (final photo in photos) {
      final address = photo.locationInfo.address;
      if (address.isEmpty) continue;
      final parts = address.split(',');
      final city = parts.length > 1
          ? parts[parts.length - 2].trim()
          : parts.first.trim();
      grouped.putIfAbsent(city, () => []).add(photo);
    }

    if (!mounted) return;
    setState(() {
      _grouped
        ..clear()
        ..addAll(grouped);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _grouped.isEmpty
              ? const Center(child: Text('No location data available yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: _grouped.entries.map((entry) {
                      return ListTile(
                        title: Text(entry.key),
                        subtitle: Text('${entry.value.length} photos'),
                        leading: const Icon(Icons.place),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => GalleryScreen(
                                filteredPhotos: entry.value,
                                title: entry.key,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
