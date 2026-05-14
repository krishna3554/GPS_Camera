import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/app_photo.dart';
import '../../../services/app_photo_store.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final AppPhotoStore _photoStore = const AppPhotoStore();
  List<AppPhoto> _photos = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _loading = true);
    final photos = await _photoStore.loadPhotos();
    if (!mounted) return;
    setState(() {
      _photos = photos;
      _loading = false;
    });
  }

  void _openPhoto(AppPhoto photo) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => AppPhotoViewer(photo: photo, photoStore: _photoStore),
        ))
        .then((_) => _loadPhotos());
  }

  Future<void> _sharePhoto(AppPhoto photo) async {
    await Share.shareXFiles(
      [XFile(photo.filePath)],
      text:
          '📍 ${photo.locationInfo.address}\n📅 ${photo.locationInfo.date} ${photo.locationInfo.time}\nCaptured with GPS Camera',
    );
  }

  void _showActions(AppPhoto photo) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fullscreen),
              title: const Text('View'),
              onTap: () {
                Navigator.pop(context);
                _openPhoto(photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _sharePhoto(photo);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Photos'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No app photos yet'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Open Camera'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPhotos,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(2),
                    itemCount: _photos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) {
                      final photo = _photos[index];
                      return GestureDetector(
                        onTap: () => _openPhoto(photo),
                        onLongPress: () => _showActions(photo),
                        child: Hero(
                          tag: photo.id,
                          child: Image.file(
                            File(photo.filePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.black12,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class AppPhotoViewer extends StatelessWidget {
  const AppPhotoViewer({
    required this.photo,
    required this.photoStore,
    super.key,
  });

  final AppPhoto photo;
  final AppPhotoStore photoStore;

  Future<void> _share() async {
    await Share.shareXFiles(
      [XFile(photo.filePath)],
      text:
          '📍 ${photo.locationInfo.address}\n📅 ${photo.locationInfo.date} ${photo.locationInfo.time}\nCaptured with GPS Camera',
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This removes the photo from this app and deletes the local file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await photoStore.deletePhoto(photo);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final info = photo.locationInfo;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: photo.id,
              child: InteractiveViewer(
                child: Image.file(File(photo.filePath), fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 36,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Positioned(
            top: 36,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  onPressed: _share,
                  icon: const Icon(Icons.share, color: Colors.white),
                ),
                IconButton(
                  onPressed: () => _delete(context),
                  icon: const Icon(Icons.delete, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.address,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('${info.date} ${info.time}'),
                      const SizedBox(height: 6),
                      Text(
                        '${info.latitude.toStringAsFixed(6)}, ${info.longitude.toStringAsFixed(6)}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
