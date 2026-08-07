import 'package:flutter/material.dart';

class AppToast {
  const AppToast._();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    return messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onInverseSurface),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
