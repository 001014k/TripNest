import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart' as shimmer_pkg;
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:fluttertrip/views/shared_link_view.dart';
import 'package:fluttertrip/widgets/address_photo_preview.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shared_link_model.dart';
import '../viewmodels/shared_link_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/marker_model.dart';
import '../design/app_design.dart';
import 'community_board_view.dart';
import 'markerdetail_view.dart';

// ================================
// 메인 홈 대시보드 뷰
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
    _viewModel.subscribeToChanges();
    _initializeAnimations();
    _initializeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !context.read<SharedLinkViewModel>().hasPendingSharedUrl) {
        return;
      }
      Navigator.pushNamed(context, '/shared_link');
    });
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
        decoration:
            const BoxDecoration(gradient: AppDesign.homeBackgroundGradient),
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
                        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                        child: _DashboardHeader(
                          userId:
                              Supabase.instance.client.auth.currentUser?.id ??
                                  '',
                        ),
                      ),
                    ),

                    // 프리미엄 웰컴 카드
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: _MoodBanner(),
                      ),
                    ),

                    // 메인 기능 그리드
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
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

  Future<void> _navigateToList() async {
    await Navigator.pushNamed(context, '/marker_list');
    if (mounted) _viewModel.loadRecentMarkers();
  }

  Future<void> _navigateToSharedLinks() async {
    await Navigator.pushNamed(context, '/shared_link');
    if (mounted) _viewModel.loadSharedLinks();
  }
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
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: AppDesign.homeEyebrow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '트래블 노트',
                      style: AppDesign.caption.copyWith(
                        color: AppDesign.homeEyebrow,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.spacing12),
                Text(
                  '어디로 떠날까요?',
                  style: AppDesign.headingXL.copyWith(
                    color: AppDesign.homeForeground,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing8),
                Text(
                  '새로운 모험이 당신을 기다리고 있어요 ✈️',
                  style: AppDesign.bodyLarge.copyWith(
                    color: AppDesign.homeMutedText,
                  ),
                ),
              ],
            ),
            _buildProfileAvatar(context),
          ],
        ),
        const SizedBox(height: AppDesign.spacing24),
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
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: AppDesign.homeSurface,
          border: Border.all(color: AppDesign.homeSurfaceBorder),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: AppDesign.softShadow,
        ),
        child: Icon(
          Icons.person_outline,
          color: AppDesign.homeTagForeground,
          size: 24.sp,
        ),
      ),
    );
  }
}

// ================================
// 무드 배너 — 비인터랙티브(정보 전달) + 탭 가능한 진입점
// ================================
class _MoodBanner extends StatelessWidget {
  const _MoodBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '여행 이야기 게시판 열기',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CommunityBoardView()),
          ),
          child: Container(
            height: 160.h,
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              gradient: AppDesign.homeHeroGradient,
              borderRadius: BorderRadius.circular(AppDesign.radiusXL),
              boxShadow: AppDesign.softShadow,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -16.w,
                  top: -16.h,
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 20.w,
                  bottom: -24.h,
                  child: Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 52.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 여행',
                        style: AppDesign.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '세계 어디든,\n당신의 이야기로',
                        style: AppDesign.headingSmall.copyWith(
                          color: Colors.white,
                          fontSize: 20.sp,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '숨겨진 보석을 발견해보세요',
                        style: AppDesign.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppDesign.homeForeground,
                      size: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================
// 메인 기능 그리드
// ================================
class _MainFeaturesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeatureGridItem(
                icon: _buildIcon(Icons.map_outlined),
                title: '지도 탐색',
                subtitle: '새로운 장소 발견하기',
                gradient: AppDesign.homeMapIconGradient,
                onTap: () => Navigator.pushNamed(context, '/map'),
              ),
            ),
            const SizedBox(width: AppDesign.spacing16),
            Expanded(
              child: _FeatureGridItem(
                icon: _buildIcon(Icons.bookmark_outline),
                title: '여행 리스트',
                subtitle: '나만의 여행 노트',
                gradient: AppDesign.homeListIconGradient,
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

  static Widget _buildIcon(IconData iconData) => Icon(
        iconData,
        color: AppDesign.whiteText,
        size: 22.sp,
      );
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
          child: ShadCard(
            height: 140.h,
            padding: EdgeInsets.all(20.w),
            backgroundColor: AppDesign.homeSurface,
            radius: BorderRadius.circular(AppDesign.radiusLarge),
            border: ShadBorder.all(color: AppDesign.homeSurfaceBorder),
            shadows: AppDesign.softShadow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: widget.icon,
                ),
                const Spacer(),
                Text(
                  widget.title,
                  style: AppDesign.bodyMedium.copyWith(
                    color: AppDesign.homeForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing4),
                Text(
                  widget.subtitle,
                  style: AppDesign.caption.copyWith(
                    color: AppDesign.homeMutedText,
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
    return ShadCard(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      backgroundColor: AppDesign.homeSurface,
      radius: BorderRadius.circular(AppDesign.radiusLarge),
      border: ShadBorder.all(color: AppDesign.homeSurfaceBorder),
      shadows: AppDesign.softShadow,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          onTap: () => Navigator.pushNamed(context, '/friend_management'),
          child: Row(
            children: [
              _buildAnimatedIcon(),
              SizedBox(width: AppDesign.spacing20),
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
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: AppDesign.homeMutedSurface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            Icons.people_outline,
            color: AppDesign.homeTagForeground,
            size: 28.sp,
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
          style:
              AppDesign.headingSmall.copyWith(color: AppDesign.homeForeground),
        ),
        const SizedBox(height: AppDesign.spacing4),
        Text(
          '여행 계획을 공유하고 추억을 함께 만들어보세요',
          style: AppDesign.bodyMedium.copyWith(
            color: AppDesign.homeMutedText,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildArrowIcon() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppDesign.homeMutedSurface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        Icons.arrow_forward_ios,
        color: AppDesign.homeTagForeground,
        size: 16.sp,
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
  final Gradient iconGradient;

  const SectionHeader({
    required this.title,
    required this.icon,
    required this.onViewAll,
    this.iconGradient = AppDesign.homeListIconGradient,
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
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: iconGradient,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: Colors.white, size: 16.sp),
            ),
            const SizedBox(width: AppDesign.spacing12),
            Text(
              title,
              style: AppDesign.headingMedium.copyWith(
                color: AppDesign.homeForeground,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Row(
            children: [
              Text(
                '전체 보기',
                style: AppDesign.caption.copyWith(
                  color: AppDesign.homeTagForeground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(width: 2.w),
              Icon(
                Icons.chevron_right,
                size: 16.sp,
                color: AppDesign.homeTagForeground,
              ),
            ],
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
  bool _previewErrorNotified = false;

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
    if (url.isEmpty ||
        _previewDataCache.containsKey(url) ||
        _loadingUrls.contains(url)) {
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
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: SectionHeader(
            icon: Icons.location_on,
            title: '최근 저장한 장소',
            onViewAll: _handleViewAll,
            iconGradient: AppDesign.homeMapIconGradient,
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
      height: 226.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: widget.markers.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDesign.spacing16),
        itemBuilder: (context, index) =>
            _buildPremiumMarkerCard(widget.markers[index]),
      ),
    );
  }

  Widget _buildEmptyMarkersState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        height: 252.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDesign.homeSurface,
              AppDesign.homeBackgroundTop,
            ],
          ),
          borderRadius: BorderRadius.circular(AppDesign.radiusXL),
          boxShadow: AppDesign.elevatedShadow,
          border: Border.all(
            color: AppDesign.homeSurfaceBorder,
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
                      AppDesign.homeMutedSurface,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // 장식적 요소들
            Positioned(
              top: 20.h,
              right: 20.w,
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: AppDesign.homeMutedSurface,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                ),
              ),
            ),
            Positioned(
              bottom: 20.h,
              left: 20.w,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppDesign.homeMutedSurface,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
              ),
            ),
            // 메인 콘텐츠 - 중앙 정렬
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDesign.spacing24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: AppDesign.homeActionSurface,
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
                      child: Icon(
                        Icons.explore_outlined,
                        color: Colors.white,
                        size: 36.sp,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spacing16),
                    Text(
                      '새로운 모험을 시작하세요!',
                      style: AppDesign.headingSmall.copyWith(
                        color: AppDesign.homeForeground,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDesign.spacing8),
                    Text(
                      '지도에서 특별한 장소를 발견하고\n나만의 여행 컬렉션을 만들어보세요',
                      style: AppDesign.bodyMedium.copyWith(
                        color: AppDesign.homeMutedText,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDesign.spacing20),
                    // shadcn_ui 버튼으로 교체 — 탭 가능한 요소임이 더 분명하게 보입니다.
                    ShadButton(
                      onPressed: () => Navigator.pushNamed(context, '/map'),
                      leading: Icon(Icons.add_location_alt, size: 16.sp),
                      child: Text(
                        '지도 탐색하기',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
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
      width: 274.w,
      decoration: BoxDecoration(
        color: AppDesign.homeSurface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          onTap: () => _navigateToMarkerDetail(marker),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumMarkerImage(
                  address: marker.address,
                  title: marker.title,
                ),
                const SizedBox(height: AppDesign.spacing10),
                _buildMarkerTitle(marker, previewData),
                const SizedBox(height: AppDesign.spacing4),
                _buildMarkerDescription(marker, previewData),
                const Spacer(),
                _buildMarkerFooter(marker),
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
        height: 88.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        ),
        child: AddressPhotoPreview(
          address: address,
          title: title,
          size: 88,
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
      style: AppDesign.headingSmall.copyWith(color: AppDesign.homeForeground),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMarkerDescription(
      MarkerModel marker, LinkPreviewData? previewData) {
    return Text(
      previewData?.description ?? marker.address,
      style: AppDesign.bodyMedium.copyWith(color: AppDesign.homeMutedText),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMarkerFooter(MarkerModel marker) {
    final keyword = (marker.keyword ?? '').trim();
    final query = (marker.title != null && marker.title!.isNotEmpty)
        ? '${marker.title} ${marker.address}'
        : marker.address;

    final viewModel = context.read<HomeDashboardViewModel>();
    final rating = viewModel.getRating(query);
    final keywordSurface = AppDesign.homeKeywordSurface(keyword);
    final keywordForeground = AppDesign.homeKeywordForeground(keyword);

    return Row(
      children: [
        if (keyword.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: keywordSurface,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.label,
                  size: 12.sp,
                  color: keywordForeground,
                ),
                SizedBox(width: 4.w),
                Text(
                  keyword,
                  style: AppDesign.caption.copyWith(
                    color: keywordForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        if (rating != null && rating > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < rating.floor()
                      ? Icons.star
                      : (index < rating ? Icons.star_half : Icons.star_border),
                  size: 14.sp,
                  color: AppDesign.homeTagForeground,
                );
              }),
              SizedBox(width: 6.w),
              Text(
                rating.toStringAsFixed(1),
                style: AppDesign.caption.copyWith(
                  color: AppDesign.homeForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          // 평점 로딩 표시 — 스피너 대신 shimmer 플레이스홀더로 통일감을 줍니다.
          shimmer_pkg.Shimmer.fromColors(
            baseColor: AppDesign.homeMutedSurface,
            highlightColor: AppDesign.homeSurface,
            child: Container(
              width: 40.w,
              height: 14.h,
              decoration: BoxDecoration(
                color: AppDesign.homeMutedSurface,
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),
        SizedBox(width: 12.w),
        Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: AppDesign.homeNavigationText,
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

class _SharedLinksSectionState extends State<SharedLinksSection> {
  final Map<String, LinkPreviewData> _previewDataCache = {};
  bool _isLoading = true;
  bool _previewErrorNotified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensurePreviewDataLoaded();
    });
  }

  // sharedLinks가 늦게 세팅되어도 안전하게 preview 데이터 로드
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
          });
        }
      });
    }
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
      _notifyPreviewLoadIssue();
    }
  }

  // 미리보기 로드 실패는 섹션당 1번만 조용히 안내합니다(스팸 방지).
  void _notifyPreviewLoadIssue() {
    if (_previewErrorNotified || !mounted) return;
    _previewErrorNotified = true;
    ElegantNotification.info(
      title: const Text('알림'),
      description: const Text('일부 링크의 미리보기를 불러오지 못했어요'),
      position: Alignment.topCenter,
      animation: AnimationType.fromTop,
      toastDuration: const Duration(seconds: 2),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: AppDesign.spacing20),
        widget.sharedLinks.isEmpty
            ? _buildEmptyLinksState()
            : (_isLoading ? _buildPremiumLoadingState() : _buildLinksList()),
        const SizedBox(height: AppDesign.spacing40),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SectionHeader(
        title: '공유된 링크',
        icon: Icons.share,
        onViewAll: _handleViewAll,
        iconGradient: AppDesign.homeLinkIconGradient,
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
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        height: 252.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDesign.homeSurface,
              AppDesign.homeBackgroundTop,
            ],
          ),
          borderRadius: BorderRadius.circular(AppDesign.radiusXL),
          boxShadow: AppDesign.elevatedShadow,
          border: Border.all(
            color: AppDesign.homeSurfaceBorder,
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
                      AppDesign.homeMutedSurface,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // 장식적 요소들
            Positioned(
              top: 16.h,
              left: 16.w,
              child: Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: AppDesign.homeMutedSurface,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                ),
              ),
            ),
            Positioned(
              bottom: 16.h,
              right: 16.w,
              child: Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  color: AppDesign.homeMutedSurface,
                  borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
                ),
              ),
            ),
            Positioned(
              top: 60.h,
              right: 30.w,
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: AppDesign.homeMutedSurface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // 메인 콘텐츠 - 중앙 정렬
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDesign.spacing24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: AppDesign.homeActionSurface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppDesign.sunsetGradientStart.withOpacity(0.4),
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
                      child: Icon(
                        Icons.share_outlined,
                        color: AppDesign.homeTagForeground,
                        size: 36.sp,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spacing16),
                    Text(
                      '여행 링크를 공유해보세요!',
                      style: AppDesign.headingSmall.copyWith(
                        color: AppDesign.homeForeground,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDesign.spacing8),
                    Text(
                      '멋진 여행 관련 링크를 저장하고\n나중에 쉽게 찾아볼 수 있어요',
                      style: AppDesign.bodyMedium.copyWith(
                        color: AppDesign.homeMutedText,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDesign.spacing20),
                    // shadcn_ui 버튼으로 교체 — 탭 가능한 요소임이 더 분명하게 보입니다.
                    ShadButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/shared_link'),
                      leading: Icon(Icons.add_link, size: 16.sp),
                      child: Text(
                        '링크 추가하기',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
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
    // 커스텀 pulse 애니메이션 대신 shimmer 패키지의 스윕 효과를 사용합니다.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: shimmer_pkg.Shimmer.fromColors(
        baseColor: AppDesign.homeSurface,
        highlightColor: AppDesign.homeBackgroundTop,
        child: Container(
          height: 208.h,
          decoration: BoxDecoration(
            color: AppDesign.homeSurface,
            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
            boxShadow: AppDesign.softShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  gradient: AppDesign.homeListIconGradient,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.cloud_download,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              const SizedBox(height: AppDesign.spacing16),
              Text(
                '링크 정보를 불러오는 중...',
                style: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.homeMutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinksList() {
    return SizedBox(
      height: 226.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: widget.sharedLinks.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDesign.spacing16),
        itemBuilder: (context, index) =>
            _buildPremiumLinkCard(widget.sharedLinks[index]),
      ),
    );
  }

  Widget _buildPremiumLinkCard(SharedLinkModel link) {
    final previewData = _previewDataCache[link.url];
    final subtitle = _getClippedSubtitle(previewData, link);

    return Container(
      width: 274.w,
      decoration: BoxDecoration(
        color: AppDesign.homeSurface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
        border: Border.all(
          color: AppDesign.homeSurfaceBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          onTap: () => _navigateToLinkDetail(link),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLinkImage(previewData),
                const SizedBox(height: AppDesign.spacing10),
                _buildLinkTitle(previewData, link),
                const SizedBox(height: AppDesign.spacing4),
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
      height: 88.h,
      decoration: BoxDecoration(
        gradient:
            previewData?.image != null ? null : AppDesign.homeListIconGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        image: previewData?.image != null
            ? DecorationImage(
                image: NetworkImage(previewData!.image!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: previewData?.image == null
          ? Center(
              child: Icon(
                Icons.link,
                color: Colors.white,
                size: 40.sp,
              ),
            )
          : null,
    );
  }

  Widget _buildLinkTitle(LinkPreviewData? previewData, SharedLinkModel link) {
    return Text(
      previewData?.title ?? link.platform,
      style: AppDesign.headingSmall.copyWith(color: AppDesign.homeForeground),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLinkDescription(String subtitle) {
    return Text(
      subtitle,
      style: AppDesign.bodyMedium.copyWith(color: AppDesign.homeMutedText),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLinkFooter(SharedLinkModel link) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppDesign.homeTagSurface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            link.platform,
            style: AppDesign.caption.copyWith(
              color: AppDesign.homeTagForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppDesign.homeMutedSurface,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(
            Icons.open_in_new,
            size: 14.sp,
            color: AppDesign.homeNavigationText,
          ),
        ),
      ],
    );
  }

  String _getClippedSubtitle(
      LinkPreviewData? previewData, SharedLinkModel link) {
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
      arguments: link,
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
                color: widget.gradient == null
                    ? (widget.color ?? AppDesign.cardBg)
                    : null,
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
