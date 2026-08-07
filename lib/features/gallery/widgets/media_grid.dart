import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'media_tile.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({
    required this.assets,
    required this.selectedIds,
    required this.onAssetTap,
    this.crossAxisCount = 3,
    super.key,
  });

  final List<AssetEntity> assets;
  final Set<String> selectedIds;
  final ValueChanged<AssetEntity> onAssetTap;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final selectMode = selectedIds.isNotEmpty;
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return MediaTile(
          asset: asset,
          isSelected: selectedIds.contains(asset.id),
          selectMode: selectMode,
          onTap: () => onAssetTap(asset),
          index: index,
        );
      },
    );
  }
}
