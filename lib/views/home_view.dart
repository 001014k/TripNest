import 'package:flutter/material.dart';
import 'package:fluttertrip/views/shared_link_view.dart';
import 'package:provider/provider.dart';
import '../models/shared_link_model.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/marker_model.dart';

// ================================
// 개선된 디자인 시스템 - 여행 테마
// ================================
class AppDesign {
  // 생동감 있는 컬러 팔레트
  static const Color primaryBg = Color(0xFFF8FAFC);
  static const Color secondaryBg = Color(0xFFF1F5F9);
  static const Color cardBg = Colors.white;

  // 브랜드 컬러 - 여행의 설렘을 표현
  static const Color travelBlue = Color(0xFF3B82F6);
  static const Color travelGreen = Color(0xFF10B981);
  static const Color travelOrange = Color(0xFFF59E0B);
  static const Color travelPurple = Color(0xFF8B5CF6);
  static const Color sunsetGradientStart = Color(0xFFFF6B6B);
  static const Color sunsetGradientEnd = Color(0xFFFFE066);

  // 텍스트 컬러
  static const Color primaryText = Color(0xFF1E293B);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color subtleText = Color(0xFF94A3B8);
  static const Color whiteText = Color(0xFFFFFFFF);

  // 기본 컬러
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color lightGray = Color(0xFFF8FAFC);

  // 간격 시스템
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;

  // 보더 반지름 - 더 현대적인 느낌
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;
  static const double radiusXL = 32;

  // 개선된 타이포그래피
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

  // 프리미엄 그림자 효과
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

  // 그라디언트 정의
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

// ================================
// 메인 홈 대시보드 뷰
// ================================
class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView>
    with TickerProviderStateMixin {
  late HomeDashboardViewModel _viewModel;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<HomeDashboardViewModel>();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );
    _fadeAnimationController.forward();
  }

  void _initializeData() {
    _viewModel.loadRecentMarkers();
    _viewModel.loadSharedLinks();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: Consumer<HomeDashboardViewModel>(
            builder: (context, viewModel, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 개선된 헤더 섹션
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                        child: _DashboardHeader(),
                      ),
                    ),

                    // 프리미엄 웰컴 카드
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _WelcomeCard(),
                      ),
                    ),

                    // 메인 기능 그리드
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _MainFeaturesGrid(),
                      ),
                    ),

                    // 최근 마커 섹션
                    if (viewModel.recentMarkers.isNotEmpty)
                      SliverToBoxAdapter(
                        child: RecentMarkersSection(
                          markers: viewModel.recentMarkers,
                          onViewAll: () => _navigateToList(),
                        ),
                      ),

                    // 공유 링크 섹션
                    if (viewModel.sharedLinks.isNotEmpty)
                      SliverToBoxAdapter(
                        child: SharedLinksSection(
                          sharedLinks: viewModel.sharedLinks,
                          onViewAll: () => _navigateToSharedLinks(),
                        ),
                      ),

                    // 하단 여백
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppDesign.spacing40),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToList() => Navigator.pushNamed(context, '/list');
  void _navigateToSharedLinks() => Navigator.pushNamed(context, '/shared_link');
}

// ================================
// 프리미엄 대시보드 헤더
// ================================
class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppDesign.travelBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppDesign.travelBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '오늘의 여행',
                    style: AppDesign.caption.copyWith(
                      color: AppDesign.travelBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppDesign.spacing12),
                const Text('어디로 떠날까요?', style: AppDesign.headingXL),
                const SizedBox(height: AppDesign.spacing8),
                Text(
                  '새로운 모험이 당신을 기다리고 있어요 ✈️',
                  style: AppDesign.bodyLarge.copyWith(
                    color: AppDesign.secondaryText,
                  ),
                ),
              ],
            ),
            _buildProfileAvatar(),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDesign.glowShadow,
      ),
      child: const Icon(
        Icons.person_outline,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

// ================================
// 웰컴 카드 컴포넌트
// ================================
class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppDesign.spacing32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppDesign.sunsetGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppDesign.sunsetGradientStart.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '새로운 여행을\n시작해보세요',
                  style: AppDesign.headingMedium.copyWith(
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing8),
                Text(
                  '전 세계 숨겨진 보석들을 발견하고\n잊을 수 없는 추억을 만들어보세요',
                  style: AppDesign.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.explore_outlined,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================
// 메인 기능 그리드
// ================================
class _MainFeaturesGrid extends StatefulWidget {
  @override
  State<_MainFeaturesGrid> createState() => _MainFeaturesGridState();
}

class _MainFeaturesGridState extends State<_MainFeaturesGrid> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeShimmerAnimation();
  }

  void _initializeShimmerAnimation() {
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeatureGridItem(
                icon: _buildAnimatedIcon(Icons.map_outlined),
                title: '지도 탐색',
                subtitle: '새로운 장소\n발견하기',
                gradient: AppDesign.primaryGradient,
                onTap: () => Navigator.pushNamed(context, '/map'),
              ),
            ),
            const SizedBox(width: AppDesign.spacing16),
            Expanded(
              child: _FeatureGridItem(
                icon: _buildAnimatedIcon(Icons.bookmark_outline),
                title: '저장 목록',
                subtitle: '나만의\n여행 노트',
                gradient: AppDesign.greenGradient,
                onTap: () => Navigator.pushNamed(context, '/list'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesign.spacing16),
        _PremiumFriendsCard(),
      ],
    );
  }

  Widget _buildAnimatedIcon(IconData iconData) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            iconData,
            color: Colors.white,
            size: 24,
          ),
        );
      },
    );
  }
}

// ================================
// 기능 그리드 아이템
// ================================
class _FeatureGridItem extends StatefulWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _FeatureGridItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_FeatureGridItem> createState() => _FeatureGridItemState();
}

class _FeatureGridItemState extends State<_FeatureGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              boxShadow: AppDesign.elevatedShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.icon,
                ),
                const Spacer(),
                Text(
                  widget.title,
                  style: AppDesign.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing4),
                Text(
                  widget.subtitle,
                  style: AppDesign.caption.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTapUp() {
    _animationController.reverse();
    widget.onTap();
  }
}

// ================================
// 프리미엄 친구 기능 카드
// ================================
class _PremiumFriendsCard extends StatefulWidget {
  @override
  State<_PremiumFriendsCard> createState() => _PremiumFriendsCardState();
}

class _PremiumFriendsCardState extends State<_PremiumFriendsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeShimmerAnimation();
  }

  void _initializeShimmerAnimation() {
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppDesign.primaryText,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          onTap: () => Navigator.pushNamed(context, '/friends'),
          child: Row(
            children: [
              _buildAnimatedIcon(),
              const SizedBox(width: AppDesign.spacing20),
              Expanded(child: _buildTextContent()),
              _buildArrowIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.people_outline,
            color: Colors.white,
            size: 28,
          ),
        );
      },
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '친구들과 함께',
          style: AppDesign.headingSmall.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppDesign.spacing4),
        Text(
          '여행 계획을 공유하고 추억을 함께 만들어보세요',
          style: AppDesign.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildArrowIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

// ================================
// 개선된 섹션 헤더
// ================================
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onViewAll;

  const SectionHeader({
    required this.title,
    required this.icon,
    required this.onViewAll,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppDesign.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: AppDesign.spacing12),
            Text(title, style: AppDesign.headingMedium),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppDesign.primaryText,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppDesign.softShadow,
          ),
          child: InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(20),
            child: Text(
              '전체 보기',
              style: AppDesign.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================
// 프리미엄 최근 마커 섹션
// ================================
class RecentMarkersSection extends StatefulWidget {
  final List<MarkerModel> markers;
  final VoidCallback onViewAll;

  const RecentMarkersSection({
    required this.markers,
    required this.onViewAll,
    super.key,
  });

  @override
  State<RecentMarkersSection> createState() => _RecentMarkersSectionState();
}

class _RecentMarkersSectionState extends State<RecentMarkersSection> {
  final Map<String, LinkPreviewData?> _previewDataCache = {};
  final Set<String> _loadingUrls = {};

  @override
  void initState() {
    super.initState();
    _loadPreviewData();
  }

  Future<void> _loadPreviewData() async {
    for (final marker in widget.markers) {
      await _fetchPreviewForMarker(marker);
    }
  }

  Future<void> _fetchPreviewForMarker(MarkerModel marker) async {
    final url = marker.address;
    if (url.isEmpty || _previewDataCache.containsKey(url) || _loadingUrls.contains(url)) {
      return;
    }

    _loadingUrls.add(url);

    try {
      final previewData = await getPreviewData(url);
      if (mounted) {
        setState(() {
          _previewDataCache[url] = previewData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewDataCache[url] = null;
        });
      }
    } finally {
      _loadingUrls.remove(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SectionHeader(
            icon: Icons.location_on,
            title: '최근 저장한 장소',
            onViewAll: _handleViewAll,  // 내부 함수 연결
          ),
        ),
        const SizedBox(height: AppDesign.spacing20),
        _buildMarkersList(),
        const SizedBox(height: AppDesign.spacing40),
      ],
    );
  }

// 섹션 내부에 onViewAll 전용 핸들러 추가
  void _handleViewAll() {
    if (widget.onViewAll != null) {
      widget.onViewAll!(); // 외부 콜백 있으면 실행
    } else {
      Navigator.pushNamed(context, '/list'); // 기본 동작 (전체 보기 페이지 이동)
    }
  }

  Widget _buildMarkersList() {
    return SizedBox(
      height: 270,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: widget.markers.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDesign.spacing16),
        itemBuilder: (context, index) => _buildPremiumMarkerCard(widget.markers[index]),
      ),
    );
  }

  Widget _buildPremiumMarkerCard(MarkerModel marker) {
    final previewData = _previewDataCache[marker.address];

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          onTap: () => _navigateToMarkerDetail(marker),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumMarkerImage(),
                const SizedBox(height: AppDesign.spacing16),
                _buildMarkerTitle(marker, previewData),
                const SizedBox(height: AppDesign.spacing8),
                _buildMarkerDescription(marker, previewData),
                const Spacer(),
                _buildMarkerFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumMarkerImage() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
      ),
      child: const Center(
        child: Icon(
          Icons.place,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildMarkerTitle(MarkerModel marker, LinkPreviewData? previewData) {
    return Text(
      previewData?.title ?? marker.title,
      style: AppDesign.headingSmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMarkerDescription(MarkerModel marker, LinkPreviewData? previewData) {
    return Text(
      previewData?.description ?? marker.address,
      style: AppDesign.bodyMedium.copyWith(color: AppDesign.secondaryText),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMarkerFooter() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppDesign.travelBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '저장됨',
            style: AppDesign.caption.copyWith(
              color: AppDesign.travelBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppDesign.subtleText,
        ),
      ],
    );
  }

  void _navigateToMarkerDetail(MarkerModel marker) {
    Navigator.pushNamed(
      context,
      '/user_list',
      arguments: marker.id,
    );
  }
}

// ================================
// 프리미엄 공유 링크 섹션
// ================================
class SharedLinksSection extends StatefulWidget {
  final List<SharedLinkModel> sharedLinks;
  final VoidCallback? onViewAll;

  const SharedLinksSection({
    required this.sharedLinks,
    this.onViewAll,
    Key? key,
  }) : super(key: key);

  @override
  State<SharedLinksSection> createState() => _SharedLinksSectionState();
}

class _SharedLinksSectionState extends State<SharedLinksSection> with TickerProviderStateMixin {
  final Map<String, LinkPreviewData> _previewDataCache = {};
  bool _isLoading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _loadAllPreviewData();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadAllPreviewData() async {
    await Future.wait(
      widget.sharedLinks.map((link) => _loadPreviewForLink(link)),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _pulseController.stop();
    }
  }

  Future<void> _loadPreviewForLink(SharedLinkModel link) async {
    try {
      final preview = await getPreviewData(link.url);
      _previewDataCache[link.url] = preview;
    } catch (e) {
      _previewDataCache[link.url] = LinkPreviewData(
        title: link.platform,
        description: '',
        image: null,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sharedLinks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: AppDesign.spacing20),
        _isLoading ? _buildPremiumLoadingState() : _buildLinksList(),
        const SizedBox(height: AppDesign.spacing40),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SectionHeader(
        title: '공유된 링크',
        icon: Icons.share,
        onViewAll: _handleViewAll,
      ),
    );
  }

// 내부 핸들러 함수 추가
  void _handleViewAll() {
    if (widget.onViewAll != null) {
      widget.onViewAll!();  // 외부에서 콜백이 전달됐으면 실행
    } else {
      _navigateToSharedLinks();  // 기본 동작 실행
    }
  }

  Widget _buildPremiumLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnimation.value,
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppDesign.cardBg,
                    AppDesign.lightGray,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
                boxShadow: AppDesign.softShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppDesign.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.cloud_download,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: AppDesign.spacing16),
                  Text(
                    '링크 정보를 불러오는 중...',
                    style: AppDesign.bodyMedium.copyWith(
                      color: AppDesign.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLinksList() {
    return SizedBox(
      height: 290,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: widget.sharedLinks.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDesign.spacing16),
        itemBuilder: (context, index) => _buildPremiumLinkCard(widget.sharedLinks[index]),
      ),
    );
  }

  Widget _buildPremiumLinkCard(SharedLinkModel link) {
    final previewData = _previewDataCache[link.url];
    final subtitle = _getClippedSubtitle(previewData, link);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
        border: Border.all(
          color: AppDesign.borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          onTap: () => _navigateToLinkDetail(link),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLinkImage(previewData),
                const SizedBox(height: AppDesign.spacing16),
                _buildLinkTitle(previewData, link),
                const SizedBox(height: AppDesign.spacing8),
                _buildLinkDescription(subtitle),
                const Spacer(),
                _buildLinkFooter(link),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkImage(LinkPreviewData? previewData) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: previewData?.image != null
            ? null
            : AppDesign.sunsetGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        image: previewData?.image != null
            ? DecorationImage(
          image: NetworkImage(previewData!.image!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: previewData?.image == null
          ? const Center(
        child: Icon(
          Icons.link,
          color: Colors.white,
          size: 40,
        ),
      )
          : null,
    );
  }

  Widget _buildLinkTitle(LinkPreviewData? previewData, SharedLinkModel link) {
    return Text(
      previewData?.title ?? link.platform,
      style: AppDesign.headingSmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLinkDescription(String subtitle) {
    return Text(
      subtitle,
      style: AppDesign.bodyMedium.copyWith(color: AppDesign.secondaryText),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLinkFooter(SharedLinkModel link) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppDesign.travelOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            link.platform,
            style: AppDesign.caption.copyWith(
              color: AppDesign.travelOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppDesign.lightGray,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.open_in_new,
            size: 14,
            color: AppDesign.subtleText,
          ),
        ),
      ],
    );
  }

  String _getClippedSubtitle(LinkPreviewData? previewData, SharedLinkModel link) {
    final subtitleText = previewData?.description ?? link.url;
    return subtitleText.length > 80
        ? '${subtitleText.substring(0, 77)}...'
        : subtitleText;
  }

  void _navigateToSharedLinks() {
    Navigator.pushNamed(context, '/shared_link');
  }

  void _navigateToLinkDetail(SharedLinkModel link) {
    Navigator.pushNamed(
      context,
      '/shared_link_detail',
      arguments: link.id,
    );
  }
}

// ================================
// 고급 기능 카드 컴포넌트
// ================================
class FeatureCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final BorderRadiusGeometry borderRadius;
  final VoidCallback? onTap;

  const FeatureCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.gradient,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.onTap,
    super.key,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _shadowAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.gradient == null ? (widget.color ?? AppDesign.cardBg) : null,
                gradient: widget.gradient,
                borderRadius: widget.borderRadius,
                boxShadow: AppDesign.softShadow.map((shadow) {
                  return shadow.copyWith(
                    blurRadius: shadow.blurRadius * _shadowAnimation.value,
                    color: shadow.color.withOpacity(
                      shadow.color.opacity * _shadowAnimation.value,
                    ),
                  );
                }).toList(),
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }
}