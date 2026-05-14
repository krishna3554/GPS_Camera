import 'dart:math' as math;

import 'package:image/image.dart' as img;

class ImageUtils {
  const ImageUtils._();

  static void fillRoundedRect(
    img.Image image, {
    required int x,
    required int y,
    required int width,
    required int height,
    required int radius,
    required img.Color color,
  }) {
    final safeRadius = math.min(radius, math.min(width, height) ~/ 2);
    img.fillRect(
      image,
      x1: x + safeRadius,
      y1: y,
      x2: x + width - safeRadius,
      y2: y + height,
      color: color,
    );
    img.fillRect(
      image,
      x1: x,
      y1: y + safeRadius,
      x2: x + width,
      y2: y + height - safeRadius,
      color: color,
    );
    img.fillCircle(image, x: x + safeRadius, y: y + safeRadius, radius: safeRadius, color: color);
    img.fillCircle(image, x: x + width - safeRadius, y: y + safeRadius, radius: safeRadius, color: color);
    img.fillCircle(image, x: x + safeRadius, y: y + height - safeRadius, radius: safeRadius, color: color);
    img.fillCircle(image, x: x + width - safeRadius, y: y + height - safeRadius, radius: safeRadius, color: color);
  }

  static void drawWrappedText(
    img.Image image,
    String text, {
    required img.BitmapFont font,
    required int x,
    required int y,
    required int maxWidth,
    required img.Color color,
    int maxLines = 2,
  }) {
    final words = text.trim().split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';

    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';
      if (_estimateTextWidth(candidate, font) <= maxWidth) {
        current = candidate;
      } else {
        if (current.isNotEmpty) lines.add(current);
        current = word;
      }
      if (lines.length == maxLines) break;
    }
    if (current.isNotEmpty && lines.length < maxLines) lines.add(current);

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (i == maxLines - 1 && words.join(' ').length > lines.join(' ').length) {
        line = _ellipsize(line, font, maxWidth);
      }
      img.drawString(
        image,
        line,
        font: font,
        x: x,
        y: y + (i * font.lineHeight),
        color: color,
      );
    }
  }

  static int _estimateTextWidth(String value, img.BitmapFont font) {
    return (value.length * font.lineHeight * 0.56).round();
  }

  static String _ellipsize(String value, img.BitmapFont font, int maxWidth) {
    var output = value;
    while (output.isNotEmpty && _estimateTextWidth('$output...', font) > maxWidth) {
      output = output.substring(0, output.length - 1).trimRight();
    }
    return output.isEmpty ? '...' : '$output...';
  }
}
