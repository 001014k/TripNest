import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 점선 원형 테두리. 커뮤니티 게시판에서 "우표(postmark)" 느낌을 주기 위해
/// 마커 공유 게시글의 아바타 자리에 사용합니다.
class DashedCircleBorder extends StatelessWidget {
  const DashedCircleBorder({
    super.key,
    required this.child,
    required this.color,
    this.size = 38,
    this.strokeWidth = 1.4,
    this.dashCount = 16,
  });

  final Widget child;
  final Color color;
  final double size;
  final double strokeWidth;
  final int dashCount;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(
        color: color,
        strokeWidth: strokeWidth,
        dashCount: dashCount,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  final Color color;
  final double strokeWidth;
  final int dashCount;

  static const double _dashFraction = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final radius = (size.shortestSide - strokeWidth) / 2;
    final center = size.center(Offset.zero);
    final sweepPerDash = (2 * math.pi) / dashCount;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * sweepPerDash;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepPerDash * _dashFraction,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashCount != dashCount;
  }
}

/// 점선 필(pill) 테두리. "탑승권" 스타일 목적지 태그에 사용합니다.
/// 배경은 투명하게 두고 child에 padding/색상을 직접 지정하세요.
class DashedPillBorder extends StatelessWidget {
  const DashedPillBorder({
    super.key,
    required this.child,
    required this.color,
    this.strokeWidth = 1.2,
    this.dashWidth = 4,
    this.gapWidth = 3,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPillPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        gapWidth: gapWidth,
      ),
      child: child,
    );
  }
}

class _DashedPillPainter extends CustomPainter {
  _DashedPillPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gapWidth,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );

    final path = Path()..addRRect(rrect);
    canvas.drawPath(_dashPath(path, dashWidth, gapWidth), paint);
  }

  Path _dashPath(Path source, double dashWidth, double gapWidth) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : gapWidth;
        final end = math.min(distance + length, metric.length);
        if (draw) {
          dashedPath.addPath(metric.extractPath(distance, end), Offset.zero);
        }
        distance += length;
        draw = !draw;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant _DashedPillPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.gapWidth != gapWidth;
  }
}