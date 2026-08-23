import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 여행 테마 디자인 시스템
class AppDesign {
  // =============================================================
  // 1. 색상 팔레트
  // =============================================================

  // 배경색
  static const Color primaryBg = Color(0xFFF7F8F5);
  static const Color secondaryBg = Color(0xFFEDF1EC);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF1F3EF);

  // 브랜드 컬러인
  static const Color primary = Color(0xFF3D7357);
  static const Color primaryDark = Color(0xFF28513D);
  static const Color travelBlue = Color(0xFF4E7D8A);
  static const Color travelGreen = Color(0xFF5C896D);
  static const Color travelOrange = Color(0xFFA9784D);
  static const Color travelPurple = Color(0xFF7B728B);

  // 커뮤니티/저널 포인트 컬러 — 우표(postmark) 모티프에서 가져온 테라코타 톤.
  // 이 색은 "여행 이야기" 게시판에서만 제한적으로 사용해 포인트로 유지합니다.
  static const Color travelStamp = Color(0xFFB66B57);

  // 그라데이션용
  static const Color sunsetGradientStart = Color(0xFF9C7656);
  static const Color sunsetGradientEnd = Color(0xFFD5C3A4);

  // 텍스트 컬러
  static const Color primaryText = Color(0xFF17251E);
  static const Color secondaryText = Color(0xFF5F7167);
  static const Color subtleText = Color(0xFF87968E);
  static const Color whiteText = Colors.white;

  // 기타 컬러
  static const Color borderColor = Color(0xFFDCE4DD);
  static const Color lightGray = Color(0xFFF4F6F3);
  static const Color success = Color(0xFF4F8B68);
  static const Color label1 = Color(0xFF17251E);
  static const Color label2 = Color(0xFF3D5046);
  static const Color label3 = Color(0xFF819087);
  static const Color separator = Color(0xFFE2E8E2);

  // 홈 목업 전용 팔레트 — 화면에서 임의의 색상을 만들지 않고 이 토큰만 사용합니다.
  static const Color homeBackgroundTop = Color(0xFF102019);
  static const Color homeBackgroundBottom = Color(0xFF19382A);
  static const Color homeSurface = Color(0xFF1E3A2D);
  static const Color homeSurfaceBorder = Color(0xFF416755);
  static const Color homeForeground = Color(0xFFF1F6F2);
  static const Color homeEyebrow = Color(0xFFB5CABD);
  static const Color homeMutedText = Color(0xFFA9BFB1);
  static const Color homeNavigationText = Color(0xFF90AA9A);
  static const Color homeMutedSurface = Color(0xFF315844);
  static const Color homeTagSurface = Color(0xFF315844);
  static const Color homeTagForeground = Color(0xFFC1EDD0);
  static const Color homeHeroStart = Color(0xFF356B51);
  static const Color homeHeroEnd = Color(0xFF688D76);
  static const Color homeMapIconStart = Color(0xFF5F929A);
  static const Color homeMapIconEnd = Color(0xFF6E9EA3);
  static const Color homeListIconStart = Color(0xFF4D8969);
  static const Color homeListIconEnd = Color(0xFF397257);
  static const Color homeLinkIconStart = Color(0xFF866B50);
  static const Color homeLinkIconEnd = Color(0xFFA88461);
  static const Color homeRestaurantTagSurface = Color(0xFF503B30);
  static const Color homeRestaurantTagForeground = Color(0xFFF0C3A2);
  static const Color homePhotoTagSurface = Color(0xFF304C5A);
  static const Color homePhotoTagForeground = Color(0xFFA8D9E9);
  static const Color homeCafeTagSurface = Color(0xFF4B4330);
  static const Color homeCafeTagForeground = Color(0xFFE8D092);
  static const Color homeHotelTagSurface = Color(0xFF3E3D58);
  static const Color homeHotelTagForeground = Color(0xFFCBC8ED);
  static const Color homeExhibitionTagSurface = Color(0xFF344B41);
  static const Color homeExhibitionTagForeground = Color(0xFFB9DCC8);

  // =============================================================
  // 2. Radius (모서리 둥글기)
  // =============================================================
  static const Radius r12 = Radius.circular(14);
  static const Radius r14 = Radius.circular(16);
  static const Radius r16 = Radius.circular(18);
  static const Radius r40 = Radius.circular(40);

  static const double radiusSmall = 14;
  static const double radiusMedium = 18;
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
  static const double spacing48 = 48;
  static const double spacing80 = 80;

  // =============================================================
  // 4. 텍스트 스타일
  // =============================================================

  static const TextStyle headingXL = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: primaryText,
    letterSpacing: -1.0,
    height: 1.2,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
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

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: secondaryText,
    height: 1.4,
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

  // ---- 저널 스타일 (커뮤니티 게시판 등 스토리텔링 콘텐츠 전용) ----
  // 오버라인 라벨 ("TRAVEL JOURNAL" 등 화면 상단 소제목용)
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: subtleText,
    letterSpacing: 1.4,
  );

  // 화면 타이틀급 세리프 스타일. 한글 지원을 위해 Noto Serif KR 사용.
  static TextStyle get journalTitle => GoogleFonts.notoSerifKr(
        fontSize: 22,
        color: primaryText,
        fontWeight: FontWeight.w500,
      );

  // 게시글 제목 등 카드 내부용 세리프 스타일
  static TextStyle get journalTitleSmall => GoogleFonts.notoSerifKr(
        fontSize: 16,
        color: primaryText,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // =============================================================
  // 5. 그림자 (Shadow)
  // =============================================================
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF1B382A).withValues(alpha: 0.08),
      blurRadius: 18,
      offset: const Offset(0, 6),
      spreadRadius: -8,
    ),
  ];

  static final List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: const Color(0xFF1B382A).withValues(alpha: 0.12),
      blurRadius: 26,
      offset: const Offset(0, 10),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: const Color(0xFF1B382A).withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.16),
      blurRadius: 20,
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
    colors: [primary, travelGreen],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunsetGradientStart, sunsetGradientEnd],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [travelGreen, primaryDark],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBg, secondaryBg],
    stops: [0.0, 1.0],
  );

  /// 홈 화면 전용 배경. 카드가 흰색이어도 화면 전체는 세이지 그린으로 느껴집니다.
  static const LinearGradient homeBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [homeBackgroundTop, homeBackgroundBottom],
  );

  static const LinearGradient homeHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [homeHeroStart, homeHeroEnd],
  );

  static const Color homeActionSurface = homeMutedSurface;

  static const LinearGradient homeMapIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [homeMapIconStart, homeMapIconEnd],
  );

  static const LinearGradient homeListIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [homeListIconStart, homeListIconEnd],
  );

  static const LinearGradient homeLinkIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [homeLinkIconStart, homeLinkIconEnd],
  );

  static Color homeKeywordSurface(String keyword) {
    switch (keyword.trim()) {
      case '음식점':
        return homeRestaurantTagSurface;
      case '사진':
        return homePhotoTagSurface;
      case '카페':
        return homeCafeTagSurface;
      case '호텔':
        return homeHotelTagSurface;
      case '전시회':
        return homeExhibitionTagSurface;
      default:
        return homeTagSurface;
    }
  }

  static Color homeKeywordForeground(String keyword) {
    switch (keyword.trim()) {
      case '음식점':
        return homeRestaurantTagForeground;
      case '사진':
        return homePhotoTagForeground;
      case '카페':
        return homeCafeTagForeground;
      case '호텔':
        return homeHotelTagForeground;
      case '전시회':
        return homeExhibitionTagForeground;
      default:
        return homeTagForeground;
    }
  }

  /// Material 3 기반의 전역 테마입니다. 화면의 문구와 기능에는 영향을 주지 않고,
  /// 기본 버튼·입력창·다이얼로그 같은 공통 UI의 밀도와 색만 일관되게 맞춥니다.
  static ThemeData get lightTheme {
    return FlexThemeData.light(
      useMaterial3: true,
      colors: const FlexSchemeColor(
        primary: primary,
        primaryContainer: Color(0xFFDCE9DE),
        secondary: travelGreen,
        secondaryContainer: Color(0xFFE5EEE5),
        tertiary: travelBlue,
        tertiaryContainer: Color(0xFFDDE8E9),
        error: travelStamp,
      ),
      scaffoldBackground: primaryBg,
      subThemesData: const FlexSubThemesData(
        defaultRadius: radiusSmall,
        interactionEffects: true,
        useMaterial3Typography: true,
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme().apply(
        bodyColor: primaryText,
        displayColor: primaryText,
      ),
    ).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBg,
        foregroundColor: primaryText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primaryText,
        contentTextStyle: TextStyle(color: whiteText),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// shadcn_ui 컴포넌트가 앱 어디에서든 동일한 색과 둥글기를 사용하도록 합니다.
  static ShadThemeData get shadTheme => ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadGreenColorScheme.light(
          background: primaryBg,
          foreground: primaryText,
          card: cardBg,
          cardForeground: primaryText,
          popover: cardBg,
          popoverForeground: primaryText,
          primary: primary,
          primaryForeground: whiteText,
          secondary: secondaryBg,
          secondaryForeground: primaryText,
          muted: lightGray,
          mutedForeground: secondaryText,
          accent: Color(0xFFDCE9DE),
          accentForeground: primaryText,
          destructive: travelStamp,
          destructiveForeground: whiteText,
          border: borderColor,
          input: borderColor,
          ring: primary,
          selection: Color(0xFFCCE0D1),
        ),
        radius: BorderRadius.circular(radiusSmall),
      );
}
