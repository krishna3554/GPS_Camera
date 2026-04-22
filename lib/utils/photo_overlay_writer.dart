import 'dart:io';
import 'dart:typed_data';

import 'package:gps_camera/models/location_data.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class PhotoOverlayWriter {
  Future<void> stamp({
    required String imagePath,
    required LocationData location,
    String? address,
    String? city,
    String? country,
  }) async {
    final File source = File(imagePath);
    final Uint8List bytes = await source.readAsBytes();
    final img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw StateError('Unable to decode captured photo.');
    }

    final int panelHeight = (image.height * 0.23).round().clamp(130, 300);
    final int panelTop = image.height - panelHeight;
    final img.Color panelColor = img.ColorRgba8(0, 0, 0, 165);

    img.fillRect(
      image,
      x1: 0,
      y1: panelTop,
      x2: image.width,
      y2: image.height,
      color: panelColor,
    );

    final String placeTitle = _title(city: city, country: country);
    final String placeAddress = (address ?? '').trim();
    final String coords =
        'Lat ${location.latitude.toStringAsFixed(5)}, Lng ${location.longitude.toStringAsFixed(5)}';
    final String altitude = location.altitude == null
        ? 'Alt --'
        : 'Alt ${location.altitude!.toStringAsFixed(1)} m';
    final String heading = location.heading == null
        ? 'Heading --'
        : 'Heading ${location.heading!.toStringAsFixed(0)}°';
    final String speed = location.speed == null
        ? 'Speed --'
        : 'Speed ${(location.speed! * 3.6).toStringAsFixed(1)} km/h';
    final String timestamp =
        DateFormat('EEE, dd MMM yyyy HH:mm:ss').format(location.timestamp.toLocal());

    final int left = (image.width * 0.03).round();
    final int top = panelTop + (panelHeight * 0.08).round();
    final int lineGap = (panelHeight * 0.17).round().clamp(18, 36);

    img.drawString(
      image,
      placeTitle,
      font: img.arial24,
      x: left,
      y: top,
      color: img.ColorRgb8(255, 255, 255),
    );
    img.drawString(
      image,
      placeAddress.isEmpty ? 'Address unavailable' : placeAddress,
      font: img.arial14,
      x: left,
      y: top + lineGap,
      color: img.ColorRgb8(235, 235, 235),
    );
    img.drawString(
      image,
      coords,
      font: img.arial14,
      x: left,
      y: top + (lineGap * 2),
      color: img.ColorRgb8(235, 235, 235),
    );
    img.drawString(
      image,
      '$timestamp   •   $speed   •   $heading   •   $altitude',
      font: img.arial14,
      x: left,
      y: top + (lineGap * 3),
      color: img.ColorRgb8(220, 220, 220),
    );

    await source.writeAsBytes(img.encodeJpg(image, quality: 92), flush: true);
  }

  String _title({String? city, String? country}) {
    final String c = (city ?? '').trim();
    final String n = (country ?? '').trim();
    if (c.isNotEmpty && n.isNotEmpty) {
      return '$c, $n';
    }
    if (c.isNotEmpty) {
      return c;
    }
    if (n.isNotEmpty) {
      return n;
    }
    return 'GPS Camera';
  }
}
