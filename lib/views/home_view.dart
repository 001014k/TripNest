import 'package:flutter/material.dart';
import 'package:fluttertrip/views/shared_link_view.dart';
import 'package:fluttertrip/views/widgets/address_photo_preview.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shared_link_model.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/marker_model.dart';
import '../design/app_design.dart';
import 'markerdetail_view.dart';

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
                        child: _DashboardHeader(
                          userId: Supabase.instance.client.auth.currentUser?.id ?? '',
                        ),
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

                    // 최근 마커 섹션 (항상 표시)
                    SliverToBoxAdapter(
                      child: RecentMarkersSection(
                        markers: viewModel.recentMarkers,
                        onViewAll: () => _navigateToList(),
                      ),
                    ),

                    // 공유 링크 섹션 (항상 표시)
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

  void _navigateToList() => Navigator.pushNamed(context, '/marker_list');
  void _navigateToSharedLinks() => Navigator.pushNamed(context, '/shared_link');
}

// ================================
// 프리미엄 대시보드 헤더
// ================================
class _DashboardHeader extends StatelessWidget {
  final String userId;

  const _DashboardHeader({required this.userId});

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
            _buildProfileAvatar(context),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: userId,
        );
      },
      child: Container(
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
          onTap: () => Navigator.pushNamed(context, '/friend_management'),
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
// 프리미엄 최근 마커 섹션 (항상 표시)
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
    if (widget.markers.isNotEmpty) {
      _loadPreviewData();
    }
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
            onViewAll: _handleViewAll,
          ),
        ),
        const SizedBox(height: AppDesign.spacing20),
        _buildMarkersList(),
        const SizedBox(height: AppDesign.spacing40),
      ],
    );
  }

  void _handleViewAll() {
    widget.onViewAll();
  }

  Widget _buildMarkersList() {
    if (widget.markers.isEmpty) {
      return _buildEmptyMarkersState();
    }

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

  Widget _buildEmptyMarkersState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 270,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDesign.cardBg,
              AppDesign.primaryBg,
            ],
          ),
          borderRadius: BorderRadius.circular(AppDesign.radiusXL),
          boxShadow: AppDesign.elevatedShadow,
          border: Border.all(
            color: AppDesign.travelBlue.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // 백그라운드 패턴
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      AppDesign.travelBlue.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // 장식적 요소들
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppDesign.travelBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppDesign.travelPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
              ),
            ),
            // 메인 콘텐츠 - 중앙 정렬
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDesign.spacing24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppDesign.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppDesign.travelBlue.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                          BoxShadow(
                            color: AppDesign.travelPurple.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spacing16),
                    Text(
                      '새로운 모험을 시작하세요!',
                      style: AppDesign.headingSmall.copyWith(
                        color: AppDesign.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDesign.spacing8),
                    Text(
                      '지도에서 특별한 장소를 발견하고\n나만의 여행 컬렉션을 만들어보세요',
                      style: AppDesign.bodyMedium.copyWith(
                        color: AppDesign.secondaryText,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDesign.spacing20),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppDesign.primaryGradient,
                        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: AppDesign.travelBlue.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(context, '/map'),
                          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDesign.spacing20,
                              vertical: AppDesign.spacing10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.add_location_alt,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: AppDesign.spacing8),
                                Text(
                                  '지도 탐색하기',
                                  style: AppDesign.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                _buildPremiumMarkerImage(address: marker.address, title: marker.title,),
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

  Widget _buildPremiumMarkerImage({
    required String address,
    String? title,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
      child: Container(
        height: 120,
        width: double.infinity, // 또는 300처럼 넓게
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        ),
        child: AddressPhotoPreview(
          address: address,
          title: title,
          size: 120, // 높이 120px 고정
          // 아래로 오버레이 + 그라데이션 살리기
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            ),
          ),
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

  void _navigateToMarkerDetail(MarkerModel markerModel) {
    final googleMarker = markerModel.toGoogleMarker();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkerDetailView(
          marker: googleMarker,
          keyword: markerModel.keyword,
        ),
      ),
    );
  }
}

// ================================
// 프리미엄 공유 링크 섹션 (항상 표시)
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensurePreviewDataLoaded();
    });
  }

  /// sharedLinks가 늦게 세팅되어도 안전하게 preview 데이터 로드
  void _ensurePreviewDataLoaded() {
    if (widget.sharedLinks.isNotEmpty) {
      _loadAllPreviewData();
    } else {
      // sharedLinks가 나중에 세팅될 수 있으므로 잠깐 지연 후 재시도
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && widget.sharedLinks.isNotEmpty) {
          _loadAllPreviewData();
        } else {
          setState(() {
            _isLoading = false;
            print('[Preview] 링크가 없어서 _isLoading=false 설정');
          });
        }
      });
    }
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
      widget.sharedLinks.map((link) {
        return _loadPreviewForLink(link);
      }),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: AppDesign.spacing20),
        widget.sharedLinks.isEmpty ? _buildEmptyLinksState() : (_isLoading ? _buildPremiumLoadingState() : _buildLinksList()),
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

  void _handleViewAll() {
    if (widget.onViewAll != null) {
      widget.onViewAll!();
    } else {
      _navigateToSharedLinks();
    }
  }

  Widget _buildEmptyLinksState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 290,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDesign.cardBg,
              AppDesign.lightGray,
            ],
          ),
          borderRadius: BorderRadius.circular(AppDesign.radiusXL),
          boxShadow: AppDesign.elevatedShadow,
          border: Border.all(
            color: AppDesign.sunsetGradientStart.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // 백그라운드 패턴
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                  gradient: RadialGradient(
                    center: Alignment.bottomLeft,
                    radius: 1.8,
                    colors: [
                      AppDesign.sunsetGradientStart.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // 장식적 요소들
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppDesign.travelOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppDesign.sunsetGradientEnd.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: 30,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppDesign.sunsetGradientStart.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // 메인 콘텐츠 - 중앙 정렬
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDesign.spacing24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppDesign.sunsetGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppDesign.sunsetGradientStart.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                          BoxShadow(
                            color: AppDesign.sunsetGradientEnd.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spacing16),
                    Text(
                      '여행 링크를 공유해보세요!',
                      style: AppDesign.headingSmall.copyWith(
                        color: AppDesign.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDesign.spacing8),
                    Text(
                      '멋진 여행 관련 링크를 저장하고\n나중에 쉽게 찾아볼 수 있어요',
                      style: AppDesign.bodyMedium.copyWith(
                        color: AppDesign.secondaryText,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDesign.spacing20),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppDesign.sunsetGradient,
                        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: AppDesign.sunsetGradientStart.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(context, '/shared_link'),
                          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDesign.spacing20,
                              vertical: AppDesign.spacing10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.add_link,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: AppDesign.spacing8),
                                Text(
                                  '링크 추가하기',
                                  style: AppDesign.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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