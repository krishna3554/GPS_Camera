import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/app_photo.dart';
import '../../../services/app_photo_store.dart';
import '../../../services/error_reporter.dart';
import '../../../services/google_map_service.dart';
import '../../gallery/screen/gallery_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final AppPhotoStore _photoStore = const AppPhotoStore();
  final Set<String> _expanded = {};
  List<_LocationEntry> _entries = const [];
  bool _loading = true;
  bool _mapView = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final photos = await _photoStore.loadPhotos();
      final grouped = <String, List<AppPhoto>>{};
      for (final photo in photos) {
        final name = _locationName(photo);
        grouped.putIfAbsent(name, () => []).add(photo);
      }
      final entries = grouped.entries
          .map((entry) => _LocationEntry(name: entry.key, photos: entry.value))
          .toList()
        ..sort((a, b) => b.latest.compareTo(a.latest));
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (error, stackTrace) {
      await ErrorReporter.recordError(error, stackTrace, reason: 'Failed to load locations.');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load locations. Pull to retry.')));
    }
  }

  String _locationName(AppPhoto photo) {
    final info = photo.locationInfo;
    if ((info.locality ?? '').isNotEmpty) return info.locality!;
    final parts = info.address.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.length > 1) return parts[parts.length - 2];
    return parts.isNotEmpty ? parts.first : 'Unknown location';
  }

  List<_LocationEntry> get _filteredEntries {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _entries;
    return _entries.where((entry) {
      final date = DateFormat.yMMMMd().format(entry.latest).toLowerCase();
      return entry.name.toLowerCase().contains(q) ||
          entry.address.toLowerCase().contains(q) ||
          date.contains(q);
    }).toList();
  }

  Map<String, List<_LocationEntry>> _entriesByDate(List<_LocationEntry> entries) {
    final grouped = <String, List<_LocationEntry>>{};
    for (final entry in entries) {
      final key = DateFormat.yMMMMEEEEd().format(entry.latest);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return grouped;
  }

  void _openGallery(_LocationEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GalleryScreen(filteredPhotos: entry.photos, title: entry.name),
      ),
    );
  }

  Future<void> _deleteEntry(_LocationEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${entry.name}?'),
        content: Text('This removes ${entry.photos.length} photos from this app and deletes local files.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    for (final photo in entry.photos) {
      await _photoStore.deletePhoto(photo);
    }
    await _load();
  }

  void _showActions(_LocationEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('View photos'), onTap: () { Navigator.pop(context); _openGallery(entry); }),
            ListTile(leading: const Icon(Icons.map), title: const Text('Open location in maps'), onTap: () { Navigator.pop(context); setState(() => _mapView = true); }),
            ListTile(leading: const Icon(Icons.share), title: const Text('Share'), onTap: () { Navigator.pop(context); Share.share('📍 ${entry.name}\n${entry.address}\n${entry.photos.length} photos captured with GPS Camera'); }),
            ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete'), onTap: () { Navigator.pop(context); _deleteEntry(entry); }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
        actions: [
          IconButton(
            tooltip: _mapView ? 'Show list' : 'Show map',
            onPressed: () => setState(() => _mapView = !_mapView),
            icon: Icon(_mapView ? Icons.view_list : Icons.map),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _SearchHeader(onChanged: (value) => setState(() => _query = value))),
                  if (_entries.isEmpty)
                    const SliverFillRemaining(hasScrollBody: false, child: _EmptyLocations())
                  else if (entries.isEmpty)
                    const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('No locations match your search.')))
                  else if (_mapView)
                    SliverFillRemaining(child: _LocationsMap(entries: entries))
                  else
                    ..._entriesByDate(entries).entries.map((section) => SliverMainAxisGroup(slivers: [
                          SliverToBoxAdapter(child: _DateHeader(label: '${section.key} • ${section.value.length} locations')),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = section.value[index];
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 220 + (index * 45)),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) => Opacity(
                                    opacity: value,
                                    child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
                                  ),
                                  child: _LocationCard(
                                    entry: entry,
                                    expanded: _expanded.contains(entry.name),
                                    onTap: () => setState(() => _expanded.contains(entry.name) ? _expanded.remove(entry.name) : _expanded.add(entry.name)),
                                    onLongPress: () => _showActions(entry),
                                  ),
                                );
                              },
                              childCount: section.value.length,
                            ),
                          ),
                        ])),
                ],
              ),
            ),
    );
  }
}

class _LocationEntry {
  const _LocationEntry({required this.name, required this.photos});
  final String name;
  final List<AppPhoto> photos;
  AppPhoto get primary => photos.first;
  DateTime get latest => photos.map((photo) => photo.capturedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  String get address => primary.locationInfo.address;
  double get latitude => primary.locationInfo.latitude;
  double get longitude => primary.locationInfo.longitude;
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.onChanged});
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by location or date',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      );
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.entry, required this.expanded, required this.onTap, required this.onLongPress});
  final _LocationEntry entry;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final info = entry.primary.locationInfo;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MapThumb(latitude: entry.latitude, longitude: entry.longitude),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(entry.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text('${DateFormat.yMMMd().format(entry.latest)} • ${info.time}', style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Chip(label: Text('${entry.photos.length} photos'), visualDensity: VisualDensity.compact),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    height: 78,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(entry.photos[index].filePath), width: 78, height: 78, fit: BoxFit.cover),
                      ),
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: entry.photos.length,
                    ),
                  ),
                ),
                crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapThumb extends StatelessWidget {
  const _MapThumb({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
  @override
  Widget build(BuildContext context) {
    final uri = const GoogleMapService().staticMapUri(latitude: latitude, longitude: longitude, width: 220, height: 220, zoom: 15);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        uri.toString(),
        width: 86,
        height: 86,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(width: 86, height: 86, color: Colors.white10, child: const Icon(Icons.map)),
      ),
    );
  }
}

class _LocationsMap extends StatelessWidget {
  const _LocationsMap({required this.entries});
  final List<_LocationEntry> entries;
  @override
  Widget build(BuildContext context) {
    final center = LatLng(entries.first.latitude, entries.first.longitude);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 11),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.gps_camera'),
            MarkerLayer(markers: entries.map((entry) => Marker(point: LatLng(entry.latitude, entry.longitude), width: 48, height: 48, child: const Icon(Icons.location_pin, color: Colors.red, size: 42))).toList()),
          ],
        ),
      ),
    );
  }
}

class _EmptyLocations extends StatelessWidget {
  const _EmptyLocations();
  @override
  Widget build(BuildContext context) => const Center(child: Text('No location data available yet'));
}
