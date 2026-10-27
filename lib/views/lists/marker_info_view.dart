import '../../widgets/markers/marker_delete_dialog.dart';
import '../../widgets/places/place_keyword_icon.dart';
import '../../navigation/app_page_route.dart';
import '../../viewmodels/map/mapsample_viewmodel.dart';
import '../../viewmodels/lists/add_markers_to_list_viewmodel.dart';
import '../../widgets/common/reference_design.dart';
import '../map/mapsample_view.dart';
import '../schedule/schedule_view.dart';
import '../../widgets/places/address_photo_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/app_design.dart';
import '../../models/markers/marker_model.dart';
import '../../mappers/marker_map_adapter.dart';
import '../../viewmodels/lists/marker_info_viewmodel.dart';
import 'add_markers_to_list_view.dart';
import '../markers/markerdetail_view.dart';
import 'list_collaboration_view.dart';

class MarkerInfoPage extends StatefulWidget {
  final String listId;
  final String? listName;
  final int collaboratorCount;
  final VoidCallback? onManage;
  final VoidCallback? onCollaborate;

  const MarkerInfoPage(
      {super.key,
      required this.listId,
      this.listName,
      this.collaboratorCount = 0,
      this.onManage,
      this.onCollaborate});

  @override
  State<MarkerInfoPage> createState() => _MarkerInfoPageState();
}

class _MarkerInfoPageState extends State<MarkerInfoPage> {
  late MarkerInfoViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = MarkerInfoViewModel(listId: widget.listId);
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> navigateToAddMarkersToListPage() async {
    if (!viewModel.canEditPlaces) return;
    final result = await Navigator.push(
      context,
      AppPageRoute(
        motion: AppMotion.editor,
        builder: (context) => AddMarkersToListPage(listId: widget.listId),
      ),
    );
    if (result == true) {
      await viewModel.loadMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MarkerInfoViewModel>.value(
      value: viewModel,
      child: Scaffold(
        backgroundColor: AppDesign.primaryBg,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppDesign.backgroundGradient,
          ),
          child: SafeArea(
            child: Consumer<MarkerInfoViewModel>(
              builder: (context, vm, child) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildPremiumAppBar(context)),
                    if (vm.isLoading)
                      SliverToBoxAdapter(child: _buildLoadingState())
                    else if (vm.error != null)
                      SliverToBoxAdapter(child: _buildErrorState(vm.error!))
                    else if (vm.markers.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyState())
                    else ...[
                      SliverToBoxAdapter(
                        child: _buildHeaderInfo(vm.markers.length),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesign.spacing20,
                          vertical: AppDesign.spacing8,
                        ),
                        sliver: SliverReorderableList(
                          itemCount: vm.markers.length,
                          onReorderItem: (oldIndex, newIndex) async {
                            if (!vm.isOwner) return;
                            final map = context.read<MapSampleViewModel>();
                            final add =
                                context.read<AddMarkersToListViewModel>();
                            try {
                              await map.loadMarkersForList(widget.listId);
                              await map.reorderMarkers(
                                  oldIndex, newIndex, widget.listId, add);
                              await vm.loadMarkers();
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('순서를 저장하지 못했어요. 다시 시도해주세요.')));
                              }
                            }
                          },
                          itemBuilder: (context, index) {
                            final marker = vm.markers[index];
                            return _MarkerInfoCard(
                                key: ValueKey(marker.id),
                                marker: marker,
                                details: {
                                  'title': marker.title,
                                  'address': marker.address,
                                  'keyword': marker.keyword
                                },
                                index: index,
                                canReorder: vm.isOwner,
                                onDelete: vm.canEditPlaces
                                    ? () => _confirmDelete(context, vm, marker)
                                    : null);
                          },
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppDesign.spacing40 * 2),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        floatingActionButton: Consumer<MarkerInfoViewModel>(
          builder: (_, vm, __) =>
              vm.canEditPlaces ? _buildPremiumFAB() : const SizedBox.shrink(),
        ),
        bottomNavigationBar: SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        AppPageRoute(
                            builder: (_) =>
                                MapPreviewView(initialListId: widget.listId))),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppDesign.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('경로 시작')))),
      ),
    );
  }

  Widget _buildPremiumAppBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconButton(
                tooltip: '뒤로',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21)),
            const Expanded(
                child: Text('TripNest',
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.8))),
            IconButton(
                tooltip: '알림 설정',
                onPressed: () =>
                    Navigator.pushNamed(context, '/notification_settings'),
                icon: const Icon(Icons.notifications_none_rounded)),
            if (viewModel.isOwner && widget.onManage != null)
              IconButton(
                  tooltip: '리스트 관리',
                  onPressed: widget.onManage,
                  icon: const Icon(Icons.more_vert)),
          ]),
          const SizedBox(height: 14),
          Consumer<MarkerInfoViewModel>(
              builder: (context, vm, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                      height: 168,
                      child: Stack(fit: StackFit.expand, children: [
                        if (vm.markers.isNotEmpty)
                          AddressPhotoPreview(
                              address: vm.markers.first.address,
                              title: vm.markers.first.title,
                              size: 168)
                        else
                          const ColoredBox(color: Color(0xFF636C6C)),
                        const DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                              Color(0x08000000),
                              Color(0xB3000000)
                            ]))),
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(widget.listName ?? '여행 리스트',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                  const SizedBox(height: 6),
                                  Text(
                                      '저장한 장소 ${vm.markers.length}개 · ${widget.collaboratorCount + 1}명이 함께 편집 중',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    Expanded(
                                        child: SizedBox(
                                      height: 32,
                                      child: Stack(
                                          children: List.generate(
                                        (widget.collaboratorCount + 1)
                                            .clamp(1, 3),
                                        (index) => Positioned(
                                          left: index * 23.0,
                                          child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFE4E3E0),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5)),
                                              child: const Icon(
                                                  Icons.person_outline,
                                                  color: Color(0xFF666970),
                                                  size: 22)),
                                        ),
                                      )),
                                    )),
                                    if (viewModel.isOwner &&
                                        widget.onCollaborate != null)
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              AppDesign.primaryText,
                                          minimumSize: const Size(0, 34),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 13, vertical: 7),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        onPressed: widget.onCollaborate,
                                        icon: const Icon(Icons.people_outline,
                                            size: 19),
                                        label: const Text('공유하기',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                  ]),
                                ])),
                      ])))),
          const SizedBox(height: 12),
          Row(children: [
            _listAction(
                Icons.place_outlined,
                '지도 보기',
                () => Navigator.push(
                    context,
                    AppPageRoute(
                        builder: (_) =>
                            MapPreviewView(initialListId: widget.listId)))),
            _listAction(
                Icons.format_list_bulleted, '일정으로 추가', _addListToSchedule),
            _listAction(Icons.link, '공유 링크',
                () => Navigator.pushNamed(context, '/shared_link')),
            _listAction(
                Icons.group_outlined,
                '협업 관리',
                () => Navigator.push(
                    context,
                    AppPageRoute(
                        builder: (_) =>
                            ListCollaborationView(listId: widget.listId)))),
          ]),
        ]),
      );
  Future<void> _addListToSchedule() async {
    if (viewModel.isLoading ||
        viewModel.error != null ||
        viewModel.markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장소 목록을 불러온 뒤 장소를 추가해주세요.')));
      return;
    }
    final places = List<MarkerModel>.of(viewModel.markers);
    final result = await Navigator.push<bool>(
        context,
        AppPageRoute<bool>(
            motion: AppMotion.editor,
            builder: (_) => ScheduleEditView(
                date: DateTime.now(),
                initialTitle: widget.listName ?? '여행',
                initialPlaces: places)));
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${places.length}개 장소를 일정에 추가했어요.')));
    }
  }

  Widget _listAction(IconData icon, String text, VoidCallback onTap) =>
      Expanded(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                      side: const BorderSide(color: Color(0xFFF0F0F2))),
                  child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(13),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Column(children: [
                            Icon(icon, size: 24),
                            const SizedBox(height: 7),
                            Text(text,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center)
                          ]))))));

  Widget _buildHeaderInfo(int count) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(children: [
        Expanded(child: Text('저장한 장소 $count개', style: AppDesign.headingSmall)),
        const Text('추가된 순', style: AppDesign.bodySmall),
      ]));

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      margin: EdgeInsets.all(AppDesign.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 애니메이션 로딩 컨테이너
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              shape: BoxShape.circle,
              boxShadow: AppDesign.elevatedShadow,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
                  strokeWidth: 3,
                ),
                Icon(
                  Icons.location_on_outlined,
                  color: AppDesign.travelBlue.withValues(alpha: 0.3),
                  size: 32,
                ),
              ],
            ),
          ),
          SizedBox(height: AppDesign.spacing32),
          Text(
            '마커를 불러오는 중...',
            style: AppDesign.headingSmall,
          ),
          SizedBox(height: AppDesign.spacing8),
          Text(
            '잠시만 기다려주세요',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: EdgeInsets.all(AppDesign.spacing24),
      padding: EdgeInsets.all(AppDesign.spacing32),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade400,
                  Colors.orange.shade400,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppDesign.whiteText,
              size: 40,
            ),
          ),
          SizedBox(height: AppDesign.spacing24),
          Text(
            '오류가 발생했습니다',
            style: AppDesign.headingMedium,
          ),
          SizedBox(height: AppDesign.spacing8),
          Text(
            error,
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDesign.spacing24),
          Container(
            decoration: BoxDecoration(
              gradient: AppDesign.primaryGradient,
              borderRadius: BorderRadius.circular(AppDesign.radiusXL),
              boxShadow: AppDesign.glowShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: () => viewModel.loadMarkers(),
              icon: Icon(Icons.refresh_rounded, color: AppDesign.whiteText),
              label: Text(
                '다시 시도',
                style: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.whiteText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: AppDesign.spacing24,
                  vertical: AppDesign.spacing12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.all(AppDesign.spacing24),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppDesign.spacing40),
            decoration: BoxDecoration(
              gradient: AppDesign.sunsetGradient,
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              boxShadow: AppDesign.elevatedShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
                  ),
                  child: Icon(
                    Icons.add_location_alt_rounded,
                    color: AppDesign.whiteText,
                    size: 48,
                  ),
                ),
                SizedBox(height: AppDesign.spacing24),
                Text(
                  '아직 마커가 없어요',
                  style: AppDesign.headingMedium.copyWith(
                    color: AppDesign.whiteText,
                  ),
                ),
                SizedBox(height: AppDesign.spacing8),
                Text(
                  '새로운 여행지를 추가해보세요!',
                  style: AppDesign.bodyLarge.copyWith(
                    color: AppDesign.whiteText.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppDesign.spacing20),
          // 가이드 카드들
          Container(
            padding: EdgeInsets.all(AppDesign.spacing16),
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              boxShadow: AppDesign.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppDesign.spacing8),
                  decoration: BoxDecoration(
                    color: AppDesign.travelBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppDesign.travelBlue,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppDesign.spacing12),
                Expanded(
                  child: Text(
                    '하단의 + 버튼을 눌러 시작하세요',
                    style: AppDesign.bodyMedium.copyWith(
                      color: AppDesign.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: [
          ...AppDesign.elevatedShadow,
          BoxShadow(
            color: AppDesign.travelBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          onTap: navigateToAddMarkersToListPage,
          child: Icon(
            Icons.add_location_rounded,
            color: AppDesign.whiteText,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, MarkerInfoViewModel vm, MarkerModel marker) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (_) => MarkerDeleteDialog(
              removeFromList: true,
              title: marker.title,
              address: marker.address,
              imageUrl: marker.markerImagePath.startsWith('http')
                  ? marker.markerImagePath
                  : null,
              tags: [if (marker.keyword.trim().isNotEmpty) marker.keyword],
            ));
    if (result == true && context.mounted) {
      await vm.deleteMarker(marker.id);
    }
  }
}

// 마커 카드 위젯
class _MarkerInfoCard extends StatelessWidget {
  final MarkerModel marker;
  final Map<String, String> details;
  final int index;
  final VoidCallback? onDelete;
  final bool canReorder;

  const _MarkerInfoCard({
    super.key,
    required this.marker,
    required this.details,
    required this.index,
    required this.onDelete,
    required this.canReorder,
  });

  @override
  Widget build(BuildContext context) {
    final title = details['title'] ?? '제목 없음';
    final address = details['address'] ?? '주소 없음';
    final keyword = details['keyword'] ?? '키워드 없음';

    // 키워드별 색상 매핑
    final keywordColors = {
      '카페': AppDesign.travelOrange,
      '호텔': AppDesign.travelBlue,
      '사진': AppDesign.travelPurple,
      '음식점': AppDesign.travelGreen,
      '전시회': AppDesign.sunsetGradientStart,
    };

    final keywordColor = keywordColors[keyword] ?? AppDesign.travelBlue;

    void navigateToMarkerDetail(MarkerModel markerModel) {
      final googleMarker = MarkerMapAdapter.toGoogleMarker(markerModel);
      Navigator.push(
        context,
        AppPageRoute(
          builder: (context) => MarkerDetailView(
            marker: googleMarker,
            keyword: markerModel.keyword,
          ),
        ),
      );
    }

    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ReferenceCard(
          padding: const EdgeInsets.all(8),
          child: InkWell(
              onTap: () => navigateToMarkerDetail(marker),
              child: Row(children: [
                SizedBox(
                    width: 96,
                    height: 80,
                    child: Stack(children: [
                      ReferencePhoto(
                          title: title,
                          address: address,
                          width: 96,
                          height: 80),
                      Positioned(
                          top: 4,
                          left: 4,
                          child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              child: Text('${index + 1}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppDesign.primaryText)))),
                    ])),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Icon(placeKeywordIcon(keyword),
                            size: 15, color: keywordColor),
                        const SizedBox(width: 5),
                        Expanded(
                            child: Text(keyword,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: keywordColor))),
                      ]),
                      const SizedBox(height: 4),
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppDesign.subtleText),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppDesign.caption)),
                      ]),
                    ])),
                if (onDelete != null)
                  IconButton(
                      tooltip: '리스트에서 삭제',
                      onPressed: onDelete,
                      icon:
                          const Icon(Icons.bookmark_remove_outlined, size: 22)),
                if (canReorder)
                  ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.drag_handle,
                              size: 22, color: AppDesign.subtleText))),
              ])),
        ));
  }
}
