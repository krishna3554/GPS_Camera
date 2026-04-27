import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/media_tile.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, this.filteredAssets});

  final List<AssetEntity>? filteredAssets;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<AssetEntity> _assets = [];
  final Set<String> _selectedIds = {};
  bool _selectMode = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _loading = true);
    if (widget.filteredAssets != null) {
      _assets
        ..clear()
        ..addAll(widget.filteredAssets!);
      setState(() => _loading = false);
      return;
    }

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      setState(() => _loading = false);
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    final media = await paths.first.getAssetListPaged(page: 0, size: 60);
    _assets
      ..clear()
      ..addAll(media);
    setState(() => _loading = false);
  }

  Future<void> _deleteSelected() async {
    final selected = _assets.where((a) => _selectedIds.contains(a.id)).toList();
    await PhotoManager.editor.deleteWithIds(selected.map((e) => e.id).toList());
    _selectedIds.clear();
    await _loadAssets();
  }

  Future<void> _shareSelected() async {
    final selected = _assets.where((a) => _selectedIds.contains(a.id)).toList();
    final files = <XFile>[];
    for (final a in selected) {
      final f = await a.file;
      if (f != null) files.add(XFile(f.path));
    }
    if (files.isNotEmpty) await Share.shareXFiles(files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectMode && _selectedIds.isNotEmpty)
            IconButton(
              onPressed: _shareSelected,
              icon: const Icon(Icons.share),
            ),
          if (_selectMode && _selectedIds.isNotEmpty)
            IconButton(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              backgroundColor: Colors.white,
              label: Text(_selectMode ? 'Done' : 'Select'),
              onPressed: () => setState(() {
                _selectMode = !_selectMode;
                _selectedIds.clear();
              }),
            ),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.photo_library, size: 64, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('No media yet'),
                    FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Open Camera'))
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadAssets,
                  child: GridView.builder(
                    itemCount: _assets.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) {
                      final asset = _assets[index];
                      return MediaTile(
                        asset: asset,
                        index: index,
                        selectMode: _selectMode,
                        isSelected: _selectedIds.contains(asset.id),
                        onTap: () {
                          if (_selectMode) {
                            setState(() {
                              if (_selectedIds.contains(asset.id)) {
                                _selectedIds.remove(asset.id);
                              } else {
                                _selectedIds.add(asset.id);
                              }
                            });
                          } else {
                            Navigator.pushNamed(
                              context,
                              AppConstants.routeDetail,
                              arguments: DetailScreenArgs(
                                  assets: _assets, initialIndex: index),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
      bottomSheet: _selectMode && _selectedIds.isNotEmpty
          ? Container(
              color: Colors.white,
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('${_selectedIds.length} items selected'),
                  FilledButton(onPressed: _shareSelected, child: const Text('Share')),
                  FilledButton(onPressed: _deleteSelected, child: const Text('Delete')),
                ],
              ),
            )
          : null,
    );
  }
}
