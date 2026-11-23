import '../../navigation/app_page_route.dart';
import '../../widgets/common/app_overlays.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../design/app_design.dart';
import '../../viewmodels/markers/marker_list_screen_viewmodel.dart';
import 'markerdetail_view.dart';
import '../../models/markers/marker_model.dart';
import '../../mappers/marker_map_adapter.dart';
import '../../widgets/common/travel_shimmer.dart';
import '../../widgets/places/address_photo_preview.dart';

class MarkerListScreen extends StatefulWidget {
  const MarkerListScreen({super.key});

  @override
  State<MarkerListScreen> createState() => _MarkerListScreenState();
}

class _MarkerListScreenState extends State<MarkerListScreen>
    with TickerProviderStateMixin {
  String searchQuery = '';
  String? selectedCategory;
  String selectedSort = '최신순';

  bool selectionMode = false;
  Set<String> selectedMarkerIds = {};

  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MarkerListViewModel>().fetchMarkers();
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

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  String formatDate(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.tryParse(createdAt);
    return date != null ? DateFormat('yyyy년 M월 d일').format(date) : '';
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> source) {
    return source.where((marker) {
      final title = marker['title']?.toString() ?? '';
      final keyword = marker['keyword']?.toString();
      final titleMatch =
          title.toLowerCase().contains(searchQuery.toLowerCase());
      final categoryMatch = (selectedCategory == null ||
          selectedCategory == '전체' ||
          keyword == selectedCategory);
      return titleMatch && categoryMatch;
    }).toList();
  }

  DateTime _parseCreatedAt(Map<String, dynamic> m) {
    final raw = m['created_at']?.toString();
    final dt = raw != null ? DateTime.tryParse(raw) : null;
    return dt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: selectionMode
          ? SafeArea(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FilledButton.icon(
                    onPressed: selectedMarkerIds.isEmpty
                        ? null
                        : () => _showBulkDeleteDialog(
                            context.read<MarkerListViewModel>()),
                    icon: const Icon(Icons.delete_outline),
                    label: Text('선택한 장소 ${selectedMarkerIds.length}개 삭제'),
                  )))
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 개선된 프리미엄 헤더
                _buildEnhancedPremiumHeader(),

                // 검색 및 필터 섹션
                SliverToBoxAdapter(
                  child: _buildSearchAndFilters(),
                ),

                Consumer<MarkerListViewModel>(
                    builder: (context, vm, _) => SliverToBoxAdapter(
                        child: vm.errorMessage == null
                            ? const SizedBox.shrink()
                            : TextButton.icon(
                                onPressed:
                                    vm.isLoading ? null : vm.fetchMarkers,
                                icon: const Icon(Icons.refresh),
                                label: Text('${vm.errorMessage} 다시 시도')))),
                // 마커 리스트
                _buildMarkersSliver(),

                // 하단 여백
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDesign.spacing40),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedPremiumHeader() => SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppDesign.primaryBg,
      leading: _buildStyledBackButton(),
      title: Consumer<MarkerListViewModel>(
          builder: (context, vm, _) => Row(children: [
                const Flexible(
                    child: Text('저장한 장소', style: AppDesign.headingMedium)),
                if (!vm.isLoading) ...[
                  const SizedBox(width: 8),
                  Text('${_applyFilters(vm.markers).length}',
                      style: AppDesign.bodyMedium),
                ],
              ])),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(height: 48, child: _buildActionButtonsRow()),
        ),
      ));

  Widget _buildStyledBackButton() {
    return Container(
      margin: const EdgeInsets.all(AppDesign.spacing8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppDesign.cardBg.withValues(alpha: 0.95),
            AppDesign.cardBg.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
        boxShadow: AppDesign.softShadow,
        border: Border.all(
          color: AppDesign.borderColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: AppDesign.primaryText,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    if (selectionMode) {
      return Consumer<MarkerListViewModel>(builder: (context, vm, _) {
        final visibleIds =
            _applyFilters(vm.markers).map((m) => m['id'].toString()).toSet();
        final allSelected = visibleIds.isNotEmpty &&
            visibleIds.difference(selectedMarkerIds).isEmpty;
        return Row(children: [
          Expanded(
              child: Text('${selectedMarkerIds.length}개 선택',
                  style: AppDesign.bodyMedium)),
          TextButton(
              onPressed: visibleIds.isEmpty
                  ? null
                  : () => setState(() {
                        if (allSelected) {
                          selectedMarkerIds.removeAll(visibleIds);
                        } else {
                          selectedMarkerIds.addAll(visibleIds);
                        }
                      }),
              child: Text(allSelected ? '전체 해제' : '전체 선택')),
          TextButton(
              onPressed: () => setState(() {
                    selectionMode = false;
                    selectedMarkerIds.clear();
                  }),
              child: const Text('취소')),
        ]);
      });
    }
    return Row(children: [
      Expanded(
          child: _buildPremiumDropdownButton(
              icon: Icons.sort,
              label: selectedSort,
              onTap: _showSortBottomSheet)),
      const SizedBox(width: 10),
      _buildPremiumActionButton(
          icon: Icons.check_box_outlined,
          label: '선택',
          onTap: () => setState(() => selectionMode = true)),
    ]);
  }

  Widget _buildPremiumActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    final isEnabled = onTap != null;

    return Container(
      height: 40, // 높이 줄임
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing12, // 패딩 줄임
        vertical: AppDesign.spacing8,
      ),
      decoration: BoxDecoration(
        gradient: isEnabled && (isActive || isDestructive)
            ? (isDestructive
                ? LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : AppDesign.primaryGradient)
            : LinearGradient(
                colors: [
                  AppDesign.cardBg.withValues(alpha: 0.95),
                  AppDesign.cardBg.withValues(alpha: 0.9),
                ],
              ),
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall), // radius 줄임
        boxShadow: isEnabled
            ? (isActive || isDestructive
                ? AppDesign.glowShadow
                : AppDesign.softShadow)
            : null,
        border: Border.all(
          color: isActive || isDestructive
              ? Colors.transparent
              : AppDesign.borderColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isEnabled
                    ? (isActive || isDestructive
                        ? AppDesign.whiteText
                        : AppDesign.primaryText)
                    : AppDesign.subtleText,
                size: 16, // 아이콘 크기 줄임
              ),
              const SizedBox(width: AppDesign.spacing6), // 간격 줄임
              Text(
                label,
                style: AppDesign.bodyMedium.copyWith(
                  color: isEnabled
                      ? (isActive || isDestructive
                          ? AppDesign.whiteText
                          : AppDesign.primaryText)
                      : AppDesign.subtleText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // 폰트 크기 줄임
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumDropdownButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 40, // 높이 줄임
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing12, // 패딩 줄임
        vertical: AppDesign.spacing8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppDesign.cardBg.withValues(alpha: 0.95),
            AppDesign.cardBg.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall), // radius 줄임
        boxShadow: AppDesign.softShadow,
        border: Border.all(
          color: AppDesign.borderColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppDesign.travelBlue,
                size: 16, // 아이콘 크기 줄임
              ),
              const SizedBox(width: AppDesign.spacing6), // 간격 줄임
              Text(
                label,
                style: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // 폰트 크기 줄임
                ),
              ),
              const SizedBox(width: AppDesign.spacing4),
              Icon(
                Icons.keyboard_arrow_down,
                color: AppDesign.travelBlue,
                size: 14, // 아이콘 크기 줄임
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showAppSheet<void>(
        context: context,
        builder: (sheet) => AppSheet(
              title: '정렬 옵션',
              subtitle: '저장한 장소를 원하는 순서로 확인해보세요.',
              children: [
                for (final sort in ['최신순', '이름순', '날짜순'])
                  AppSheetOption(
                      title: sort,
                      icon: _getSortIcon(sort),
                      selected: selectedSort == sort,
                      onTap: () {
                        setState(() => selectedSort = sort);
                        Navigator.pop(sheet);
                      }),
              ],
            ));
  }

  IconData _getSortIcon(String sort) {
    switch (sort) {
      case '최신순':
        return Icons.schedule;
      case '이름순':
        return Icons.sort_by_alpha;
      case '날짜순':
        return Icons.calendar_today;
      default:
        return Icons.sort;
    }
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          // 검색창
          Container(
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              boxShadow: AppDesign.softShadow,
              border: Border.all(
                color: AppDesign.borderColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: '장소 검색...',
                hintStyle: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.subtleText,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(AppDesign.spacing12),
                  child: Icon(
                    Icons.search,
                    color: AppDesign.travelBlue,
                    size: 24,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.spacing20,
                  vertical: AppDesign.spacing16,
                ),
              ),
              style: AppDesign.bodyMedium,
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),

          const SizedBox(height: AppDesign.spacing8),

          // 카테고리 필터
          _buildCategoryFilters(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() => Row(children: [
        Expanded(
            child: Text(
                selectedCategory == null || selectedCategory == '전체'
                    ? '전체 카테고리'
                    : selectedCategory!,
                style: AppDesign.bodyMedium)),
        TextButton.icon(
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('필터'),
          onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (sheet) => SafeArea(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('장소 카테고리',
                                style: AppDesign.headingSmall),
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              for (final label in [
                                '전체',
                                '카페',
                                '호텔',
                                '사진',
                                '음식점',
                                '전시회',
                                '자연',
                                '관광명소',
                                '쇼핑',
                                '체험'
                              ])
                                ChoiceChip(
                                    label: Text(label),
                                    selected:
                                        (selectedCategory ?? '전체') == label,
                                    onSelected: (_) {
                                      setState(() => selectedCategory = label);
                                      Navigator.pop(sheet);
                                    }),
                            ]),
                          ])))),
        ),
      ]);

  Widget _buildMarkersSliver() {
    return Consumer<MarkerListViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return _buildLoadingSliver();
        }

        final filteredMarkers = _applyFilters(vm.markers);
        _sortMarkers(filteredMarkers);

        if (filteredMarkers.isEmpty) {
          if (vm.errorMessage != null) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return _buildEmptySliver();
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDesign.spacing24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < filteredMarkers.length) {
                  final markerIndex = index;
                  final markerMap = filteredMarkers[markerIndex];
                  final marker = MarkerModel.fromMap(markerMap);
                  return Padding(
                    padding: EdgeInsets.only(
                      top: 0,
                      bottom: AppDesign.spacing16,
                    ),
                    child: _buildPremiumMarkerCard(marker, markerMap, vm),
                  );
                }
                return null;
              },
              childCount: filteredMarkers.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumMarkerCard(MarkerModel marker,
      Map<String, dynamic> markerMap, MarkerListViewModel vm) {
    return Dismissible(
      key: Key(marker.id),
      background: _buildDismissBackground(),
      direction:
          selectionMode ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss:
          selectionMode ? null : (direction) => _showDeleteDialog(marker),
      onDismissed: (direction) async {
        final deleted = await vm.deleteMarker(marker.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(deleted ? '삭제되었습니다.' : '삭제에 실패했습니다.')),
          );
        }
        setState(() {
          selectedMarkerIds.remove(marker.id);
        });
      },
      child: GestureDetector(
        onTap: () => _handleMarkerTap(marker),
        child: Container(
          decoration: BoxDecoration(
            color: AppDesign.cardBg,
            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
            boxShadow: AppDesign.softShadow,
            border: selectedMarkerIds.contains(marker.id)
                ? Border.all(
                    color: AppDesign.travelBlue,
                    width: 2,
                  )
                : Border.all(
                    color: AppDesign.borderColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing20),
            child: Row(
              children: [
                if (selectionMode) ...[
                  _buildSelectionCheckbox(marker),
                  const SizedBox(width: AppDesign.spacing16),
                ],
                _buildMarkerPhoto(marker),
                const SizedBox(width: AppDesign.spacing16),
                Expanded(
                  child: _buildMarkerInfo(marker, markerMap),
                ),
                if (!selectionMode)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppDesign.subtleText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCheckbox(MarkerModel marker) {
    final isSelected = selectedMarkerIds.contains(marker.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: isSelected ? AppDesign.primaryGradient : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? Colors.transparent : AppDesign.borderColor,
          width: 2,
        ),
      ),
      child: isSelected
          ? Icon(
              Icons.check,
              color: AppDesign.whiteText,
              size: 16,
            )
          : null,
    );
  }

  Widget _buildMarkerPhoto(MarkerModel marker) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        child: AddressPhotoPreview(
          key: ValueKey('saved-place-photo-${marker.id}'),
          address: marker.address,
          title: marker.title,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildMarkerInfo(MarkerModel marker, Map<String, dynamic> markerMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          marker.title,
          style: AppDesign.headingSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDesign.spacing4),
        Text(
          marker.address,
          style: AppDesign.bodyMedium.copyWith(
            color: AppDesign.secondaryText,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDesign.spacing8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getMarkerColor(marker.keyword).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesign.spacing12),
              ),
              child: Text(
                marker.keyword,
                style: AppDesign.caption.copyWith(
                  color: _getMarkerColor(marker.keyword),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppDesign.spacing8),
            Text(
              formatDate(markerMap['created_at']),
              style: AppDesign.caption,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDesign.spacing8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppDesign.spacing20),
      child: Icon(
        Icons.delete_forever,
        color: AppDesign.whiteText,
        size: 28,
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverPadding(
      padding: const EdgeInsets.all(AppDesign.spacing24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildShimmerCard(),
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing16),
      padding: const EdgeInsets.all(AppDesign.spacing20),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: TravelShimmer(
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppDesign.cardBg,
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.spacing24),
        child: Container(
          height: 400,
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
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppDesign.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppDesign.glowShadow,
                  ),
                  child: Icon(
                    Icons.explore_outlined,
                    color: AppDesign.whiteText,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing24),
                Text(
                  '조건에 맞는 장소가 없습니다',
                  style: AppDesign.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDesign.spacing8),
                Text(
                  '다른 검색어나 카테고리를 시도해보세요',
                  style: AppDesign.bodyMedium.copyWith(
                    color: AppDesign.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 헬퍼 메서드들
  void _sortMarkers(List<Map<String, dynamic>> markers) {
    markers.sort((a, b) {
      switch (selectedSort) {
        case '최신순':
          return _parseCreatedAt(b).compareTo(_parseCreatedAt(a));
        case '이름순':
          return (a['title']?.toString().toLowerCase() ?? '')
              .compareTo((b['title']?.toString().toLowerCase() ?? ''));
        case '날짜순':
          return _parseCreatedAt(a).compareTo(_parseCreatedAt(b));
        default:
          return 0;
      }
    });
  }

  Color _getMarkerColor(String keyword) {
    switch (keyword) {
      case '카페':
        return AppDesign.travelOrange;
      case '호텔':
        return AppDesign.travelBlue;
      case '사진':
        return AppDesign.travelPurple;
      case '음식점':
        return AppDesign.travelGreen;
      case '전시회':
        return AppDesign.sunsetGradientStart;
      default:
        return AppDesign.travelBlue;
    }
  }

  void _handleMarkerTap(MarkerModel marker) {
    if (selectionMode) {
      setState(() {
        if (selectedMarkerIds.contains(marker.id)) {
          selectedMarkerIds.remove(marker.id);
        } else {
          selectedMarkerIds.add(marker.id);
        }
      });
    } else {
      Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => MarkerDetailView(
            marker: MarkerMapAdapter.toGoogleMarker(marker),
            keyword: marker.keyword,
          ),
        ),
      );
    }
  }

  Future<bool> _showDeleteDialog(MarkerModel marker) async =>
      await showDialog<bool>(
          context: context,
          builder: (_) => AppConfirmDialog(
              title: '장소를 삭제할까요?',
              message: "'${marker.title}'을(를) 삭제합니다. 이 작업은 되돌릴 수 없습니다.",
              confirmLabel: '삭제',
              destructive: true,
              icon: Icons.delete_outline)) ??
      false;

  Future<void> _showBulkDeleteDialog(MarkerListViewModel vm) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AppConfirmDialog(
            title: '선택한 장소를 삭제할까요?',
            message:
                '${selectedMarkerIds.length}개 장소를 삭제합니다. 이 작업은 되돌릴 수 없습니다.',
            confirmLabel: '삭제',
            destructive: true,
            icon: Icons.delete_outline));
    if (confirm == true) {
      for (final id in selectedMarkerIds) {
        if (!mounted) return;
        final deleted = await vm.deleteMarker(id);
        if (mounted && !deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제에 실패했습니다.')),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        selectedMarkerIds.clear();
        selectionMode = false;
      });
    }
  }
}
