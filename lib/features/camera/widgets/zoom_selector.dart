import 'package:flutter/material.dart';

class ZoomSelector extends StatelessWidget {
  const ZoomSelector({
    required this.value,
    required this.onChanged,
    this.options = const [1, 2, 3],
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final List<double> options;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((zoom) {
            final selected = (value - zoom).abs() < 0.15;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ChoiceChip(
                label: Text('${zoom.toStringAsFixed(zoom % 1 == 0 ? 0 : 1)}x'),
                selected: selected,
                onSelected: (_) => onChanged(zoom),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
