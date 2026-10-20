import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerIconService {
  Future<BitmapDescriptor>? _searchPin;

  Future<BitmapDescriptor> createSearchMarker() =>
      _searchPin ??= _drawSearchMarker();

  Future<BitmapDescriptor> _drawSearchMarker() async {
    const width = 40.0;
    const height = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(3);
    final pin = Path()
      ..moveTo(20, 44)
      ..cubicTo(16, 38, 4, 28, 4, 20)
      ..cubicTo(4, 10, 11, 4, 20, 4)
      ..cubicTo(29, 4, 36, 10, 36, 20)
      ..cubicTo(36, 28, 24, 38, 20, 44)
      ..close();
    canvas.drawShadow(pin, const Color(0x55000000), 2, true);
    canvas.drawPath(
        pin,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF343434), Color(0xFF121212)],
          ).createShader(const Rect.fromLTWH(4, 4, 32, 40)));
    canvas.drawPath(
        pin,
        Paint()
          ..color = const Color(0xFF111111)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7);
    canvas.drawCircle(const Offset(20, 20), 6, Paint()..color = Colors.white);
    final picture = recorder.endRecording();
    final image = await picture.toImage(120, 144);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(),
        width: width, height: height);
  }

  Future<BitmapDescriptor> createClusterMarker(int size, String text) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(3);
    final center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      size / 2 - 2,
      Paint()..color = const Color(0xFF222222),
    );
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size / 3,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
    );
    final image = await recorder.endRecording().toImage(size * 3, size * 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(),
        width: size.toDouble(), height: size.toDouble());
  }

  Future<BitmapDescriptor> createKeywordMarker(String keyword) {
    final asset = switch (keyword.trim()) {
      '카페' => 'cafe',
      '맛집' || '음식점' => 'restaurant',
      '호텔' || '숙소' => 'hotel',
      '사진' => 'photo',
      '전시회' => 'exhibition',
      _ => 'place',
    };
    return createCustomMarkerImage(asset, 48, 52, selected: true);
  }

  Future<BitmapDescriptor> createCustomMarkerImage(
      String imagePath, int width, int height,
      {bool? selected}) async {
    final key = imagePath.toLowerCase();
    final IconData icon;
    if (key.contains('cafe')) {
      icon = Icons.local_cafe;
    } else if (key.contains('hotel')) {
      icon = Icons.hotel;
    } else if (key.contains('restaurant')) {
      icon = Icons.restaurant;
    } else if (key.contains('photo')) {
      icon = Icons.camera_alt;
    } else if (key.contains('exhibition')) {
      icon = Icons.image_outlined;
    } else {
      icon = Icons.place;
    }
    final dark = selected ?? key.contains('cafe');
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Render at 3x for crisp silhouettes on high-density mobile screens.
    canvas.scale(3);
    final pin = Path()
      ..moveTo(24, 45)
      ..cubicTo(21, 42, 19, 38, 17, 37)
      ..cubicTo(7, 34, 5, 27, 6, 20)
      ..cubicTo(7, 10, 14, 5, 24, 5)
      ..cubicTo(34, 5, 41, 12, 42, 21)
      ..cubicTo(43, 29, 38, 35, 31, 38)
      ..cubicTo(29, 40, 27, 43, 24, 45)
      ..close();
    canvas.drawShadow(pin, Colors.black.withValues(alpha: 0.32), 4, true);
    canvas.drawPath(
        pin, Paint()..color = dark ? const Color(0xFF222222) : Colors.white);
    canvas.drawPath(
        pin,
        Paint()
          ..color = const Color(0x12000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
    final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
                fontFamily: icon.fontFamily,
                package: icon.fontPackage,
                fontSize: 20,
                color: dark ? Colors.white : const Color(0xFF222222))))
      ..layout();
    painter.paint(
        canvas, Offset(24 - painter.width / 2, 23 - painter.height / 2));
    final picture = recorder.endRecording();
    final image = await picture.toImage(144, 156);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(),
        width: 48, height: 52);
  }
}
