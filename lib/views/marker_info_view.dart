import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/app_design.dart';
import '../models/marker_model.dart';
import '../viewmodels/marker_info_viewmodel.dart';
import '../views/add_markers_to_list_view.dart';
import 'markerdetail_view.dart';

class MarkerInfoPage extends StatefulWidget {
  final String listId;

  const MarkerInfoPage({Key? key, required this.listId}) : super(key: key);

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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
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
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final marker = vm.markers[index];
                              return FutureBuilder<Map<String, String>>(
                                future: vm.fetchMarkerDetail(marker.id),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Container(
                                      margin: EdgeInsets.only(
                                          bottom: AppDesign.spacing16),
                                      padding:
                                          EdgeInsets.all(AppDesign.spacing32),
                                      decoration: BoxDecoration(
                                        color:
                                            AppDesign.cardBg.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(
                                            AppDesign.radiusLarge),
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppDesign.travelBlue
                                                  .withOpacity(0.5),
                                            ),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return _MarkerInfoCard(
                                    marker: marker,
                                    details: snapshot.data!,
                                    index: index,
                                    onDelete: () =>
                                        _confirmDelete(context, vm, marker.id),
                                  );
                                },
                              );
                            },
                            childCount: vm.markers.length,
                          ),
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
        floatingActionButton: _buildPremiumFAB(),
      ),
    );
  }

  Widget _buildPremiumAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDesign.spacing20,
        AppDesign.spacing20,
        AppDesign.spacing20,
        AppDesign.spacing12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 뒤로가기 버튼
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppDesign.cardBg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                  boxShadow: AppDesign.softShadow,
                  border: Border.all(
                    color: AppDesign.borderColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/list',
                        (route) => false,
                      );
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppDesign.primaryText,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // 우측 액션 버튼
              Container(
                padding: EdgeInsets.all(AppDesign.spacing12),
                decoration: BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppDesign.glowShadow,
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: AppDesign.whiteText,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDesign.spacing24),
          // 타이틀 섹션
          Container(
            padding: EdgeInsets.all(AppDesign.spacing20),
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              boxShadow: AppDesign.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppDesign.spacing12),
                  decoration: BoxDecoration(
                    gradient: AppDesign.sunsetGradient,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppDesign.whiteText,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppDesign.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '마커 정보',
                        style: AppDesign.headingMedium,
                      ),
                      SizedBox(height: AppDesign.spacing4),
                      Text(
                        '저장된 여행지를 관리하세요',
                        style: AppDesign.caption.copyWith(
                          color: AppDesign.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(int count) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppDesign.spacing20,
        vertical: AppDesign.spacing8,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDesign.spacing16,
        vertical: AppDesign.spacing12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppDesign.travelBlue.withOpacity(0.1),
            AppDesign.travelPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        border: Border.all(
          color: AppDesign.travelBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppDesign.travelBlue,
            size: 20,
          ),
          SizedBox(width: AppDesign.spacing12),
          Text(
            '총 $count개의 마커가 저장되어 있습니다',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.travelBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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
                  color: AppDesign.travelBlue.withOpacity(0.3),
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
                  color: Colors.red.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.2),
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
                    color: AppDesign.whiteText.withOpacity(0.9),
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
                    color: AppDesign.travelBlue.withOpacity(0.1),
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
            color: AppDesign.travelBlue.withOpacity(0.3),
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
      BuildContext context, MarkerInfoViewModel vm, String markerId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppDesign.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          ),
          titlePadding: EdgeInsets.fromLTRB(
            AppDesign.spacing24,
            AppDesign.spacing24,
            AppDesign.spacing24,
            AppDesign.spacing8,
          ),
          contentPadding: EdgeInsets.fromLTRB(
            AppDesign.spacing24,
            AppDesign.spacing8,
            AppDesign.spacing24,
            0,
          ),
          actionsPadding: EdgeInsets.all(AppDesign.spacing16),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppDesign.spacing8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                  size: 24,
                ),
              ),
              SizedBox(width: AppDesign.spacing12),
              Text(
                '마커 삭제',
                style: AppDesign.headingSmall,
              ),
            ],
          ),
          content: Text(
            '이 마커를 삭제하시겠습니까?\n삭제한 마커는 복구할 수 없습니다.',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
              height: 1.5,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDesign.spacing20,
                      vertical: AppDesign.spacing12,
                    ),
                  ),
                  child: Text(
                    '취소',
                    style: AppDesign.bodyMedium.copyWith(
                      color: AppDesign.secondaryText,
                    ),
                  ),
                ),
                SizedBox(width: AppDesign.spacing8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDesign.spacing24,
                        vertical: AppDesign.spacing12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesign.radiusSmall),
                      ),
                    ),
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
          ],
        );
      },
    );
    if (result == true) {
      vm.deleteMarker(markerId);
    }
  }
}

// 마커 카드 위젯
class _MarkerInfoCard extends StatelessWidget {
  final MarkerModel marker;
  final Map<String, String> details;
  final int index;
  final VoidCallback onDelete;

  const _MarkerInfoCard({
    required this.marker,
    required this.details,
    required this.index,
    required this.onDelete,
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

    return Container(
      margin: EdgeInsets.only(bottom: AppDesign.spacing16),
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
            padding: EdgeInsets.all(AppDesign.spacing20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 인덱스 번호 표시
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            keywordColor,
                            keywordColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppDesign.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: keywordColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.place_rounded,
                            color: AppDesign.whiteText,
                            size: 24,
                          ),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: AppDesign.whiteText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppDesign.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 타이틀
                          Text(
                            title,
                            style: AppDesign.headingSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppDesign.spacing8),
                          // 주소
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: AppDesign.spacing8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(AppDesign.spacing4),
                                  decoration: BoxDecoration(
                                    color:
                                        AppDesign.travelGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppDesign.radiusSmall),
                                  ),
                                  child: Icon(
                                    Icons.location_city_rounded,
                                    size: 16,
                                    color: AppDesign.travelGreen,
                                  ),
                                ),
                                SizedBox(width: AppDesign.spacing8),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: AppDesign.bodyMedium.copyWith(
                                      color: AppDesign.secondaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 키워드 태그
                          Container(
                            margin: EdgeInsets.only(top: AppDesign.spacing4),
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDesign.spacing12,
                              vertical: AppDesign.spacing8,
                            ),
                            decoration: BoxDecoration(
                              color: keywordColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppDesign.radiusXL),
                              border: Border.all(
                                color: keywordColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.label_rounded,
                                  size: 14,
                                  color: keywordColor,
                                ),
                                SizedBox(width: AppDesign.spacing4),
                                Text(
                                  keyword,
                                  style: AppDesign.caption.copyWith(
                                    color: keywordColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppDesign.spacing8),
                    // 삭제 버튼
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius:
                            BorderRadius.circular(AppDesign.radiusSmall),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppDesign.radiusSmall),
                          onTap: onDelete,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // 하단 액션 영역 (옵션)
                Container(
                  margin: EdgeInsets.only(top: AppDesign.spacing16),
                  padding: EdgeInsets.only(top: AppDesign.spacing16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppDesign.borderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 14,
                        color: AppDesign.subtleText,
                      ),
                      SizedBox(width: AppDesign.spacing4),
                      Text(
                        '탭하여 상세 정보 보기',
                        style: AppDesign.caption.copyWith(
                          color: AppDesign.subtleText,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppDesign.subtleText,
                      ),
                    ],
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
