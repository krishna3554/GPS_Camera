import 'dart:io';
import 'dart:math' as math;
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
    final int mapSize = (panelHeight * 0.72).round().clamp(70, 140);
    final int rightPadding = (image.width * 0.03).round();
    final int mapLeft = image.width - mapSize - rightPadding;
    final int mapTop = panelTop + ((panelHeight - mapSize) ~/ 2);

    await _drawMapThumbnail(
      image: image,
      left: mapLeft,
      top: mapTop,
      size: mapSize,
      location: location,
    );

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

  Future<void> _drawMapThumbnail({
    required img.Image image,
    required int left,
    required int top,
    required int size,
    required LocationData location,
  }) async {
    final img.Color borderColor = img.ColorRgba8(255, 255, 255, 230);
    final img.Color fallbackColor = img.ColorRgba8(55, 55, 55, 255);

    img.fillRect(
      image,
      x1: left,
      y1: top,
      x2: left + size,
      y2: top + size,
      color: fallbackColor,
    );

    try {
      final img.Image? tile = await _downloadMapTile(location.latitude, location.longitude);
      if (tile != null) {
        final img.Image resized = img.copyResize(
          tile,
          width: size,
          height: size,
          interpolation: img.Interpolation.cubic,
        );
        img.compositeImage(image, resized, dstX: left, dstY: top);
      }
    } catch (_) {
      // Keep fallback tile color when map download fails.
    }

    final int pinRadius = (size * 0.1).round().clamp(6, 12);
    final int pinCenterX = left + (size ~/ 2);
    final int pinCenterY = top + (size ~/ 2);
    img.fillCircle(
      image,
      x: pinCenterX,
      y: pinCenterY,
      radius: pinRadius,
      color: img.ColorRgba8(230, 25, 25, 255),
    );
    img.fillCircle(
      image,
      x: pinCenterX,
      y: pinCenterY,
      radius: (pinRadius * 0.45).round(),
      color: img.ColorRgba8(255, 255, 255, 220),
    );

    // Border on top.
    img.drawRect(
      image,
      x1: left,
      y1: top,
      x2: left + size,
      y2: top + size,
      color: borderColor,
    );
  }

  Future<img.Image?> _downloadMapTile(double latitude, double longitude) async {
    const int zoom = 15;
    final int x = _tileX(longitude, zoom);
    final int y = _tileY(latitude, zoom);
    final Uri uri = Uri.https('tile.openstreetmap.org', '/$zoom/$x/$y.png');

    final HttpClient client = HttpClient();
    client.userAgent = 'GPSCameraFlutter/1.0';
    try {
      final HttpClientRequest request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'image/png');
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }
      final Uint8List body = await consolidateHttpClientResponseBytes(response);
      return img.decodePng(body);
    } finally {
      client.close(force: true);
    }
  }

  int _tileX(double longitude, int z) {
    final double normalizedLng = ((longitude + 180) % 360 + 360) % 360 - 180;
    final double value = (normalizedLng + 180.0) / 360.0 * (1 << z);
    return value.floor();
  }

  int _tileY(double latitude, int z) {
    final double clippedLat = latitude.clamp(-85.05112878, 85.05112878);
    final double latRad = clippedLat * math.pi / 180.0;
    final double value =
        (1.0 - math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi) /
        2.0 *
        (1 << z);
    return value.floor();
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

Future<Uint8List> consolidateHttpClientResponseBytes(HttpClientResponse response) async {
  final BytesBuilder builder = BytesBuilder(copy: false);
  await for (final List<int> chunk in response) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}
