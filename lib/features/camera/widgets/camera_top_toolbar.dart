import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraTopToolbar extends StatelessWidget {
  const CameraTopToolbar({
    required this.flashMode,
    required this.onFlashModeChanged,
    required this.onOpenSettings,
    this.onOpenGallery,
    super.key,
  });

  final FlashMode flashMode;
  final ValueChanged<FlashMode> onFlashModeChanged;
  final VoidCallback onOpenSettings;
  final VoidCallback? onOpenGallery;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.photo_library_outlined,
              tooltip: 'Open gallery',
              onPressed: onOpenGallery,
            ),
            const Spacer(),
            _ToolbarButton(
              icon: _flashIcon(flashMode),
              tooltip: 'Change flash mode',
              onPressed: () => onFlashModeChanged(_nextFlashMode(flashMode)),
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.settings_outlined,
              tooltip: 'Open settings',
              onPressed: onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }

  static FlashMode _nextFlashMode(FlashMode mode) => switch (mode) {
        FlashMode.off => FlashMode.auto,
        FlashMode.auto => FlashMode.always,
        FlashMode.always => FlashMode.torch,
        FlashMode.torch => FlashMode.off,
      };

  static IconData _flashIcon(FlashMode mode) => switch (mode) {
        FlashMode.off => Icons.flash_off,
        FlashMode.auto => Icons.flash_auto,
        FlashMode.always => Icons.flash_on,
        FlashMode.torch => Icons.highlight,
      };
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
        ),
      );
}
