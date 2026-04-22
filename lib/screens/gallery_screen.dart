import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_camera/models/geo_photo.dart';
import 'package:gps_camera/providers/photos_provider.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
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
      appBar: AppBar(title: const Text('Gallery')),
      body: photos.isEmpty
          ? const Center(child: Text('No photos yet. Capture one in Camera tab.'))
          : RefreshIndicator(
              onRefresh: () => ref.read(photosProvider.notifier).loadAll(),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return _PhotoCard(photo: photo);
                },
              ),
            ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.photo});

  final GeoPhoto photo;

  @override
  Widget build(BuildContext context) {
    final File file = File(photo.imagePath);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: file.existsSync()
                ? Image.file(file, width: double.infinity, fit: BoxFit.cover)
                : Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined, size: 48),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.formattedCoords,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  photo.formattedDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
