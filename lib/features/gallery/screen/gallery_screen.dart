import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/app_photo.dart';
import '../../../services/app_photo_store.dart';
import '../../../services/error_reporter.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, this.filteredPhotos, this.title = 'My Photos'});

  final List<AppPhoto>? filteredPhotos;
  final String title;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final AppPhotoStore _photoStore = const AppPhotoStore();
  List<AppPhoto> _photos = const [];
  final Set<String> _selectedIds = {};
  bool _loading = true;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.filteredPhotos != null) {
      _photos = widget.filteredPhotos!;
      _loading = false;
    } else {
      _loadPhotos();
    }
  }

  Future<void> _loadPhotos() async {
    if (widget.filteredPhotos != null) {
      setState(() {
        _photos = widget.filteredPhotos!;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final photos = await _photoStore.loadPhotos();
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _selectedIds.clear();
        _loading = false;
      });
    } catch (error, stackTrace) {
      await ErrorReporter.recordError(error, stackTrace, reason: 'Failed to load gallery photos.');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load saved photos. Pull to retry.')));
    }
  }

  Map<String, List<AppPhoto>> _groupByDate() {
    final grouped = <String, List<AppPhoto>>{};
    for (final photo in _photos) {
      final key = DateFormat.yMMMMEEEEd().format(photo.capturedAt);
      grouped.putIfAbsent(key, () => []).add(photo);
    }
    return grouped;
  }

  void _openPhoto(AppPhoto photo) {
    Navigator.of(context)
        .push(PageRouteBuilder<void>(
          pageBuilder: (_, animation, __) => AppPhotoViewer(
            photos: _photos,
            initialIndex: _photos.indexOf(photo),
            photoStore: _photoStore,
          ),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ))
        .then((_) => _loadPhotos());
  }

  void _toggleSelection(AppPhoto photo) {
    setState(() {
      if (_selectedIds.contains(photo.id)) {
        _selectedIds.remove(photo.id);
      } else {
        _selectedIds.add(photo.id);
      }
    });
  }

  Future<void> _shareSelected() async {
    final selected = _photos.where((photo) => _selectedIds.contains(photo.id)).toList();
    if (selected.isEmpty) return;
    try {
      await Share.shareXFiles(selected.map((photo) => XFile(photo.filePath)).toList(), text: 'GPS Camera photos');
    } catch (error, stackTrace) {
      await ErrorReporter.recordError(error, stackTrace, reason: 'Failed to share selected photos.');
    }
  }

  Future<void> _deleteSelected() async {
    final selected = _photos.where((photo) => _selectedIds.contains(photo.id)).toList();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${selected.length} photos?'),
        content: const Text('This removes selected photos from this app and deletes local files.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    for (final photo in selected) {
      await _photoStore.deletePhoto(photo);
    }
    await _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${_selectedIds.length} selected' : widget.title),
        centerTitle: true,
        leading: _selectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(_selectedIds.clear))
            : IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? _EmptyGallery(onOpenCamera: () => Navigator.pop(context))
              : RefreshIndicator(
                  onRefresh: _loadPhotos,
                  child: CustomScrollView(
                    slivers: grouped.entries.expand((entry) {
                      return [
                        SliverToBoxAdapter(child: _DateHeader(label: '${entry.key} • ${entry.value.length} photos')),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final photo = entry.value[index];
                                return _GalleryTile(
                                  photo: photo,
                                  selected: _selectedIds.contains(photo.id),
                                  selectionMode: _selectionMode,
                                  onTap: () => _selectionMode ? _toggleSelection(photo) : _openPhoto(photo),
                                  onLongPress: () => _toggleSelection(photo),
                                );
                              },
                              childCount: entry.value.length,
                            ),
                          ),
                        ),
                      ];
                    }).toList(),
                  ),
                ),
      bottomNavigationBar: _selectionMode
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(onPressed: _shareSelected, icon: const Icon(Icons.share), label: const Text('Share')),
                    TextButton.icon(onPressed: _deleteSelected, icon: const Icon(Icons.delete), label: const Text('Delete')),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
        child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
      );
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.photo, required this.selected, required this.selectionMode, required this.onTap, required this.onLongPress});
  final AppPhoto photo;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final info = photo.locationInfo;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Hero(
        tag: photo.id,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _LazyPhotoThumbnail(photo: photo),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 14, 6, 5),
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                child: Text(
                  '${_shortPlace(info.address)} • ${DateFormat.MMMd().format(photo.capturedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (selectionMode) Container(color: selected ? Colors.blue.withValues(alpha: .28) : Colors.black.withValues(alpha: .18)),
            if (selected)
              const Positioned(top: 7, right: 7, child: CircleAvatar(radius: 13, backgroundColor: Colors.blue, child: Icon(Icons.check, size: 16, color: Colors.white))),
          ],
        ),
      ),
    );
  }

  static String _shortPlace(String address) {
    final parts = address.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? 'Location' : parts.first;
  }
}

class _LazyPhotoThumbnail extends StatelessWidget {
  const _LazyPhotoThumbnail({required this.photo});
  final AppPhoto photo;
  @override
  Widget build(BuildContext context) {
    final targetWidth = (MediaQuery.sizeOf(context).width / 3).round();
    final cacheExtent = (targetWidth * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.file(
      File(photo.filePath),
      fit: BoxFit.cover,
      cacheWidth: cacheExtent,
      filterQuality: FilterQuality.low,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => wasSynchronouslyLoaded || frame != null ? child : const ColoredBox(color: Colors.black12),
      errorBuilder: (_, __, ___) => Container(color: Colors.black12, child: const Icon(Icons.broken_image)),
    );
  }
}

class AppPhotoViewer extends StatefulWidget {
  const AppPhotoViewer({required this.photos, required this.initialIndex, required this.photoStore, super.key});
  final List<AppPhoto> photos;
  final int initialIndex;
  final AppPhotoStore photoStore;

  @override
  State<AppPhotoViewer> createState() => _AppPhotoViewerState();
}

class _AppPhotoViewerState extends State<AppPhotoViewer> {
  late final PageController _pageController = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  AppPhoto get _photo => widget.photos[_index];

  Future<void> _share() async {
    final photo = _photo;
    await Share.shareXFiles([XFile(photo.filePath)], text: '📍 ${photo.locationInfo.address}\n📅 ${photo.locationInfo.date} ${photo.locationInfo.time}\nCaptured with GPS Camera');
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This removes the photo from this app and deletes the local file.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.photoStore.deletePhoto(_photo);
    if (mounted) Navigator.pop(context);
  }

  void _showInfo() {
    final info = _photo.locationInfo;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Photo metadata', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(info.address),
            const SizedBox(height: 8),
            Text('${info.latitude.toStringAsFixed(6)}, ${info.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            Text('${info.date} ${info.time}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              return Hero(
                tag: photo.id,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(child: Image.file(File(photo.filePath), fit: BoxFit.contain)),
                ),
              );
            },
          ),
          Positioned(top: 36, left: 8, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white))),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: .72), borderRadius: BorderRadius.circular(22)),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(onPressed: _share, icon: const Icon(Icons.share, color: Colors.white), tooltip: 'Share'),
                    IconButton(onPressed: _showInfo, icon: const Icon(Icons.info_outline, color: Colors.white), tooltip: 'Info'),
                    IconButton(onPressed: _delete, icon: const Icon(Icons.delete, color: Colors.white), tooltip: 'Delete'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({required this.onOpenCamera});
  final VoidCallback onOpenCamera;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.photo_library_outlined, size: 68, color: Colors.grey),
          const SizedBox(height: 10),
          const Text('No photos yet', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Capture your first GPS-stamped memory.'),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: onOpenCamera, icon: const Icon(Icons.camera_alt), label: const Text('Back to Camera')),
        ]),
      );
}
