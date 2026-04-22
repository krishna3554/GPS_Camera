import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_camera/models/geo_photo.dart';
import 'package:gps_camera/providers/photos_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(photosProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<GeoPhoto> photos = ref.watch(photosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: photos.isEmpty
          ? const Center(
              child: Text('No geo-tagged photos found. Capture photos first.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final GeoPhoto photo = photos[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.place_outlined)),
                  title: Text(photo.formattedCoords),
                  subtitle: Text(photo.address?.isNotEmpty == true
                      ? photo.address!
                      : photo.formattedDate),
                );
              },
            ),
    );
  }
}
