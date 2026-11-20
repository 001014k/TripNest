import 'dart:ui' show ImageFilter;
import '../../widgets/places/place_keyword_icon.dart';
import '../../widgets/places/place_star_rating.dart';
import '../../widgets/home/home_skeleton.dart';
import '../../widgets/common/reference_design.dart' show ReferencePhoto;

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
            top: false,
            child: Consumer<HomeDashboardViewModel>(
              builder: (context, viewModel, child) => FadeTransition(
                  opacity: _fadeAnimation,
                  // 대시보드는 소수의 정해진 섹션으로 구성되므로 위젯을 유지합니다.
                  // 스크롤할 때 날씨·미리보기 로더를 다시 만들거나
                  // 화면 밖 섹션의 높이를 다시 계산하지 않도록 합니다.
                  child: SingleChildScrollView(
                      key: const PageStorageKey('home-dashboard-scroll'),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HomeHeroBackground(
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        20,
                                        MediaQuery.paddingOf(context).top + 8,
                                        20,
                                        8),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const TripNestHeader(
                                              trailing:
                                                  TripNestSocialActions()),
                                          const SizedBox(height: 20),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(_todayLabel(),
                                                  style: AppDesign.bodySmall
                                                      .copyWith(
                                                          fontSize: 13,
                                                          height: 1.5)),
                                              const Text('오늘의 여행',
                                                  style: AppDesign.headingXL),
                                              const SizedBox(height: 12),
                                              const HomeWeatherCard(),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          HomeDateStrip(
                                              start: _dateStripStart,
                                              selected: _scheduleDate,
                                              onSelect: (date) => setState(() {
                                                    _scheduleDate = date;
                                                    _loadUpcoming();
                                                  }),
                                              onPickMonth: _pickScheduleMonth),
                                          const SizedBox(height: 12),
                                          _HomeGlassSurface(
                                              child: _scheduleCard()),
                                          Center(
                                              child: TextButton(
                                            onPressed: _openSchedule,
                                            style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppDesign.primaryText,
                                                minimumSize: const Size(0, 48)),
                                            child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('일정 전체보기'),
                                                  Icon(Icons.chevron_right,
                                                      size: 20),
                                                ]),
                                          )),
                                        ]))),
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 24, 20, 0),
                                child: Column(children: [
                                  SectionHeader(
                                      title: '내 여행 리스트',
                                      icon: Icons.list,
                                      onViewAll: () => Navigator.pushNamed(
                                          context, '/list')),
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
                          ]))),
            )),
      );

  String _todayLabel() {
    final date = DateTime.now();
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일';
  }

  Widget _travelListCard() =>
      Consumer<ListViewModel>(builder: (context, vm, _) {
        if (vm.isLoading && vm.lists.isEmpty) {
          return const HomeSkeleton(height: 150);
        }
        if (vm.errorMessage != null) {
          return _summaryCard(const Icon(Icons.refresh), '리스트를 불러오지 못했어요',
              '눌러서 다시 시도', vm.loadLists);
        }
        if (vm.lists.isEmpty) {
          return _summaryCard(const Icon(Icons.add), '첫 여행 리스트 만들기',
              '가고 싶은 장소를 모아보세요', () => Navigator.pushNamed(context, '/list'));
        }
        final list = vm.lists.first;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppDesign.homeSurfaceBorder),
              borderRadius: BorderRadius.circular(18)),
          child: LayoutBuilder(builder: (context, constraints) {
            final photo = ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ReferencePhoto(
                    title: list.coverTitle ?? list.name,
                    width: double.infinity,
                    height: 154));
            final details =
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(list.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppDesign.headingSmall),
              const SizedBox(height: 6),
              Semantics(
                label: '저장한 장소 ${list.markerCount}개'
                    '${list.collaboratorCount > 0 ? ', ${list.collaboratorCount + 1}명이 함께 편집 중' : ''}',
                child: ExcludeSemantics(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppDesign.secondaryText),
                        const SizedBox(width: 3),
                        Text('장소 ${list.markerCount}개',
                            style: AppDesign.bodySmall.copyWith(height: 1.5)),
                      ]),
                      if (list.collaboratorCount > 0)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.people_outline_rounded,
                              size: 14, color: AppDesign.secondaryText),
                          const SizedBox(width: 3),
                          Text('${list.collaboratorCount + 1}명',
                              style: AppDesign.bodySmall.copyWith(height: 1.5)),
                        ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final keyword in list.keywords)
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppDesign.lightGray,
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(placeKeywordIcon(keyword), size: 16),
                        const SizedBox(width: 4),
                        Text(keyword,
                            style: AppDesign.caption
                                .copyWith(color: AppDesign.primaryText)),
                      ])),
              ]),
              const SizedBox(height: 8),
              FilledButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      AppPageRoute(
                          builder: (_) => MarkerInfoPage(
                              listId: list.id,
                              listName: list.name,
                              collaboratorCount: list.collaboratorCount))),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('바로 보기'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppDesign.homeForeground,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)))),
            ]);
            // 접근성을 위해 공간을 더 확보해야 하는 경우를 제외하고 기준 레이아웃을 유지합니다.
            if (constraints.maxWidth < 280 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [photo, const SizedBox(height: 12), details]);
            }
            return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: photo),
                  const SizedBox(width: 12),
                  Expanded(child: details),
                ]);
          }),
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
              '눌러서 다시 시도', () => setState(_loadUpcoming),
              inline: true);
        }
        final items = [...?snapshot.data]
            .where((item) =>
                !DateUtils.isSameDay(_scheduleDate, DateTime.now()) ||
                !item.endTime.isBefore(DateTime.now()))
            .toList()
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
          }, inline: true, shrinkTitle: true);
        }
        final item = items.first;
        final start = item.startTime.toLocal();
        return _summaryCard(
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                  '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                  style: AppDesign.headingSmall),
              Text(
                  DateUtils.isSameDay(start, DateTime.now())
                      ? '오늘'
                      : '${start.month}/${start.day}',
                  style:
                      AppDesign.bodySmall.copyWith(fontSize: 13, height: 1.5))
            ]),
            '${item.title}${items.length > 1 ? ' · 외 ${items.length - 1}개' : ''}',
            '참여자 ${item.collaboratorIds?.length ?? 0}명', () async {
          await Navigator.push(
              context,
              AppPageRoute(
                  motion: AppMotion.editor,
                  builder: (_) =>
                      ScheduleEditView(date: start, schedule: item)));
          if (mounted) setState(_loadUpcoming);
        }, inline: true);
      });

  Widget _summaryCard(
          Widget leading, String title, String subtitle, VoidCallback onTap,
          {String? action, bool inline = false, bool shrinkTitle = false}) =>
      Material(
        color: inline ? Colors.transparent : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: inline
                ? BorderSide.none
                : const BorderSide(color: AppDesign.borderColor)),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                      width: 68,
                      height: inline ? 48 : 78,
                      decoration: BoxDecoration(
                          color:
                              inline ? Colors.transparent : AppDesign.lightGray,
                          borderRadius: BorderRadius.circular(13)),
                      child: Center(child: leading)),
                  if (inline)
                    Container(
                        width: 1, height: 36, color: AppDesign.borderColor),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        if (shrinkTitle)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(title,
                                maxLines: 1, style: AppDesign.headingSmall),
                          )
                        else
                          Text(title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppDesign.headingSmall),
                        const SizedBox(height: 7),
                        Text(subtitle,
                            style: AppDesign.bodySmall
                                .copyWith(fontSize: 13, height: 1.5)),
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
        Expanded(
            child: Text(title,
                style: AppDesign.headingMedium
                    .copyWith(fontSize: 22, fontWeight: FontWeight.w600))),
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
  Widget build(BuildContext context) => const SizedBox(height: 32);
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
      height: 88.h + 16.w + MediaQuery.textScalerOf(context).scale(100),
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
    final query = marker.title.isEmpty
        ? marker.address
        : '${marker.title} ${marker.address}';
    final rating = context.watch<HomeDashboardViewModel>().getRating(query);
    return SizedBox(
        width:
            (MediaQuery.sizeOf(context).width * .42).clamp(140, 200).toDouble(),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
                child: InkWell(
                    onTap: () => _navigateToMarkerDetail(marker),
                    child: Stack(fit: StackFit.expand, children: [
                      AppPhotoHero(
                          tag: 'home-place-${marker.id}',
                          child: AddressPhotoPreview(
                              address: marker.address,
                              title: marker.title,
                              size: 180)),
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                            Colors.black54,
                            Colors.transparent,
                            Colors.black87
                          ]))),
                      Positioned(
                          left: 8,
                          top: 8,
                          right: 8,
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        ExcludeSemantics(
                                            child: Icon(
                                                placeKeywordIcon(marker.keyword
                                                        .trim()
                                                        .isEmpty
                                                    ? '기타'
                                                    : marker.keyword.trim()),
                                                size: 16,
                                                color: Colors.white)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                            child: Text(
                                                marker.keyword.trim().isEmpty
                                                    ? '기타'
                                                    : marker.keyword.trim(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppDesign.caption
                                                    .copyWith(
                                                        color: Colors.white))),
                                      ]),
                                    ],
                                  )))),
                      Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(marker.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                PlaceStarRating(
                                    rating: rating,
                                    starSize: 14,
                                    textStyle: AppDesign.caption
                                        .copyWith(color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(marker.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13))
                              ]))
                    ])))));
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

    // 홈 화면은 기존 원본 URL에서 새로 추출된 장소를 받을 수 있습니다.
    // 새 원본 URL이 추가된 경우에만 미리보기를 조회합니다.
    final vm = context.read<HomeDashboardViewModel>();
    if (_sourceLinks.any((link) => !vm.hasPreview(link.url))) {
      _loadAllPreviewData();
    }
  }

  /// 하나의 게시물에서 추출한 여러 장소는 각각 별도 기록으로 저장됩니다.
  /// 홈 캐러셀에서는 해당 게시물을 한 번만 표시합니다.
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
    final links = _sourceLinks.take(2).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppDesign.homeSurfaceBorder)),
        child: Column(children: [
          for (var i = 0; i < links.length; i++) ...[
            if (i > 0)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Divider(height: 1, color: AppDesign.borderColor)),
            _buildPremiumLinkCard(links[i]),
          ],
        ]),
      ),
    );
  }

  Widget _buildPremiumLinkCard(SharedLinkModel link) {
    final preview =
        context.watch<HomeDashboardViewModel>().previewFor(link.url);
    final count = widget.sharedLinks
        .where((item) =>
            item.url == link.url &&
            (item.placeAddress?.trim().isNotEmpty ?? false))
        .length;
    return InkWell(
      onTap: () => _navigateToLinkDetail(link),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          SizedBox(width: 52, height: 52, child: _buildLinkImage(preview)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(preview?.title ?? link.placeTitle ?? link.url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${link.platform} · 장소 $count개',
                    style: AppDesign.bodySmall.copyWith(fontSize: 13)),
              ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              size: 20, color: AppDesign.secondaryText),
        ]),
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

/// 제한된 영역 한 곳에만 흐림 효과를 적용해 홈 피드를 가볍게 유지합니다.
class _HomeGlassSurface extends StatelessWidget {
  const _HomeGlassSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        enabled: !highContrast,
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: highContrast ? 1 : .85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppDesign.homeForeground.withValues(alpha: .08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _HomeHeroBackground extends StatelessWidget {
  const _HomeHeroBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: ColoredBox(
          color: const Color(0xFFEDEDF2),
          child: Stack(children: [
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 300 + MediaQuery.paddingOf(context).top,
                child: ExcludeSemantics(
                    child: IgnorePointer(
                        child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/images/home_sea_horizon.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                      colors: [Color(0xB3EDEDF2), Color(0x20EDEDF2)],
                    ))),
                    const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, .25, .55, 1],
                      colors: [
                        Color(0xB3EDEDF2),
                        Color(0x33EDEDF2),
                        Color(0x55EDEDF2),
                        Color(0xFFEDEDF2)
                      ],
                    ))),
                  ],
                )))),
            child,
          ]),
        ),
      );
}
