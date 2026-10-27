import '../../widgets/home/home_skeleton.dart';
import '../../widgets/common/reference_design.dart' show ReferencePlatform;
import '../../widgets/lists/travel_list_card.dart';
import '../../navigation/app_tab_shell.dart';
import '../../widgets/common/app_photo_hero.dart';
import '../../navigation/app_page_route.dart';
import '../../widgets/home/home_weather_card.dart';
import '../../widgets/home/home_date_strip.dart';
import '../../widgets/navigation/tripnest_navigation.dart';
import '../../viewmodels/lists/list_viewmodel.dart';
import '../../services/schedule/schedule_service.dart';
import '../../models/schedule/schedule_model.dart';
import '../lists/marker_info_view.dart';
import '../schedule/schedule_view.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import '../../models/shared_links/link_preview_data.dart';
import '../../mappers/marker_map_adapter.dart';
import 'package:fluttertrip/widgets/places/address_photo_preview.dart';
import 'package:provider/provider.dart';
import '../../models/shared_links/shared_link_model.dart';
import '../../viewmodels/shared_links/shared_link_viewmodel.dart';
import '../../viewmodels/home/home_viewmodel.dart';
import '../../models/markers/marker_model.dart';
import '../../design/app_design.dart';
import '../markers/markerdetail_view.dart';

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
  late Future<List<ScheduleModel>> _upcoming;
  DateTime _scheduleDate = DateUtils.dateOnly(DateTime.now());
  DateTime _dateStripStart = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<HomeDashboardViewModel>();
    _viewModel.subscribeToChanges();
    _initializeAnimations();
    _initializeData();
    _loadUpcoming();
    ScheduleService.changes.addListener(_onSchedulesChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ListViewModel>().loadLists();
      if (!mounted ||
          !context.read<SharedLinkViewModel>().hasPendingSharedUrl) {
        return;
      }
      Navigator.pushNamed(context, '/shared_link');
    });
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 220),
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

  bool _tabWasActive = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _fadeAnimationController.value = 1;
    }
    final active = AppTabVisibility.maybeOf(context)?.active ?? true;
    if (active && !_tabWasActive) _loadUpcoming();
    _tabWasActive = active;
  }

  @override
  void dispose() {
    ScheduleService.changes.removeListener(_onSchedulesChanged);
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _onSchedulesChanged() {
    if (mounted) setState(_loadUpcoming);
  }

  void _loadUpcoming() {
    _upcoming = ScheduleService().fetchByDate(_scheduleDate);
  }

  void _pickScheduleMonth(int month) {
    setState(() {
      final date = DateTime(_scheduleDate.year, month, 1);
      _scheduleDate = date;
      _dateStripStart = date;
      _loadUpcoming();
    });
  }

  Future<void> _openSchedule() async {
    await AppTabController.open(context, '/schedule');
    if (mounted) setState(_loadUpcoming);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.primaryBg,
        bottomNavigationBar: const TripNestNavigation(currentRoute: '/home'),
        body: SafeArea(
            child: Consumer<HomeDashboardViewModel>(
          builder: (context, viewModel, child) => FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TripNestHeader(trailing: TripNestSocialActions()),
                          const SizedBox(height: 20),
                          const Text('오늘의 여행', style: AppDesign.headingXL),
                          const SizedBox(height: 6),
                          const Text('저장한 장소와 일정을 한눈에 확인해보세요.',
                              style: AppDesign.bodyMedium),
                          const SizedBox(height: 18),
                          const HomeWeatherCard(),
                          const SizedBox(height: 18),
                          SectionHeader(
                              title: '다가오는 일정',
                              icon: Icons.calendar_today,
                              onViewAll: _openSchedule),
                          const SizedBox(height: 8),
                          HomeDateStrip(
                              start: _dateStripStart,
                              selected: _scheduleDate,
                              onSelect: (date) => setState(() {
                                    _scheduleDate = date;
                                    _loadUpcoming();
                                  }),
                              onPickMonth: _pickScheduleMonth),
                          const SizedBox(height: 12),
                          _scheduleCard(),
                          const _HomeSectionDivider(),
                          SectionHeader(
                              title: '내 여행 리스트',
                              icon: Icons.list,
                              onViewAll: () =>
                                  Navigator.pushNamed(context, '/list')),
                          const SizedBox(height: 12),
                          _travelListCard(),
                        ])),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _HomeSectionDivider()),
                RecentMarkersSection(
                    markers: viewModel.recentMarkers,
                    onViewAll: _navigateToList),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _HomeSectionDivider()),
                SharedLinksSection(
                    sharedLinks: viewModel.sharedLinks,
                    onViewAll: _navigateToSharedLinks),
              ])),
        )),
      );

  Widget _travelListCard() =>
      Consumer<ListViewModel>(builder: (context, vm, _) {
        if (vm.isLoading && vm.lists.isEmpty)
          return const HomeSkeleton(height: 150);
        if (vm.errorMessage != null) {
          return _summaryCard(const Icon(Icons.refresh), '리스트를 불러오지 못했어요',
              '눌러서 다시 시도', vm.loadLists);
        }
        if (vm.lists.isEmpty) {
          return _summaryCard(const Icon(Icons.add), '첫 여행 리스트 만들기',
              '가고 싶은 장소를 모아보세요', () => Navigator.pushNamed(context, '/list'));
        }
        final list = vm.lists.first;
        return TravelListCard(
          list: list,
          onTap: () => Navigator.pushNamed(context, '/list'),
          onOpen: () => Navigator.push(
              context,
              AppPageRoute(
                  builder: (_) => MarkerInfoPage(
                      listId: list.id,
                      listName: list.name,
                      collaboratorCount: list.collaboratorCount))),
        );
      });

  Widget _scheduleCard() => FutureBuilder<List<ScheduleModel>>(
      future: _upcoming,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const HomeSkeleton();
        }
        if (snapshot.hasError) {
          return _summaryCard(const Icon(Icons.refresh), '일정을 불러오지 못했어요',
              '눌러서 다시 시도', () => setState(_loadUpcoming));
        }
        final items = [...?snapshot.data]
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        if (items.isEmpty) {
          return _summaryCard(
              const Icon(Icons.calendar_today_outlined),
              '선택한 날짜에 일정이 없어요',
              '${_scheduleDate.month}월 ${_scheduleDate.day}일 · 새 일정을 추가해보세요',
              () async {
            await Navigator.push(
                context,
                AppPageRoute(
                    motion: AppMotion.editor,
                    builder: (_) => ScheduleEditView(date: _scheduleDate)));
            if (mounted) setState(_loadUpcoming);
          });
        }
        final item = items.first;
        final start = item.startTime.toLocal();
        return _summaryCard(
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${start.month}월', style: AppDesign.bodySmall),
              Text('${start.day}', style: AppDesign.headingLarge)
            ]),
            item.title,
            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} · 참여자 ${item.collaboratorIds?.length ?? 0}명',
            () async {
          await Navigator.push(
              context,
              AppPageRoute(
                  motion: AppMotion.editor,
                  builder: (_) =>
                      ScheduleEditView(date: start, schedule: item)));
          if (mounted) setState(_loadUpcoming);
        });
      });

  Widget _summaryCard(
          Widget leading, String title, String subtitle, VoidCallback onTap,
          {String? action}) =>
      Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppDesign.borderColor)),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                      width: 68,
                      height: 78,
                      decoration: BoxDecoration(
                          color: AppDesign.lightGray,
                          borderRadius: BorderRadius.circular(13)),
                      child: Center(child: leading)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppDesign.headingSmall),
                        const SizedBox(height: 7),
                        Text(subtitle, style: AppDesign.bodySmall),
                        if (action != null) ...[
                          const SizedBox(height: 10),
                          Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: AppDesign.primary,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.play_arrow,
                                            size: 17, color: Colors.white),
                                        Text(action,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12))
                                      ])))
                        ],
                      ])),
                  if (action == null)
                    const Icon(Icons.chevron_right,
                        color: AppDesign.subtleText),
                ]))),
      );

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
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: AppDesign.headingMedium)),
        TextButton(
            onPressed: onViewAll,
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('전체보기',
                  style:
                      TextStyle(color: AppDesign.secondaryText, fontSize: 12)),
              Icon(Icons.chevron_right,
                  size: 17, color: AppDesign.secondaryText),
            ])),
      ]);
}

// ================================
// 프리미엄 최근 마커 섹션 (항상 표시)
// ================================
class _HomeSectionDivider extends StatelessWidget {
  const _HomeSectionDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 24,
        thickness: 1,
        color: Color(0xFFE9E9EC),
      );
}

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
  @override
  void initState() {
    super.initState();
    if (widget.markers.isNotEmpty) {
      _loadPreviewData();
    }
  }

  @override
  void didUpdateWidget(covariant RecentMarkersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.markers != oldWidget.markers) _loadPreviewData();
  }

  Future<void> _loadPreviewData() async {
    for (final marker in widget.markers) {
      if (!mounted) return;
      await _fetchPreviewForMarker(marker);
    }
  }

  Future<void> _fetchPreviewForMarker(MarkerModel marker) async {
    final url = marker.address;
    if (url.isEmpty) return;
    await context.read<HomeDashboardViewModel>().loadPreview(url);
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
        const SizedBox(height: 10),
        _buildMarkersList(),
      ],
    );
  }

  void _handleViewAll() {
    widget.onViewAll();
  }

  Widget _buildMarkersList() {
    if (context.watch<HomeDashboardViewModel>().loadingRecentMarkers &&
        widget.markers.isEmpty) {
      return const HomePhotoSkeletons();
    }
    if (widget.markers.isEmpty) {
      return _buildEmptyMarkersState();
    }

    return SizedBox(
      height: 88.h + 16.w + MediaQuery.textScalerOf(context).scale(80),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: widget.markers.length.clamp(0, 5),
        separatorBuilder: (_, __) => const SizedBox(width: AppDesign.spacing8),
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
                            color: AppDesign.travelBlue.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                          BoxShadow(
                            color:
                                AppDesign.travelPurple.withValues(alpha: 0.2),
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
                      onPressed: () => AppTabController.open(context, '/map'),
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
    final previewData =
        context.watch<HomeDashboardViewModel>().previewFor(marker.address);

    return Container(
      width: (MediaQuery.sizeOf(context).width * .42).clamp(140.0, 200.0),
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
            padding: EdgeInsets.all(8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPhotoHero(
                  tag: 'home-place-${marker.id}',
                  child: _buildPremiumMarkerImage(
                    address: marker.address,
                    title: marker.title,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing10),
                _buildMarkerTitle(marker, previewData),
                const SizedBox(height: AppDesign.spacing4),
                _buildMarkerDescription(marker, previewData),
                const SizedBox(height: 6),
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
          size: 88.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
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
      style: AppDesign.headingSmall
          .copyWith(color: AppDesign.homeForeground, fontSize: 14),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMarkerDescription(
      MarkerModel marker, LinkPreviewData? previewData) {
    return Text(
      previewData?.description ?? marker.address,
      style: AppDesign.bodyMedium
          .copyWith(color: AppDesign.homeMutedText, fontSize: 11),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMarkerFooter(MarkerModel marker) {
    final query = marker.title.isNotEmpty
        ? '${marker.title} ${marker.address}'
        : marker.address;
    final rating = context.watch<HomeDashboardViewModel>().getRating(query);
    return Wrap(spacing: 5, runSpacing: 4, children: [
      Text(marker.keyword,
          style: AppDesign.caption
              .copyWith(fontSize: 10, color: AppDesign.secondaryText)),
      if (rating != null && rating > 0)
        Text('★ ${rating.toStringAsFixed(1)}',
            style: AppDesign.caption
                .copyWith(fontSize: 10, color: AppDesign.secondaryText)),
    ]);
  }

  void _navigateToMarkerDetail(MarkerModel markerModel) {
    final googleMarker = MarkerMapAdapter.toGoogleMarker(markerModel);
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => MarkerDetailView(
          marker: googleMarker,
          keyword: markerModel.keyword,
          photoHeroTag: 'home-place-${markerModel.id}',
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
    super.key,
  });

  @override
  State<SharedLinksSection> createState() => _SharedLinksSectionState();
}

class _SharedLinksSectionState extends State<SharedLinksSection> {
  bool _isLoadingPreviews = false;
  bool _previewErrorNotified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensurePreviewDataLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant SharedLinksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sourceLinks.isEmpty) return;

    // The home view can receive new extracted places for an existing source
    // URL. Fetch a preview only when a new source URL appears.
    final vm = context.read<HomeDashboardViewModel>();
    if (_sourceLinks.any((link) => !vm.hasPreview(link.url))) {
      _loadAllPreviewData();
    }
  }

  /// Multiple places extracted from one post are stored as separate records.
  /// The home carousel shows that post only once.
  List<SharedLinkModel> get _sourceLinks {
    final linksByUrl = <String, SharedLinkModel>{};
    for (final link in widget.sharedLinks) {
      linksByUrl.putIfAbsent(link.url, () => link);
    }
    return linksByUrl.values.toList();
  }

  // sharedLinks가 늦게 세팅되어도 안전하게 preview 데이터 로드
  void _ensurePreviewDataLoaded() {
    if (_sourceLinks.isNotEmpty) {
      _loadAllPreviewData();
    }
  }

  Future<void> _loadAllPreviewData() async {
    if (_isLoadingPreviews) return;

    final linksToLoad = _sourceLinks
        .where((link) =>
            !context.read<HomeDashboardViewModel>().hasPreview(link.url))
        .toList();
    if (linksToLoad.isEmpty) {
      return;
    }

    _isLoadingPreviews = true;
    try {
      await Future.wait(
        linksToLoad.map(_loadPreviewForLink),
      );
    } finally {
      _isLoadingPreviews = false;
    }
  }

  Future<void> _loadPreviewForLink(SharedLinkModel link) async {
    try {
      final preview =
          await context.read<HomeDashboardViewModel>().loadPreview(link.url);
      if (preview == null) _notifyPreviewLoadIssue();
    } catch (_) {
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
        const SizedBox(height: 10),
        context.watch<HomeDashboardViewModel>().loadingSharedLinks &&
                _sourceLinks.isEmpty
            ? const HomePhotoSkeletons()
            : _sourceLinks.isEmpty
                ? _buildEmptyLinksState()
                : _buildLinksList(),
        const SizedBox(height: 20),
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
                            color: AppDesign.sunsetGradientStart
                                .withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                          BoxShadow(
                            color: AppDesign.sunsetGradientEnd
                                .withValues(alpha: 0.3),
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

  Widget _buildLinksList() {
    return SizedBox(
      height: 174 + MediaQuery.textScalerOf(context).scale(112),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: _sourceLinks.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDesign.spacing16),
        itemBuilder: (context, index) =>
            _buildPremiumLinkCard(_sourceLinks[index]),
      ),
    );
  }

  Widget _buildPremiumLinkCard(SharedLinkModel link) {
    final previewData =
        context.watch<HomeDashboardViewModel>().previewFor(link.url);
    final subtitle = _getClippedSubtitle(previewData, link);
    final placeCount =
        widget.sharedLinks.where((item) => item.url == link.url).length;

    return Container(
      width: (MediaQuery.sizeOf(context).width * .72).clamp(240.0, 340.0),
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
                Row(children: [
                  Expanded(child: ReferencePlatform(platform: link.platform)),
                  const SizedBox(width: 8),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: const Color(0xfff3f3f5),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('장소 $placeCount곳',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xff85858f))))
                ]),
                const SizedBox(height: 10),
                _buildLinkImage(previewData),
                const SizedBox(height: AppDesign.spacing10),
                _buildLinkTitle(previewData, link),
                const SizedBox(height: AppDesign.spacing4),
                _buildLinkDescription(subtitle),
                const Spacer(),
                const Divider(
                    height: 16, thickness: 1, color: Color(0xffeeeeF1)),
                const Row(children: [
                  Expanded(
                      child: Text('링크 상세 보기',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xff484850)))),
                  Icon(Icons.chevron_right, size: 21, color: Color(0xff85858f))
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkImage(LinkPreviewData? previewData) {
    final url = previewData?.image;
    final fallback = const ColoredBox(
        color: Color(0xfff1f2f4),
        child: Center(
            child: Icon(Icons.image_outlined,
                size: 32, color: Color(0xffaaaab3))));
    return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
            height: 100,
            width: double.infinity,
            child: url == null || url.isEmpty
                ? fallback
                : Image.network(url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback)));
  }

  Widget _buildLinkTitle(LinkPreviewData? previewData, SharedLinkModel link) {
    return Text(previewData?.title ?? link.platform,
        style: const TextStyle(
            fontSize: 17,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: Color(0xff202024)),
        maxLines: 2,
        overflow: TextOverflow.ellipsis);
  }

  Widget _buildLinkDescription(String subtitle) => Text(subtitle,
      style:
          const TextStyle(fontSize: 12, height: 1.4, color: Color(0xff85858f)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis);

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
                    color: shadow.color.withValues(
                      alpha: shadow.color.a * _shadowAnimation.value,
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
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }
}
