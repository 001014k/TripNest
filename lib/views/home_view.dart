import 'package:flutter/material.dart';
import 'package:fluttertrip/views/shared_link_view.dart';
import 'package:fluttertrip/views/widgets/preview_card.dart';
import 'package:provider/provider.dart';
import '../models/shared_link_model.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/marker_model.dart';

// ================================
// 디자인 시스템 및 상수 정의
// ================================
class AppDesign {
  // 컬러 팔레트 - 모노크롬 테마
  static const Color primaryBg = Color(0xFFF8F9FA);
  static const Color cardBg = Colors.white;
  static const Color darkBg = Color(0xFF121212);
  static const Color primaryText = Color(0xFF000000);
  static const Color secondaryText = Color(0xFF666666);
  static const Color subtleText = Color(0xFF999999);
  static const Color borderColor = Color(0xFFE5E5E5);
  static const Color accentGray = Color(0xFF2D3748);
  static const Color lightGray = Color(0xFFF7F8F9);

  // 간격 시스템
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;

  // 보더 반지름
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;
  static const double radiusXL = 24;

  // 타이포그래피 시스템
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: primaryText,
    letterSpacing: -0.8,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: primaryText,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: secondaryText,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: subtleText,
  );

  // 그림자 효과
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}

// ================================
// 메인 홈 대시보드 뷰
// ================================
class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  late HomeDashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<HomeDashboardViewModel>();
    _initializeData();
  }

  void _initializeData() {
    _viewModel.loadRecentMarkers();
    _viewModel.loadSharedLinks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TripNest',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppDesign.primaryBg,
      body: SafeArea(
        child: Consumer<HomeDashboardViewModel>(
          builder: (context, viewModel, child) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 헤더 섹션
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: _DashboardHeader(),
                  ),
                ),

                // 메인 기능 카드들
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: AppDesign.spacing24),
                        _QuickActionsCard(),
                        const SizedBox(height: AppDesign.spacing24),
                        _FriendsFeatureCard(),
                      ],
                    ),
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
                  child: SizedBox(height: AppDesign.spacing32),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 네비게이션 메서드들
  void _navigateToList() => Navigator.pushNamed(context, '/list');
  void _navigateToSharedLinks() => Navigator.pushNamed(context, '/shared_links');
}

// ================================
// 대시보드 헤더 컴포넌트
// ================================
class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '어디로 떠날까요?',
          style: AppDesign.headingLarge,
        ),
        const SizedBox(height: AppDesign.spacing8),
        const Text(
          '새로운 여행지를 탐색하고 친구들과 계획을 세워보세요',
          style: AppDesign.bodyLarge,
        ),
      ],
    );
  }
}

// ================================
// 퀵 액션 카드 컴포넌트
// ================================
class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusXL),
        boxShadow: AppDesign.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.spacing24),
        child: Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.map_outlined,
                label: '지도 탐색',
                description: '새로운 장소 발견',
                color: AppDesign.primaryText,
                onTap: () => _navigateToMap(context),
              ),
            ),
            const SizedBox(width: AppDesign.spacing20),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.bookmark_outline,
                label: '저장 목록',
                description: '나만의 여행 노트',
                color: AppDesign.accentGray,
                onTap: () => _navigateToList(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMap(BuildContext context) => Navigator.pushNamed(context, '/map');
  void _navigateToList(BuildContext context) => Navigator.pushNamed(context, '/list');
}

// ================================
// 퀵 액션 버튼 컴포넌트
// ================================
class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
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
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
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
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  void _handleTapUp() {
    _animationController.reverse();
    widget.onTap();
  }

  Widget _buildButtonContent() {
    return Column(
      children: [
        _buildIconContainer(),
        const SizedBox(height: AppDesign.spacing12),
        Text(
          widget.label,
          style: AppDesign.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDesign.spacing4),
        Text(
          widget.description,
          style: AppDesign.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIconContainer() {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.lightGray,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        border: Border.all(
          color: widget.color.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppDesign.spacing16),
      child: Icon(
        widget.icon,
        color: widget.color,
        size: 28,
      ),
    );
  }
}

// ================================
// 친구 기능 카드 컴포넌트
// ================================
class _FriendsFeatureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.primaryText,
        borderRadius: BorderRadius.circular(AppDesign.radiusXL),
        boxShadow: AppDesign.primaryShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusXL),
          onTap: () => _navigateToFriends(context),
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing20),
            child: Row(
              children: [
                _buildIconContainer(),
                const SizedBox(width: AppDesign.spacing16),
                Expanded(child: _buildTextContent()),
                _buildArrowIcon(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToFriends(BuildContext context) {
    Navigator.pushNamed(context, '/friends');
  }

  Widget _buildIconContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
      ),
      padding: const EdgeInsets.all(AppDesign.spacing12),
      child: const Icon(
        Icons.people_outline,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '친구들과 함께',
          style: AppDesign.headingMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppDesign.spacing4),
        Text(
          '일정을 공유하고 함께 계획해보세요',
          style: AppDesign.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildArrowIcon() {
    return const Icon(
      Icons.arrow_forward_ios,
      color: Colors.white,
      size: 16,
    );
  }
}

// ================================
// 섹션 헤더 컴포넌트
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
        _buildTitleSection(),
        _buildViewAllButton(),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Row(
      children: [
        Icon(icon, color: AppDesign.primaryText, size: 20),
        const SizedBox(width: AppDesign.spacing8),
        Text(title, style: AppDesign.headingMedium),
      ],
    );
  }

  Widget _buildViewAllButton() {
    return TextButton(
      onPressed: onViewAll,
      style: TextButton.styleFrom(
        foregroundColor: AppDesign.primaryText,
        textStyle: AppDesign.bodyMedium,
        backgroundColor: AppDesign.lightGray,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
        ),
      ),
      child: const Text('전체 보기'),
    );
  }
}

// ================================
// 최근 마커 섹션 컴포넌트
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(
            icon: Icons.location_on_outlined,
            title: '최근 저장한 장소',
            onViewAll: widget.onViewAll,
          ),
        ),
        const SizedBox(height: AppDesign.spacing16),
        _buildMarkersList(),
        const SizedBox(height: AppDesign.spacing32),
      ],
    );
  }

  Widget _buildMarkersList() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: widget.markers.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDesign.spacing12),
        itemBuilder: (context, index) => _buildMarkerCard(widget.markers[index]),
      ),
    );
  }

  Widget _buildMarkerCard(MarkerModel marker) {
    final previewData = _previewDataCache[marker.address];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          onTap: () => _navigateToMarkerDetail(marker),
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMarkerImage(),
                const SizedBox(height: AppDesign.spacing12),
                _buildMarkerTitle(marker, previewData),
                const SizedBox(height: AppDesign.spacing4),
                _buildMarkerDescription(marker, previewData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerImage() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppDesign.lightGray,
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
        border: Border.all(color: AppDesign.borderColor, width: 1),
      ),
      child: const Center(
        child: Icon(
          Icons.place_outlined,
          color: AppDesign.primaryText,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildMarkerTitle(MarkerModel marker, LinkPreviewData? previewData) {
    return Text(
      previewData?.title ?? marker.title,
      style: AppDesign.bodyMedium,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMarkerDescription(MarkerModel marker, LinkPreviewData? previewData) {
    return Text(
      previewData?.description ?? marker.address,
      style: AppDesign.caption,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
// 공유 링크 섹션 컴포넌트
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

  @override
  void initState() {
    super.initState();
    _loadAllPreviewData();
  }

  Future<void> _loadAllPreviewData() async {
    await Future.wait(
      widget.sharedLinks.map((link) => _loadPreviewForLink(link)),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sharedLinks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: AppDesign.spacing16),
        _isLoading ? _buildLoadingState() : _buildLinksList(),
        const SizedBox(height: AppDesign.spacing32),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SectionHeader(
        title: '공유된 링크',
        icon: Icons.share_outlined,
        onViewAll: widget.onViewAll ?? _navigateToSharedLinks,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppDesign.cardBg,
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppDesign.primaryText),
        ),
      ),
    );
  }

  Widget _buildLinksList() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: widget.sharedLinks.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDesign.spacing12),
        itemBuilder: (context, index) => _buildLinkCard(widget.sharedLinks[index]),
      ),
    );
  }

  Widget _buildLinkCard(SharedLinkModel link) {
    final previewData = _previewDataCache[link.url];
    final subtitle = _getClippedSubtitle(previewData, link);

    return PreviewCard(
      title: previewData?.title ?? link.platform,
      subtitle: subtitle,
      imageUrl: previewData?.image,
      width: 280,
      onTap: () => _navigateToLinkDetail(link),
    );
  }

  String _getClippedSubtitle(LinkPreviewData? previewData, SharedLinkModel link) {
    final subtitleText = previewData?.description ?? link.url;
    return subtitleText.length > 80
        ? '${subtitleText.substring(0, 77)}...'
        : subtitleText;
  }

  void _navigateToSharedLinks() {
    Navigator.pushNamed(context, '/shared_links');
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
// 재사용 가능한 기능 카드 컴포넌트
// ================================
class FeatureCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadiusGeometry borderRadius;

  const FeatureCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    super.key,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.color ?? Colors.white,
          borderRadius: widget.borderRadius,
          boxShadow: _isPressed ? null : _getCardShadow(),
        ),
        child: widget.child,
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  List<BoxShadow> _getCardShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}