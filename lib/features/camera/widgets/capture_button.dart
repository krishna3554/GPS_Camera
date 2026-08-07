import 'package:flutter/material.dart';

class CaptureButton extends StatelessWidget {
  const CaptureButton({
    required this.onPressed,
    this.isRecording = false,
    this.isBusy = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool isRecording;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isBusy;
    return Semantics(
      button: true,
      label: isRecording ? 'Stop recording' : 'Capture photo',
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.5,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 78,
            height: 78,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isRecording ? Colors.redAccent : Colors.white,
                shape: BoxShape.circle,
              ),
              child: isBusy
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
