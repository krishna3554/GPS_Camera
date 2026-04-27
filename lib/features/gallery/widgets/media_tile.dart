import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/utils/date_utils.dart';

class MediaTile extends StatelessWidget {
  const MediaTile({
    required this.asset,
    required this.isSelected,
    required this.selectMode,
    required this.onTap,
    required this.index,
    super.key,
  });

  final AssetEntity asset;
  final bool isSelected;
  final bool selectMode;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (context, snapshot) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: snapshot.hasData ? 1 : 0),
          duration: Duration(milliseconds: (index * 30).clamp(100, 500)),
          builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
          child: GestureDetector(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (snapshot.hasData)
                  Image.memory(snapshot.data!, fit: BoxFit.cover)
                else
                  Container(color: Colors.grey.shade300),
                if (asset.type == AssetType.video)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppDateUtils.formatDuration(asset.videoDuration),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                if (selectMode && isSelected)
                  Container(color: Colors.blue.withValues(alpha: 0.3)),
                if (selectMode && isSelected)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.check, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
