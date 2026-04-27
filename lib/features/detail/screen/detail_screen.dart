import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/utils/media_saver.dart';
import '../../../core/widgets/location_stamp_card.dart';
import '../../../models/location_info.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    required this.assets,
    required this.initialIndex,
    super.key,
  });

  final List<AssetEntity> assets;
  final int initialIndex;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final PageController _pageController;
  late int _index;
  VideoPlayerController? _video;
  LocationInfo? _location;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
    _preparePage(_index);
  }

  Future<void> _preparePage(int index) async {
    _video?.dispose();
    _video = null;

    final asset = widget.assets[index];
    _location = await MediaSaver.loadMetadataForAsset(asset);

    if (asset.type == AssetType.video) {
      final file = await asset.file;
      if (file != null) {
        _video = VideoPlayerController.file(file);
        await _video!.initialize();
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _video?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.assets.length,
            onPageChanged: (value) {
              _index = value;
              _preparePage(value);
            },
            itemBuilder: (context, index) {
              final asset = widget.assets[index];
              return FutureBuilder<File?>(
                future: asset.file,
                builder: (context, snapshot) {
                  final file = snapshot.data;
                  if (file == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (asset.type == AssetType.video && index == _index && _video != null) {
                    return GestureDetector(
                      onTap: () {
                        if (_video!.value.isPlaying) {
                          _video!.pause();
                        } else {
                          _video!.play();
                        }
                        setState(() {});
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _video!.value.size.width,
                              height: _video!.value.size.height,
                              child: VideoPlayer(_video!),
                            ),
                          ),
                          Center(
                            child: Icon(
                              _video!.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white70,
                              size: 64,
                            ),
                          ),
                          if (_video!.value.isInitialized)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: LinearProgressIndicator(
                                value: _video!.value.position.inMilliseconds /
                                    (_video!.value.duration.inMilliseconds == 0
                                        ? 1
                                        : _video!.value.duration.inMilliseconds),
                                minHeight: 2,
                                color: const Color(0xFFF5A623),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return InteractiveViewer(child: Image.file(file, fit: BoxFit.contain));
                },
              );
            },
          ),
          Positioned(
            top: 44,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Positioned(
            top: 52,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_index + 1} of ${widget.assets.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 74,
            child: Center(
              child: LocationStampCard(
                locationInfo: _location,
                cardWidth: MediaQuery.of(context).size.width * 0.85,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      final info = _location;
                      if (info == null) return;
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (_) => SizedBox(
                          height: 280,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Scan to open location'),
                              const SizedBox(height: 12),
                              QrImageView(
                                data:
                                    'https://maps.openstreetmap.org/?mlat=${info.latitude}&mlon=${info.longitude}',
                                size: 200,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_2),
                  ),
                  IconButton(
                    onPressed: () async {
                      final file = await widget.assets[_index].file;
                      if (file != null) {
                        await Share.shareXFiles([XFile(file.path)]);
                      }
                    },
                    icon: const Icon(Icons.share),
                  ),
                  IconButton(
                    onPressed: () async {
                      final delete = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete media?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (!delete) return;
                      await PhotoManager.editor.deleteWithIds([
                        widget.assets[_index].id,
                      ]);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
