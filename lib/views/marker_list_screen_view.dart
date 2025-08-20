import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../design/app_design.dart';
import '../viewmodels/marker_list_screen_viewmodel.dart';
import '../views/markerdetail_view.dart';
import '../models/marker_model.dart';

class MarkerListScreen extends StatefulWidget {
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
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    Future.microtask(() {
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

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _fadeAnimationController.forward();
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _shimmerController.dispose();
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
      final titleMatch = title.toLowerCase().contains(searchQuery.toLowerCase());
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

  Widget _buildEnhancedPremiumHeader() {
    return SliverAppBar(
      expandedHeight: 220, // 확장 높이 여유
      toolbarHeight: kToolbarHeight, // 기본 툴바 높이 명시
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: _buildStyledBackButton(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppDesign.spacing24),
          height: 48,
          color: Colors.transparent,
          child: _buildActionButtonsRow(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppDesign.backgroundGradient,
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double height = constraints.maxHeight;
                final bool isExpanded = height > (kToolbarHeight + 100);
                final double topPad = kToolbarHeight + (isExpanded ? 16 : 8); // 뒤로가기 버튼 아래에서 시작
                final double bottomPad = 8;
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDesign.spacing24,
                    topPad,
                    AppDesign.spacing24,
                    bottomPad,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 첫 번째 라인: 상태 배지와 타이틀
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isExpanded) _buildStatusBadge(),
                                if (isExpanded) const SizedBox(height: AppDesign.spacing6),
                                _buildMainTitle(fontSize: isExpanded ? 26 : 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // 버튼 행은 AppBar bottom으로 이동하여 오버플로우 방지
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledBackButton() {
    return Container(
      margin: const EdgeInsets.all(AppDesign.spacing8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppDesign.cardBg.withOpacity(0.95),
            AppDesign.cardBg.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
        boxShadow: AppDesign.softShadow,
        border: Border.all(
          color: AppDesign.borderColor.withOpacity(0.2),
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

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppDesign.travelBlue.withOpacity(0.1),
            AppDesign.travelBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppDesign.travelBlue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppDesign.travelBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selectionMode ? Icons.check_circle_outline : Icons.location_on,
            size: 14,
            color: AppDesign.travelBlue,
          ),
          const SizedBox(width: 6),
          Text(
            selectionMode ? '선택 모드' : '나의 여행 컬렉션',
            style: AppDesign.caption.copyWith(
              color: AppDesign.travelBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTitle({double fontSize = 26}) {
    return Text(
      selectionMode
          ? '선택됨: ${selectedMarkerIds.length}개'
          : '저장한 장소',
      style: AppDesign.headingLarge.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    return Container(
      height: 44, // 명시적 높이 설정
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 정렬 버튼
            _buildPremiumDropdownButton(
              icon: Icons.sort,
              label: selectedSort,
              onTap: _showSortBottomSheet,
            ),

            const SizedBox(width: AppDesign.spacing10), // 간격 줄임

            // 선택 모드 토글
            _buildPremiumActionButton(
              icon: selectionMode ? Icons.check_box : Icons.check_box_outlined,
              label: selectionMode ? '선택중' : '선택',
              onTap: () {
                setState(() {
                  selectionMode = !selectionMode;
                  if (!selectionMode) selectedMarkerIds.clear();
                });
              },
              isActive: selectionMode,
            ),

            if (selectionMode) ...[
              const SizedBox(width: AppDesign.spacing10), // 간격 줄임

              // 전체 선택/해제
              Consumer<MarkerListViewModel>(
                builder: (context, vm, _) {
                  final visible = _applyFilters(vm.markers);
                  final visibleIds = visible.map((m) => m['id'].toString()).toSet();
                  final allSelected = visibleIds.isNotEmpty &&
                      visibleIds.difference(selectedMarkerIds).isEmpty;

                  return _buildPremiumActionButton(
                    icon: allSelected ? Icons.deselect : Icons.select_all,
                    label: allSelected ? '전체해제' : '전체선택',
                    onTap: () {
                      setState(() {
                        if (allSelected) {
                          selectedMarkerIds.removeAll(visibleIds);
                        } else {
                          selectedMarkerIds.addAll(visibleIds);
                        }
                      });
                    },
                  );
                },
              ),

              const SizedBox(width: AppDesign.spacing10), // 간격 줄임

              // 삭제 버튼
              Consumer<MarkerListViewModel>(
                builder: (context, vm, _) {
                  return _buildPremiumActionButton(
                    icon: Icons.delete_forever,
                    label: '삭제 (${selectedMarkerIds.length})',
                    onTap: selectedMarkerIds.isEmpty
                        ? null
                        : () => _showBulkDeleteDialog(vm),
                    isDestructive: true,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
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
            AppDesign.cardBg.withOpacity(0.95),
            AppDesign.cardBg.withOpacity(0.9),
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
              : AppDesign.borderColor.withOpacity(0.2),
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
            AppDesign.cardBg.withOpacity(0.95),
            AppDesign.cardBg.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall), // radius 줄임
        boxShadow: AppDesign.softShadow,
        border: Border.all(
          color: AppDesign.borderColor.withOpacity(0.2),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(AppDesign.spacing16),
        decoration: BoxDecoration(
          color: AppDesign.cardBg,
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          boxShadow: AppDesign.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(AppDesign.spacing20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppDesign.travelBlue.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDesign.radiusLarge),
                  topRight: Radius.circular(AppDesign.radiusLarge),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppDesign.borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDesign.spacing8),
                    decoration: BoxDecoration(
                      gradient: AppDesign.primaryGradient,
                      borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                    ),
                    child: Icon(
                      Icons.sort,
                      color: AppDesign.whiteText,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppDesign.spacing12),
                  Text(
                    '정렬 옵션',
                    style: AppDesign.headingSmall,
                  ),
                  const Spacer(),
                  // 닫기 버튼
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppDesign.lightGray,
                      borderRadius: BorderRadius.circular(AppDesign.spacing8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppDesign.spacing8),
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: AppDesign.subtleText,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 옵션들
            ...['최신순', '이름순', '날짜순'].map((sort) {
              final isSelected = selectedSort == sort;
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDesign.spacing16,
                  vertical: AppDesign.spacing4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppDesign.travelBlue.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDesign.spacing16,
                    vertical: AppDesign.spacing8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppDesign.primaryGradient
                          : LinearGradient(
                        colors: [
                          AppDesign.lightGray,
                          AppDesign.borderColor.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                    ),
                    child: Icon(
                      _getSortIcon(sort),
                      size: 18,
                      color: isSelected ? AppDesign.whiteText : AppDesign.subtleText,
                    ),
                  ),
                  title: Text(
                    sort,
                    style: AppDesign.bodyMedium.copyWith(
                      color: isSelected ? AppDesign.travelBlue : AppDesign.primaryText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: AppDesign.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppDesign.whiteText,
                      size: 14,
                    ),
                  )
                      : null,
                  onTap: () {
                    setState(() {
                      selectedSort = sort;
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),

            const SizedBox(height: AppDesign.spacing20),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.all(AppDesign.spacing24),
      child: Column(
        children: [
          // 프리미엄 검색창
          Container(
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              boxShadow: AppDesign.softShadow,
              border: Border.all(
                color: AppDesign.borderColor.withOpacity(0.3),
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

          const SizedBox(height: AppDesign.spacing20),

          // 프리미엄 카테고리 필터
          _buildCategoryFilters(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppDesign.spacing12),
          child: Text(
            '카테고리',
            style: AppDesign.headingSmall.copyWith(
              color: AppDesign.primaryText,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('전체'),
              _buildCategoryChip('카페'),
              _buildCategoryChip('호텔'),
              _buildCategoryChip('사진'),
              _buildCategoryChip('음식점'),
              _buildCategoryChip('전시회'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = selectedCategory == label ||
        (selectedCategory == null && label == '전체');

    return Padding(
      padding: const EdgeInsets.only(right: AppDesign.spacing12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected ? AppDesign.primaryGradient : null,
          color: isSelected ? null : AppDesign.cardBg,
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          boxShadow: isSelected ? AppDesign.glowShadow : AppDesign.softShadow,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppDesign.borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
            onTap: () {
              setState(() {
                selectedCategory = label;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing20,
                vertical: AppDesign.spacing12,
              ),
              child: Text(
                label,
                style: AppDesign.bodyMedium.copyWith(
                  color: isSelected ? AppDesign.whiteText : AppDesign.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkersSliver() {
    return Consumer<MarkerListViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return _buildLoadingSliver();
        }

        final filteredMarkers = _applyFilters(vm.markers);
        _sortMarkers(filteredMarkers);

        if (filteredMarkers.isEmpty) {
          return _buildEmptySliver();
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDesign.spacing24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (index == 0) {
                  return _buildResultsHeader(filteredMarkers.length);
                } else if (index <= filteredMarkers.length) {
                  final markerIndex = index - 1;
                  final markerMap = filteredMarkers[markerIndex];
                  final marker = MarkerModel.fromMap(markerMap);
                  return Padding(
                    padding: EdgeInsets.only(
                      top: markerIndex == 0 ? AppDesign.spacing16 : 0,
                      bottom: AppDesign.spacing16,
                    ),
                    child: _buildPremiumMarkerCard(marker, markerMap, vm),
                  );
                }
                return null;
              },
              childCount: filteredMarkers.length + 1,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesign.spacing16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesign.spacing8),
            decoration: BoxDecoration(
              gradient: AppDesign.primaryGradient,
              borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
            ),
            child: Icon(
              Icons.location_on,
              color: AppDesign.whiteText,
              size: 16,
            ),
          ),
          const SizedBox(width: AppDesign.spacing12),
          Text(
            '$count개의 장소',
            style: AppDesign.headingMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMarkerCard(
      MarkerModel marker,
      Map<String, dynamic> markerMap,
      MarkerListViewModel vm
      ) {
    return Dismissible(
      key: Key(marker.id),
      background: _buildDismissBackground(),
      direction: selectionMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      confirmDismiss: selectionMode
          ? null
          : (direction) => _showDeleteDialog(marker),
      onDismissed: (direction) async {
        await vm.deleteMarker(context, marker.id);
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
              color: AppDesign.borderColor.withOpacity(0.3),
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
                _buildMarkerIcon(marker),
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

  Widget _buildMarkerIcon(MarkerModel marker) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: _getMarkerGradient(marker.keyword),
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: _getMarkerColor(marker.keyword).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        _getMarkerIcon(marker.keyword),
        color: AppDesign.whiteText,
        size: 28,
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
          maxLines: 1,
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
                color: _getMarkerColor(marker.keyword).withOpacity(0.1),
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
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppDesign.lightGray,
                  AppDesign.borderColor,
                  AppDesign.lightGray,
                ],
                stops: [
                  _shimmerAnimation.value - 0.3,
                  _shimmerAnimation.value,
                  _shimmerAnimation.value + 0.3,
                ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              ),
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            ),
          );
        },
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

  LinearGradient _getMarkerGradient(String keyword) {
    final color = _getMarkerColor(keyword);
    return LinearGradient(
      colors: [color, color.withOpacity(0.8)],
    );
  }

  IconData _getMarkerIcon(String keyword) {
    switch (keyword) {
      case '카페':
        return Icons.coffee;
      case '호텔':
        return Icons.hotel;
      case '사진':
        return Icons.camera_alt;
      case '음식점':
        return Icons.restaurant;
      case '전시회':
        return Icons.museum;
      default:
        return Icons.place;
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
        MaterialPageRoute(
          builder: (_) => MarkerDetailView(
            marker: marker.toGoogleMarker(),
            keyword: marker.keyword,
          ),
        ),
      );
    }
  }

  Future<bool> _showDeleteDialog(MarkerModel marker) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        ),
        backgroundColor: AppDesign.cardBg,
        title: Text(
          "삭제 확인",
          style: AppDesign.headingMedium,
        ),
        content: Text(
          "'${marker.title}'을(를) 삭제하시겠습니까?",
          style: AppDesign.bodyMedium.copyWith(
            color: AppDesign.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "취소",
              style: AppDesign.bodyMedium.copyWith(
                color: AppDesign.subtleText,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade500],
              ),
              borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                "삭제",
                style: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.whiteText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showBulkDeleteDialog(MarkerListViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        ),
        backgroundColor: AppDesign.cardBg,
        title: Text(
          '선택 항목 삭제',
          style: AppDesign.headingMedium,
        ),
        content: Text(
          '${selectedMarkerIds.length}개를 삭제하시겠습니까?',
          style: AppDesign.bodyMedium.copyWith(
            color: AppDesign.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: AppDesign.bodyMedium.copyWith(
                color: AppDesign.subtleText,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade500],
              ),
              borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                '삭제',
                style: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.whiteText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final id in selectedMarkerIds) {
        await vm.deleteMarker(context, id);
      }
      setState(() {
        selectedMarkerIds.clear();
        selectionMode = false;
      });
    }
  }
}