import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/media_saver.dart';
import '../../../models/captured_media.dart';
import '../../../models/location_info.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.filePath,
    required this.locationInfo,
    required this.type,
    super.key,
  });

  final String filePath;
  final LocationInfo locationInfo;
  final MediaType type;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  VideoPlayerController? _video;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.type == MediaType.video) {
      _video = VideoPlayerController.file(File(widget.filePath));
      await _video!.initialize();
      _video!
        ..setLooping(true)
        ..setVolume(0)
        ..play();
    }

    final ok = widget.type == MediaType.photo
        ? await MediaSaver.savePhoto(
            filePath: widget.filePath, locationInfo: widget.locationInfo)
        : await MediaSaver.saveVideo(
            filePath: widget.filePath, locationInfo: widget.locationInfo);

    if (!mounted) return;
    if (ok) {
      setState(() => _showBanner = true);
      Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _showBanner = false);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to save — tap Share to save manually'),
        ),
      );
    }

    setState(() {});
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  void _closeToCamera() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeToCamera();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: widget.type == MediaType.photo
                  ? Image.file(File(widget.filePath), fit: BoxFit.cover)
                  : (_video != null && _video!.value.isInitialized)
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _video!.value.size.width,
                            height: _video!.value.size.height,
                            child: VideoPlayer(_video!),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
            ),
            Positioned(
              top: 44,
              left: 8,
              child: IconButton(
                onPressed: _closeToCamera,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 400),
                  offset: _showBanner ? Offset.zero : const Offset(0, -1),
                  child: AnimatedOpacity(
                    opacity: _showBanner ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Saved to camera roll',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                height: 80,
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Share.shareXFiles(
                        [XFile(widget.filePath)],
                        text:
                            '📍 ${widget.locationInfo.address}\n📅 ${widget.locationInfo.date} ${widget.locationInfo.time}\nCaptured with GPS Camera',
                      ),
                      child: const Text('Share now'),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
