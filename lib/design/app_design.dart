import 'package:flutter/material.dart';

/// 여행 테마 디자인 시스템
class AppDesign {
  // =============================================================
  // 1. 색상 팔레트
  // =============================================================

  // 배경색
  static const Color primaryBg = Color(0xFFF8FAFC);
  static const Color secondaryBg = Color(0xFFF1F5F9);
  static const Color cardBg = Colors.white;
  static const Color bg = Color(0xFFF2F2F7);

  // 브랜드 컬러
  static const Color primary = Color(0xFF4F46E5);       // 인디고 (메인)
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color travelBlue = Color(0xFF3B82F6);
  static const Color travelGreen = Color(0xFF10B981);
  static const Color travelOrange = Color(0xFFF59E0B);
  static const Color travelPurple = Color(0xFF8B5CF6);

  // 그라데이션용
  static const Color sunsetGradientStart = Color(0xFFFF6B6B);
  static const Color sunsetGradientEnd = Color(0xFFFFE066);

  // 텍스트 컬러
  static const Color primaryText = Color(0xFF1E293B);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color subtleText = Color(0xFF94A3B8);
  static const Color whiteText = Colors.white;

  // 기타 컬러
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color success = Color(0xFF34C759);
  static const Color label1 = Color(0xFF1C1C1E);
  static const Color label2 = Color(0xFF3C3C43);
  static const Color label3 = Color(0xFF8E8E93);
  static const Color separator = Color(0xFFE5E5EA);

  // =============================================================
  // 2. Radius (모서리 둥글기)
  // =============================================================
  static const Radius r12 = Radius.circular(12);
  static const Radius r14 = Radius.circular(14);
  static const Radius r16 = Radius.circular(16);
  static const Radius r40 = Radius.circular(40);

  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;
  static const double radiusXL = 32;

  // =============================================================
  // 3. 간격 (Spacing)
  // =============================================================
  static const double spacing4 = 4;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing10 = 10;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing80 = 80;

  // =============================================================
  // 4. 텍스트 스타일
  // =============================================================

  static const TextStyle headingXL = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: primaryText,
    letterSpacing: -1.0,
    height: 1.2,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: primaryText,
    letterSpacing: -0.8,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: primaryText,
    letterSpacing: -0.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryText,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: secondaryText,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryText,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: subtleText,
    height: 1.4,
  );

  // 자주 쓰이는 스타일 (getter로 편의 제공)
  static TextStyle get title22 => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.25,
  );

  static TextStyle get body15 => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: label1,
  );

  static TextStyle get caption11 => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: label3,
    letterSpacing: 0.3,
  );

  // =============================================================
  // 5. 그림자 (Shadow)
  // =============================================================
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 4),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 32,
      offset: const Offset(0, 8),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> glowShadow = [
    BoxShadow(
      color: travelBlue.withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -8,
    ),
  ];

  // =============================================================
  // 6. 그라디언트
  // =============================================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [travelBlue, travelPurple],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunsetGradientStart, sunsetGradientEnd],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [travelGreen, Color(0xFF059669)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBg, secondaryBg],
    stops: [0.0, 1.0],
  );
}