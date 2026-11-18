import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

/// 플로팅 패널 영역에만 흐림 효과를 적용하며, 고대비 모드에서는 불투명 배경을 사용합니다.
class SoftGlassSurface extends StatelessWidget {
  const SoftGlassSurface({super.key, required this.child, this.radius = 20});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        enabled: !highContrast,
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: highContrast ? 1 : .85),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0x14202023)),
          ),
          child: child,
        ),
      ),
    );
  }
}
