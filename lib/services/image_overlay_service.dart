import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/geo_photo_model.dart';
import '../utils/image_utils.dart';

/// Composites the static map, metadata card, and watermark directly into pixels.
class ImageOverlayService {
  const ImageOverlayService();

  Future<GeoTaggedImageResult> composeGeoTaggedImage({
    required String capturedImagePath,
    required GeoPhotoModel geoPhoto,
    Uint8List? mapThumbnailBytes,
    String appName = 'GPS Map Camera',
  }) async {
    final sourceFile = File(capturedImagePath);
    final sourceBytes = await sourceFile.readAsBytes();
    final image = img.decodeImage(sourceBytes);
    if (image == null) {
      throw StateError('Unable to decode captured photo.');
    }

    final normalized = img.bakeOrientation(image);
    img.Image? mapImage;
    if (mapThumbnailBytes != null) {
      mapImage = img.decodeImage(mapThumbnailBytes);
    }

    _drawWatermark(normalized, appName);
    _drawOverlayCard(normalized, geoPhoto, mapImage);

    final outputBytes = Uint8List.fromList(img.encodeJpg(normalized, quality: 95));
    final directory = await getTemporaryDirectory();
    final name = 'geo_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outputFile = File(p.join(directory.path, name));
    await outputFile.writeAsBytes(outputBytes, flush: true);

    return GeoTaggedImageResult(
      filePath: outputFile.path,
      bytes: outputBytes,
      originalFilePath: capturedImagePath,
    );
  }

  void _drawOverlayCard(
    img.Image image,
    GeoPhotoModel geoPhoto,
    img.Image? mapImage,
  ) {
    final width = image.width;
    final height = image.height;
    final margin = (width * 0.045).round().clamp(28, 96);
    final cardWidth = width - (margin * 2);
    final cardHeight = (height * 0.23).round().clamp(310, 620);
    final cardTop = height - cardHeight - (height * 0.035).round();
    final radius = (cardHeight * 0.08).round().clamp(20, 44);

    ImageUtils.fillRoundedRect(
      image,
      x: margin,
      y: cardTop,
      width: cardWidth,
      height: cardHeight,
      radius: radius,
      color: img.ColorRgba8(0, 0, 0, 178),
    );

    final inner = (cardHeight * 0.08).round().clamp(18, 44);
    final mapWidth = (cardWidth * 0.32).round().clamp(220, 520);
    final mapHeight = cardHeight - (inner * 2);
    final mapLeft = margin + inner;
    final mapTop = cardTop + inner;

    _drawMapPreview(
      image,
      mapImage,
      x: mapLeft,
      y: mapTop,
      width: mapWidth,
      height: mapHeight,
    );

    final textLeft = mapLeft + mapWidth + inner;
    final textTop = mapTop + (mapHeight * 0.03).round();
    final textWidth = margin + cardWidth - inner - textLeft;
    final titleFont = width >= 2200 ? img.arial48 : img.arial24;
    final bodyFont = width >= 2200 ? img.arial24 : img.arial14;
    final titleColor = img.ColorRgb8(255, 255, 255);
    final bodyColor = img.ColorRgb8(235, 238, 242);
    final mutedColor = img.ColorRgb8(210, 215, 222);
    final accentColor = img.ColorRgb8(255, 204, 0);
    final lineHeight = (cardHeight * 0.13).round().clamp(28, 62);

    var cursorY = textTop;
    ImageUtils.drawWrappedText(
      image,
      geoPhoto.shortTitle,
      font: titleFont,
      x: textLeft,
      y: cursorY,
      maxWidth: textWidth,
      color: titleColor,
      maxLines: 1,
    );
    cursorY += lineHeight;

    ImageUtils.drawWrappedText(
      image,
      geoPhoto.address,
      font: bodyFont,
      x: textLeft,
      y: cursorY,
      maxWidth: textWidth,
      color: bodyColor,
      maxLines: 2,
    );
    cursorY += lineHeight * 2;

    img.drawString(
      image,
      'Lat ${geoPhoto.formattedLatitude}°   Long ${geoPhoto.formattedLongitude}°',
      font: bodyFont,
      x: textLeft,
      y: cursorY,
      color: bodyColor,
    );
    cursorY += lineHeight;

    img.drawString(
      image,
      geoPhoto.formattedDateTime,
      font: bodyFont,
      x: textLeft,
      y: cursorY,
      color: bodyColor,
    );
    cursorY += lineHeight;

    ImageUtils.drawWrappedText(
      image,
      'Note: ${geoPhoto.note}',
      font: bodyFont,
      x: textLeft,
      y: cursorY,
      maxWidth: textWidth,
      color: mutedColor,
      maxLines: 1,
    );

    final footerY = cardTop + cardHeight - inner - bodyFont.lineHeight;
    _drawFooterMetric(image, 'W', geoPhoto.weatherLabel, textLeft, footerY, accentColor, bodyColor, bodyFont);
    _drawFooterMetric(image, 'C', geoPhoto.headingLabel, textLeft + (textWidth * 0.25).round(), footerY, img.ColorRgb8(130, 220, 255), bodyColor, bodyFont);
    _drawFooterMetric(image, 'S', geoPhoto.speedLabel, textLeft + (textWidth * 0.50).round(), footerY, img.ColorRgb8(0, 210, 255), bodyColor, bodyFont);
    _drawFooterMetric(image, 'A', geoPhoto.altitudeLabel, textLeft + (textWidth * 0.75).round(), footerY, img.ColorRgb8(255, 160, 80), bodyColor, bodyFont);
  }

  void _drawMapPreview(
    img.Image image,
    img.Image? mapImage, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    final radius = (height * 0.08).round().clamp(14, 32);
    ImageUtils.fillRoundedRect(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
      radius: radius,
      color: img.ColorRgb8(38, 48, 56),
    );

    if (mapImage == null) {
      ImageUtils.drawWrappedText(
        image,
        'Google map preview unavailable',
        font: img.arial24,
        x: x + 22,
        y: y + (height ~/ 2) - 20,
        maxWidth: width - 44,
        color: img.ColorRgb8(255, 255, 255),
        maxLines: 2,
      );
    } else {
      final resized = img.copyResizeCropSquare(mapImage, size: math.min(width, height));
      final fitted = img.copyResize(resized, width: width, height: height);
      img.compositeImage(image, fitted, dstX: x, dstY: y);
    }

    img.drawRect(
      image,
      x1: x,
      y1: y,
      x2: x + width,
      y2: y + height,
      color: img.ColorRgba8(255, 255, 255, 80),
      thickness: 3,
    );
    img.drawString(
      image,
      'Google',
      font: width > 360 ? img.arial48 : img.arial24,
      x: x + 24,
      y: y + height - 64,
      color: img.ColorRgb8(255, 255, 255),
    );
  }

  void _drawWatermark(img.Image image, String appName) {
    final width = image.width;
    final height = image.height;
    final font = width >= 2200 ? img.arial24 : img.arial14;
    final label = appName;
    final boxWidth = (width * 0.31).round().clamp(300, 700);
    final boxHeight = (height * 0.045).round().clamp(54, 100);
    final x = width - boxWidth - (width * 0.05).round();
    final y = height - (height * 0.32).round();

    ImageUtils.fillRoundedRect(
      image,
      x: x,
      y: y,
      width: boxWidth,
      height: boxHeight,
      radius: boxHeight ~/ 2,
      color: img.ColorRgba8(0, 0, 0, 145),
    );
    img.fillCircle(
      image,
      x: x + (boxHeight ~/ 2),
      y: y + (boxHeight ~/ 2),
      radius: (boxHeight * 0.28).round(),
      color: img.ColorRgb8(255, 204, 0),
    );
    img.drawString(
      image,
      'G',
      font: font,
      x: x + (boxHeight * 0.28).round(),
      y: y + (boxHeight * 0.18).round(),
      color: img.ColorRgb8(30, 120, 255),
    );
    img.drawString(
      image,
      label,
      font: font,
      x: x + boxHeight,
      y: y + ((boxHeight - font.lineHeight) ~/ 2),
      color: img.ColorRgb8(255, 255, 255),
    );
  }

  void _drawFooterMetric(
    img.Image image,
    String icon,
    String label,
    int x,
    int y,
    img.Color iconColor,
    img.Color textColor,
    img.BitmapFont font,
  ) {
    img.drawString(image, icon, font: font, x: x, y: y, color: iconColor);
    img.drawString(image, label, font: font, x: x + (font.lineHeight * 1.3).round(), y: y, color: textColor);
  }
}

class GeoTaggedImageResult {
  const GeoTaggedImageResult({
    required this.filePath,
    required this.bytes,
    required this.originalFilePath,
  });

  final String filePath;
  final Uint8List bytes;
  final String originalFilePath;
}
