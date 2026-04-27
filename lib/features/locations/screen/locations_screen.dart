import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/media_saver.dart';
import '../../gallery/screen/gallery_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  bool _loading = true;
  final Map<String, List<AssetEntity>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      setState(() => _loading = false);
      return;
    }

    final paths = await PhotoManager.getAssetPathList(type: RequestType.common);
    final assets = await paths.first.getAssetListPaged(page: 0, size: 200);
    for (final asset in assets) {
      final info = await MediaSaver.loadMetadataForAsset(asset);
      if (info == null || info.address.isEmpty) continue;
      final parts = info.address.split(',');
      final city = parts.length > 1 ? parts[parts.length - 2].trim() : parts.first.trim();
      _grouped.putIfAbsent(city, () => []).add(asset);
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _grouped.isEmpty
              ? const Center(child: Text('No location data available yet'))
              : ListView(
                  children: _grouped.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text('${entry.value.length} photos/videos'),
                      leading: FutureBuilder<AssetEntity?>(
                        future: Future.value(entry.value.first),
                        builder: (_, __) => const Icon(Icons.place),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GalleryScreen(filteredAssets: entry.value),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
    );
  }
}
