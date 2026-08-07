import 'package:flutter/material.dart';

class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    required this.onShowQr,
    required this.onShare,
    required this.onDelete,
    super.key,
  });

  final VoidCallback? onShowQr;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: onShowQr,
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'Show location QR',
            ),
            IconButton(onPressed: onShare, icon: const Icon(Icons.share), tooltip: 'Share media'),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete media',
            ),
          ],
        ),
      ),
    );
  }
}
