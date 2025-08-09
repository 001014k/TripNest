import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_markers_to_list_viewmodel.dart';
import '../design/app_design.dart'; // AppDesign 임포트 추가

class AddMarkersToListPage extends StatelessWidget {
  final String listId;

  const AddMarkersToListPage({required this.listId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddMarkersToListViewModel()
        ..loadMarkers()
        ..loadMarkersInList(listId),
      child: Scaffold(
        backgroundColor: AppDesign.primaryBg,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppDesign.backgroundGradient,
              boxShadow: AppDesign.softShadow,
            ),
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDesign.spacing16,
                  vertical: AppDesign.spacing12,
                ),
                child: Row(
                  children: [
                    // 뒤로가기 버튼
                    Container(
                      decoration: BoxDecoration(
                        color: AppDesign.cardBg,
                        borderRadius:
                            BorderRadius.circular(AppDesign.radiusSmall),
                        boxShadow: AppDesign.softShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppDesign.radiusSmall),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.all(AppDesign.spacing12),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: AppDesign.primaryText,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppDesign.spacing16),
                    // 타이틀
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '마커 추가하기',
                            style: AppDesign.headingMedium,
                          ),
                          SizedBox(height: AppDesign.spacing4),
                          Text(
                            '리스트에 추가할 장소를 선택하세요',
                            style: AppDesign.caption.copyWith(
                              color: AppDesign.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 정보 아이콘
                    Container(
                      padding: EdgeInsets.all(AppDesign.spacing8),
                      decoration: BoxDecoration(
                        gradient: AppDesign.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_location_alt_rounded,
                        color: AppDesign.whiteText,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Consumer<AddMarkersToListViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로딩 애니메이션
                    Container(
                      padding: EdgeInsets.all(AppDesign.spacing24),
                      decoration: BoxDecoration(
                        color: AppDesign.cardBg,
                        shape: BoxShape.circle,
                        boxShadow: AppDesign.elevatedShadow,
                      ),
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: AppDesign.spacing24),
                    Text(
                      '마커를 불러오는 중...',
                      style: AppDesign.bodyLarge.copyWith(
                        color: AppDesign.secondaryText,
                      ),
                    ),
                  ],
                ),
              );
            } else if (viewModel.error != null) {
              return Center(
                child: Container(
                  margin: EdgeInsets.all(AppDesign.spacing32),
                  padding: EdgeInsets.all(AppDesign.spacing24),
                  decoration: BoxDecoration(
                    color: AppDesign.cardBg,
                    borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
                    boxShadow: AppDesign.softShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppDesign.spacing16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade400,
                          size: 48,
                        ),
                      ),
                      SizedBox(height: AppDesign.spacing16),
                      Text(
                        '오류가 발생했습니다',
                        style: AppDesign.headingSmall,
                      ),
                      SizedBox(height: AppDesign.spacing8),
                      Text(
                        viewModel.error!,
                        style: AppDesign.bodyMedium.copyWith(
                          color: AppDesign.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppDesign.spacing24),
                      ElevatedButton.icon(
                        onPressed: () {
                          viewModel.loadMarkers();
                          viewModel.loadMarkersInList(listId);
                        },
                        icon: Icon(Icons.refresh_rounded),
                        label: Text('다시 시도'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesign.travelBlue,
                          foregroundColor: AppDesign.whiteText,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDesign.spacing24,
                            vertical: AppDesign.spacing12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDesign.radiusXL),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              final markers = viewModel.markers.toList();

              if (markers.isEmpty) {
                return Center(
                  child: Container(
                    margin: EdgeInsets.all(AppDesign.spacing32),
                    padding: EdgeInsets.all(AppDesign.spacing32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppDesign.spacing24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppDesign.travelBlue.withOpacity(0.1),
                                AppDesign.travelPurple.withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_off_outlined,
                            color: AppDesign.travelBlue,
                            size: 64,
                          ),
                        ),
                        SizedBox(height: AppDesign.spacing24),
                        Text(
                          '아직 마커가 없습니다',
                          style: AppDesign.headingSmall,
                        ),
                        SizedBox(height: AppDesign.spacing8),
                        Text(
                          '지도에서 새로운 장소를 추가해보세요',
                          style: AppDesign.bodyMedium.copyWith(
                            color: AppDesign.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  gradient: AppDesign.backgroundGradient,
                ),
                child: Column(
                  children: [
                    // 상단 정보 바
                    Container(
                      margin: EdgeInsets.all(AppDesign.spacing16),
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
                        borderRadius:
                            BorderRadius.circular(AppDesign.radiusMedium),
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
                          Expanded(
                            child: Text(
                              '${markers.length}개의 마커를 선택할 수 있습니다',
                              style: AppDesign.bodyMedium.copyWith(
                                color: AppDesign.travelBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDesign.spacing12,
                              vertical: AppDesign.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: AppDesign.travelBlue,
                              borderRadius:
                                  BorderRadius.circular(AppDesign.radiusXL),
                            ),
                            child: Text(
                              '${viewModel.markers.where((m) => viewModel.isMarkerInList(m, listId)).length}개 선택됨',
                              style: AppDesign.caption.copyWith(
                                color: AppDesign.whiteText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 마커 리스트
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDesign.spacing16,
                          vertical: AppDesign.spacing8,
                        ),
                        itemCount: markers.length,
                        itemBuilder: (context, index) {
                          final marker = markers[index];
                          final isSelected =
                              viewModel.isMarkerInList(marker, listId);

                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            margin:
                                EdgeInsets.only(bottom: AppDesign.spacing12),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          AppDesign.travelGreen
                                              .withOpacity(0.1),
                                          AppDesign.travelGreen
                                              .withOpacity(0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected ? null : AppDesign.cardBg,
                                borderRadius: BorderRadius.circular(
                                    AppDesign.radiusLarge),
                                border: Border.all(
                                  color: isSelected
                                      ? AppDesign.travelGreen.withOpacity(0.3)
                                      : AppDesign.borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppDesign.travelGreen
                                              .withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ]
                                    : AppDesign.softShadow,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                      AppDesign.radiusLarge),
                                  onTap: () => viewModel.addMarkerToList(
                                      marker, listId, context),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(AppDesign.spacing20),
                                    child: Row(
                                      children: [
                                        // 아이콘 컨테이너
                                        AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          padding: EdgeInsets.all(
                                              AppDesign.spacing12),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? AppDesign.greenGradient
                                                : null,
                                            color: isSelected
                                                ? null
                                                : AppDesign.lightGray,
                                            borderRadius: BorderRadius.circular(
                                                AppDesign.radiusMedium),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration:
                                                Duration(milliseconds: 300),
                                            child: Icon(
                                              isSelected
                                                  ? Icons.check_circle_rounded
                                                  : Icons
                                                      .add_location_alt_outlined,
                                              key: ValueKey(isSelected),
                                              color: isSelected
                                                  ? AppDesign.whiteText
                                                  : AppDesign.secondaryText,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: AppDesign.spacing16),
                                        // 텍스트 정보
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                marker.infoWindow.title ??
                                                    '제목 없음',
                                                style: AppDesign.bodyMedium
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppDesign.primaryText,
                                                ),
                                              ),
                                              if (marker.infoWindow.snippet !=
                                                      null &&
                                                  marker.infoWindow.snippet!
                                                      .isNotEmpty)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      top: AppDesign.spacing4),
                                                  child: Text(
                                                    marker.infoWindow.snippet!,
                                                    style: AppDesign.caption
                                                        .copyWith(
                                                      color: AppDesign
                                                          .secondaryText,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              if (isSelected)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      top: AppDesign.spacing8),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          AppDesign.spacing8,
                                                      vertical:
                                                          AppDesign.spacing4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppDesign.travelGreen,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppDesign
                                                                  .radiusXL),
                                                    ),
                                                    child: Text(
                                                      '선택됨',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            AppDesign.whiteText,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // 화살표 아이콘
                                        Container(
                                          padding: EdgeInsets.all(
                                              AppDesign.spacing8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppDesign.travelGreen
                                                    .withOpacity(0.1)
                                                : AppDesign.lightGray,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isSelected
                                                ? Icons.done_rounded
                                                : Icons
                                                    .arrow_forward_ios_rounded,
                                            size: 16,
                                            color: isSelected
                                                ? AppDesign.travelGreen
                                                : AppDesign.subtleText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
