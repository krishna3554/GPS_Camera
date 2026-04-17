import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/geo_photo.dart';
import '../providers/geo_photo_provider.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GeoPhotoProvider>(
      builder: (context, provider, _) {
        final photos = provider.photos;

        return Scaffold(
          appBar: AppBar(title: const Text('Geo Gallery')),
          body: photos.isEmpty
              ? const Center(child: Text('No photos yet. Capture from camera tab.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, i) => _PhotoTile(photo: photos[i]),
                ),
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});
  final GeoPhoto photo;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('MMM d, yyyy • h:mm a').format(photo.timestamp);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Ink.image(
              image: FileImage(File(photo.imagePath)),
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(formatted, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  photo.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Share',
                      onPressed: () =>
                          context.read<GeoPhotoProvider>().sharePhoto(photo),
                      icon: const Icon(Icons.share),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () =>
                          context.read<GeoPhotoProvider>().deletePhoto(photo),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
