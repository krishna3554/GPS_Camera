import 'package:flutter/material.dart';

import 'capture_button.dart';

class CameraControlsBar extends StatelessWidget {
  const CameraControlsBar({
    required this.onCapture,
    required this.onSwitchCamera,
    this.onOpenGallery,
    this.isCapturing = false,
    super.key,
  });

  final VoidCallback? onCapture;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onOpenGallery;
  final bool isCapturing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filledTonal(
              onPressed: onOpenGallery,
              icon: const Icon(Icons.photo_library_outlined),
              tooltip: 'Gallery',
            ),
            CaptureButton(onPressed: onCapture, isBusy: isCapturing),
            IconButton.filledTonal(
              onPressed: onSwitchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
              tooltip: 'Switch camera',
            ),
          ],
        ),
      ),
    );
  }
}
