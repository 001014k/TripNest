import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fluttertrip/views/markercreationscreen_view.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_markers_to_list_viewmodel.dart';
import '../viewmodels/markercreationscreen_viewmodel.dart';
import '../views/markerdetail_view.dart';
import '../viewmodels/mapsample_viewmodel.dart';
import '../design/app_design.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

class MapSampleView extends StatefulWidget {
  final MarkerId? initialMarkerId;

  const MapSampleView({Key? key, this.initialMarkerId}) : super(key: key);

  @override
  _MapSampleViewState createState() => _MapSampleViewState();
}

class _MapSampleViewState extends State<MapSampleView> {
  late MapSampleViewModel viewModel;
  final ZoomDrawerController zoomDrawerController = ZoomDrawerController();
  late GoogleMapController _controller;
  Map<MarkerId, String> _markerKeywords = {};
  TextEditingController _searchController = TextEditingController();
  bool _isMapInitialized = false;
  final Map<String, String> keywordMarkerImages = {
    '카페': 'assets/cafe_marker.png',
    '호텔': 'assets/hotel_marker.png',
    '사진': 'assets/photo_marker.png',
    '음식점': 'assets/restaurant_marker.png',
    '전시회': 'assets/exhibition_marker.png',
  };
  LatLng? _pendingLatLng;
  List<Marker> bookmarkedMarkers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    viewModel = context.read<MapSampleViewModel>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<MapSampleViewModel>();
      await viewModel.loadMarkers();

      viewModel.onMarkerTappedCallback = (marker) {
        String keyword =
            viewModel.getKeywordByMarkerId(marker.markerId.value) ?? '';
        final selectedListId =
            context.read<MapSampleViewModel>().selectedListId;

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => Container(
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDesign.radiusLarge)),
              boxShadow: AppDesign.elevatedShadow,
            ),
            child: MarkerInfoBottomSheet(
              marker: marker,
              keyword: keyword.isNotEmpty ? keyword : '',
              listId: selectedListId ?? 'default_list_id',
              onSave: (marker, keyword, address) async {
                // 저장 처리
              },
              onDelete: (m) {
                // 삭제 처리
              },
              onBookmark: (m) {
                // 북마크 처리
              },
              navigateToMarkerDetailPage: (context, m) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MarkerDetailView(
                      marker: m,
                      keyword: '',
                    ),
                  ),
                );
              },
            ),
          ),
        );
      };

      final initialMarkerId = (widget as MapSampleView).initialMarkerId;
      if (initialMarkerId != null) {
        await viewModel.onMarkerTapped(initialMarkerId);
      }
    });
  }

  void _navigateToMarkerDetailPage(BuildContext context, Marker marker) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkerDetailView(
          marker: marker,
          keyword: _markerKeywords[marker.markerId] ?? 'default',
        ),
      ),
    );

    if (result == true) {
      context.read<MapSampleViewModel>().loadMarkers();
    }
  }

  void _onMapTapped(BuildContext context, LatLng latLng) async {
    final bool? shouldAddMarker = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppDesign.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.all(AppDesign.spacing16),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppDesign.spacing8),
                decoration: BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
                child: Icon(
                  Icons.add_location_alt_outlined,
                  color: AppDesign.whiteText,
                  size: 24,
                ),
              ),
              SizedBox(width: AppDesign.spacing12),
              Text(
                '마커 추가',
                style: AppDesign.headingSmall,
              ),
            ],
          ),
          content: Text(
            '이 위치에 마커를 추가할까요?',
            style: AppDesign.bodyLarge,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDesign.spacing20,
                      vertical: AppDesign.spacing12,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
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
                    gradient: AppDesign.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                    boxShadow: AppDesign.glowShadow,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesign.radiusSmall),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDesign.spacing24,
                        vertical: AppDesign.spacing12,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      '마커 추가',
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

    if (shouldAddMarker == true) {
      setState(() {
        _pendingLatLng = latLng;
      });
      _navigateToMarkerCreationScreen(context, latLng);
    }
  }

  void _navigateToMarkerCreationScreen(
      BuildContext context, LatLng latLng) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) =>
            MarkerCreationScreen(initialLatLng: latLng),
      ),
    );

    if (result != null && _pendingLatLng != null) {
      final keyword = result['keyword'] ?? 'default';
      final listId = result['listId'];
      final address = result['address'] ?? '';
      context.read<MapSampleViewModel>().addMarker(
            title: result['title'],
            snippet: result['snippet'],
            position: _pendingLatLng!,
            keyword: keyword,
            address: address,
            listId: listId,
            onTapCallback: (markerId) {
              context.read<MapSampleViewModel>().onMarkerTapped(markerId);
            },
          );
      _pendingLatLng = null;
    }
  }

  void _bookmarkLocation(BuildContext context, Marker marker) {
    setState(() {
      bookmarkedMarkers.add(marker);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('북마크에 추가되었습니다.'),
        backgroundColor: AppDesign.travelGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
        ),
      ),
    );
  }

  void _showMarkerInfoBottomSheet(
    BuildContext context,
    Marker marker,
    Function(Marker) onDelete,
    String keyword,
    String listId,
  ) {
    print('showMarkerInfoBottomSheet called for marker: ${marker.markerId}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: AppDesign.cardBg,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDesign.radiusLarge)),
          boxShadow: AppDesign.elevatedShadow,
        ),
        padding: EdgeInsets.all(AppDesign.spacing20),
        child: MarkerInfoBottomSheet(
          marker: marker,
          keyword: keyword,
          listId: listId,
          onSave: (updatedMarker, keyword, address) async {
            final markerImagePath =
                keywordMarkerImages[keyword] ?? 'assets/default_marker.png';
            context.read<MarkerCreationScreenViewModel>().saveMarker(
                  marker: updatedMarker,
                  keyword: keyword,
                  markerImagePath: markerImagePath,
                  listId: listId,
                  address: address,
                );
          },
          onDelete: onDelete,
          onBookmark: (marker) {
            _bookmarkLocation(context, marker);
          },
          navigateToMarkerDetailPage: _navigateToMarkerDetailPage,
        ),
      ),
    );
  }

  void showUserLists(BuildContext context) async {
    List<Map<String, dynamic>> userLists =
        await context.read<MapSampleViewModel>().getUserLists();
    if (!mounted) return;

    if (userLists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장된 리스트가 없습니다'),
          backgroundColor: AppDesign.travelOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDesign.radiusLarge)),
      ),
      backgroundColor: AppDesign.cardBg,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: AppDesign.backgroundGradient,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDesign.radiusLarge)),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDesign.spacing20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: EdgeInsets.only(bottom: AppDesign.spacing20),
                  decoration: BoxDecoration(
                    color: AppDesign.borderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  '여행 리스트 선택',
                  style: AppDesign.headingMedium,
                ),
                SizedBox(height: AppDesign.spacing20),
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: userLists.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: AppDesign.spacing12),
                  itemBuilder: (context, index) {
                    final list = userLists[index];
                    final listName = list['name'] ?? '이름 없음';

                    return Container(
                      decoration: BoxDecoration(
                        color: AppDesign.cardBg,
                        borderRadius:
                            BorderRadius.circular(AppDesign.radiusMedium),
                        boxShadow: AppDesign.softShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppDesign.radiusMedium),
                          onTap: () {
                            Navigator.pop(context);
                            showMarkersForSelectedList(userLists[index]['id']);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(AppDesign.spacing16),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(AppDesign.spacing12),
                                  decoration: BoxDecoration(
                                    gradient: AppDesign.primaryGradient,
                                    borderRadius: BorderRadius.circular(
                                        AppDesign.radiusSmall),
                                  ),
                                  child: Icon(
                                    Icons.map_outlined,
                                    color: AppDesign.whiteText,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: AppDesign.spacing16),
                                Expanded(
                                  child: Text(
                                    listName,
                                    style: AppDesign.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppDesign.secondaryText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: AppDesign.spacing20),
                Divider(thickness: 1, color: AppDesign.borderColor),
                SizedBox(height: AppDesign.spacing12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppDesign.borderColor),
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(AppDesign.radiusMedium),
                      onTap: () {
                        context.read<MapSampleViewModel>().loadMarkers();
                        context.read<MapSampleViewModel>().clearPolylines();
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.all(AppDesign.spacing16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded,
                                color: AppDesign.travelOrange),
                            SizedBox(width: AppDesign.spacing12),
                            Text(
                              '초기화',
                              style: AppDesign.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppDesign.primaryText,
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
        );
      },
    );
  }

  void showMarkersForSelectedList(String listId) async {
    if (!mounted) return;
    final viewModel = context.read<MapSampleViewModel>();
    await viewModel.loadMarkersForList(listId);

    if (!mounted) return;

    final markers = viewModel.filteredMarkers.toList();

    if (markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: AppDesign.spacing8),
              Text('해당 리스트에 마커가 없습니다'),
            ],
          ),
          backgroundColor: AppDesign.travelOrange,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(AppDesign.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          ),
          elevation: 6,
        ),
      );
      return;
    }

    Map<String, Map<String, String>> markerDetailsMap = {};
    await Future.wait(
      markers.map((marker) async {
        final details = await viewModel.fetchMarkerDetail(marker.markerId.value);
        markerDetailsMap[marker.markerId.value] = details;
      }),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppDesign.cardBg,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppDesign.radiusLarge),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 헤더 섹션
                      Container(
                        padding: EdgeInsets.all(AppDesign.spacing20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppDesign.primaryBg,
                              AppDesign.secondaryBg,
                            ],
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppDesign.radiusLarge),
                          ),
                        ),
                        child: Column(
                          children: [
                            // 드래그 핸들
                            Container(
                              width: 40,
                              height: 4,
                              margin: EdgeInsets.only(bottom: AppDesign.spacing16),
                              decoration: BoxDecoration(
                                color: AppDesign.borderColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // 타이틀과 카운트
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '경로 순서',
                                      style: AppDesign.headingMedium,
                                    ),
                                    SizedBox(height: AppDesign.spacing4),
                                    Text(
                                      '${markers.length}개의 장소',
                                      style: AppDesign.caption.copyWith(
                                        color: AppDesign.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppDesign.spacing12,
                                    vertical: AppDesign.spacing8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppDesign.primaryGradient,
                                    borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.route_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: AppDesign.spacing4),
                                      Text(
                                        '경로 보기',
                                        style: AppDesign.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppDesign.spacing16),
                            // 안내 메시지 카드
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(AppDesign.spacing12),
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
                                  Container(
                                    padding: EdgeInsets.all(AppDesign.spacing8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.touch_app_rounded,
                                      color: AppDesign.travelBlue,
                                      size: 18,
                                    ),
                                  ),
                                  SizedBox(width: AppDesign.spacing12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '드래그하여 순서 변경',
                                          style: AppDesign.bodyMedium.copyWith(
                                            color: AppDesign.travelBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '카드를 탭하면 지도에서 위치를 확인할 수 있어요',
                                          style: AppDesign.caption.copyWith(
                                            color: AppDesign.travelBlue.withOpacity(0.8),
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
                      ),
                      // 마커 리스트
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppDesign.primaryBg,
                          ),
                          child: Consumer<MapSampleViewModel>(
                            builder: (context, viewModel, _) {
                              return ReorderableListView.builder(
                                scrollController: scrollController,
                                padding: EdgeInsets.fromLTRB(
                                  AppDesign.spacing16,
                                  AppDesign.spacing8,
                                  AppDesign.spacing16,
                                  AppDesign.spacing80,
                                ),
                                itemCount: viewModel.orderedMarkers.length,
                                onReorder: (int oldIndex, int newIndex) async {
                                  HapticFeedback.lightImpact(); // 햅틱 피드백 추가
                                  await viewModel.reorderMarkers(
                                    oldIndex,
                                    newIndex,
                                    listId,
                                    context.read<AddMarkersToListViewModel>(),
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final marker = viewModel.orderedMarkers[index];
                                  final details = markerDetailsMap[marker.markerId.value] ?? {
                                    'title': '제목 없음',
                                    'keyword': '키워드 없음',
                                    'address': '주소 없음',
                                  };

                                  final title = details['title']!;
                                  final keyword = details['keyword']!;
                                  final address = details['address'] ?? '';
                                  final orderNumber = index + 1;

                                  // 키워드별 색상 매핑
                                  final keywordColors = {
                                    '카페': AppDesign.travelOrange,
                                    '호텔': AppDesign.travelBlue,
                                    '사진': AppDesign.travelPurple,
                                    '음식점': AppDesign.travelGreen,
                                    '전시회': AppDesign.sunsetGradientStart,
                                  };
                                  final keywordColor = keywordColors[keyword] ?? AppDesign.travelBlue;

                                  return Container(
                                    key: ValueKey(marker.markerId.value),
                                    margin: EdgeInsets.only(bottom: AppDesign.spacing12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          Navigator.pop(context);
                                          viewModel.onMarkerTapped(marker.markerId);
                                        },
                                        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppDesign.cardBg,
                                            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
                                            border: Border.all(
                                              color: AppDesign.borderColor.withOpacity(0.5),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: keywordColor.withOpacity(0.08),
                                                blurRadius: 12,
                                                offset: Offset(0, 4),
                                              ),
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(AppDesign.spacing16),
                                            child: Row(
                                              children: [
                                                // 드래그 핸들과 순서 번호
                                                Column(
                                                  children: [
                                                    Icon(
                                                      Icons.drag_indicator_rounded,
                                                      color: AppDesign.subtleText,
                                                      size: 20,
                                                    ),
                                                    Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [
                                                            keywordColor,
                                                            keywordColor.withOpacity(0.7),
                                                          ],
                                                        ),
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: keywordColor.withOpacity(0.3),
                                                            blurRadius: 8,
                                                            offset: Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          orderNumber.toString(),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(width: AppDesign.spacing16),
                                                // 콘텐츠
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              title,
                                                              style: AppDesign.bodyMedium.copyWith(
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 15,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          SizedBox(width: AppDesign.spacing8),
                                                          Container(
                                                            padding: EdgeInsets.symmetric(
                                                              horizontal: AppDesign.spacing10,
                                                              vertical: AppDesign.spacing4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: keywordColor.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                                                              border: Border.all(
                                                                color: keywordColor.withOpacity(0.2),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                  _getKeywordIcon(keyword),
                                                                  size: 12,
                                                                  color: keywordColor,
                                                                ),
                                                                SizedBox(width: AppDesign.spacing4),
                                                                Text(
                                                                  keyword,
                                                                  style: TextStyle(
                                                                    color: keywordColor,
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (address.isNotEmpty) ...[
                                                        SizedBox(height: AppDesign.spacing8),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.location_on_outlined,
                                                              size: 14,
                                                              color: AppDesign.subtleText,
                                                            ),
                                                            SizedBox(width: AppDesign.spacing4),
                                                            Expanded(
                                                              child: Text(
                                                                address,
                                                                style: AppDesign.caption.copyWith(
                                                                  color: AppDesign.secondaryText,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                // 화살표
                                                Container(
                                                  padding: EdgeInsets.all(AppDesign.spacing8),
                                                  decoration: BoxDecoration(
                                                    color: AppDesign.lightGray,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_forward_ios_rounded,
                                                    color: AppDesign.secondaryText,
                                                    size: 14,
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
                              );
                            },
                          ),
                        ),
                      ),
                      // 하단 액션 버튼
                      Container(
                        padding: EdgeInsets.all(AppDesign.spacing20),
                        decoration: BoxDecoration(
                          color: AppDesign.cardBg,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppDesign.borderColor,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                                      onTap: () {
                                        Navigator.pop(context);
                                        showUserLists(context);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: AppDesign.spacing16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.arrow_back_rounded,
                                              color: AppDesign.secondaryText,
                                              size: 20,
                                            ),
                                            SizedBox(width: AppDesign.spacing8),
                                            Text(
                                              '뒤로가기',
                                              style: AppDesign.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: AppDesign.spacing12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppDesign.primaryGradient,
                                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                                    boxShadow: AppDesign.glowShadow,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                                      onTap: () {
                                        Navigator.pop(context);
                                        // 경로 최적화 또는 네비게이션 시작
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                                                SizedBox(width: AppDesign.spacing8),
                                                Text('경로 안내를 시작합니다'),
                                              ],
                                            ),
                                            backgroundColor: AppDesign.travelGreen,
                                            behavior: SnackBarBehavior.floating,
                                            margin: EdgeInsets.all(AppDesign.spacing16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: AppDesign.spacing16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.navigation_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: AppDesign.spacing8),
                                            Text(
                                              '경로 시작',
                                              style: AppDesign.bodyMedium.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
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
                );
              },
            );
          },
        );
      },
    );
  }

// 키워드별 아이콘 헬퍼 함수
  IconData _getKeywordIcon(String keyword) {
    switch (keyword) {
      case '카페':
        return Icons.coffee_rounded;
      case '호텔':
        return Icons.hotel_rounded;
      case '사진':
        return Icons.camera_alt_rounded;
      case '음식점':
        return Icons.restaurant_rounded;
      case '전시회':
        return Icons.museum_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  // 뒤로가기 / 홈 이동 시 안전 처리
  void _onBackPressed() {
    viewModel.detachMap(); // 안전 detach
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> keywords =
        context.read<MapSampleViewModel>().keywordIcons.keys.toList();
    final searchResults = context.watch<MapSampleViewModel>().searchResults;
    final selectedListId = context.read<MapSampleViewModel>().selectedListId;

    return Scaffold(
      backgroundColor: AppDesign.primaryBg,
      body: Stack(
        children: [
          Consumer<MapSampleViewModel>(
            builder: (context, viewModel, child) {
              return GoogleMap(
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer()),
                },
                onMapCreated: (GoogleMapController controller) async {
                  if (_isMapInitialized) return;
                  _isMapInitialized = true;

                  viewModel.controller = controller;
                  await viewModel.loadMarkers();
                  await viewModel.applyMarkersToCluster(controller);
                  controller.setMapStyle(viewModel.mapStyle);

                  if (viewModel.currentLocation != null) {
                    controller!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(viewModel.currentLocation!.latitude!,
                              viewModel.currentLocation!.longitude!),
                          zoom: 15,
                        ),
                      ),
                    );
                  }
                  // iOS일 경우 네이티브 채널 안정화를 위해 약간 지연
                  if (Platform.isIOS) {
                    await Future.delayed(const Duration(milliseconds: 300));
                  }

                  // GoogleMap 위젯 attach 후 ClusterManager 실행
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await viewModel.applyMarkersToCluster(controller);
                  });
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    viewModel.currentLocation?.latitude ??
                        viewModel.seoulCityHall.latitude,
                    viewModel.currentLocation?.longitude ??
                        viewModel.seoulCityHall.longitude,
                  ),
                  zoom: 15.0,
                ),
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: viewModel.displayMarkers,
                polylines: {
                  if (viewModel.polygonPoints.length >= 2)
                    Polyline(
                      polylineId: PolylineId('ordered_polyline'),
                      points: viewModel.polygonPoints,
                      color: AppDesign.travelBlue,
                      width: 5,
                    ),
                },
                onTap: (latLng) => _onMapTapped(context, latLng),
                onCameraMove: (position) {
                  viewModel.onCameraMove(position);
                  viewModel.clusterManager?.onCameraMove(position);
                },
                onCameraIdle: () {
                  viewModel.clusterManager?.updateMap();
                },
              );
            },
          ),
          // 검색창 (지도 위) - 리디자인
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Builder(
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: AppDesign.cardBg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                  boxShadow: AppDesign.elevatedShadow,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppDesign.cardBg,
                        AppDesign.cardBg.withOpacity(0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                    border: Border.all(
                      color: AppDesign.borderColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDesign.spacing8,
                    vertical: AppDesign.spacing4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(AppDesign.spacing8),
                          decoration: BoxDecoration(
                            gradient: AppDesign.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: AppDesign.whiteText,
                            size: 20,
                          ),
                        ),
                        onPressed: _onBackPressed,
                      ),
                      SizedBox(width: AppDesign.spacing8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: '어디로 여행을 떠나시나요?',
                            hintStyle: AppDesign.bodyMedium.copyWith(
                              color: AppDesign.subtleText,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppDesign.spacing12,
                              vertical: AppDesign.spacing12,
                            ),
                          ),
                          style: AppDesign.bodyMedium.copyWith(
                            color: AppDesign.primaryText,
                          ),
                          onSubmitted: context
                              .read<MapSampleViewModel>()
                              .onSearchSubmitted,
                          onChanged: context
                              .read<MapSampleViewModel>()
                              .updateSearchResults,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(AppDesign.spacing8),
                          decoration: BoxDecoration(
                            color: AppDesign.travelBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: AppDesign.travelBlue,
                          ),
                        ),
                        onPressed: () => context
                            .read<MapSampleViewModel>()
                            .onSearchSubmitted(_searchController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 지도 초기화 로딩 인디케이터
          if (!_isMapInitialized)
            Positioned.fill(
              child: Container(
                color: AppDesign.primaryBg.withOpacity(0.9),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
                      ),
                      SizedBox(height: AppDesign.spacing16),
                      Text(
                        "지도를 불러오는 중...",
                        style: AppDesign.bodyLarge.copyWith(
                          color: AppDesign.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 키워드 필터 버튼들 - 리디자인
          Consumer<MapSampleViewModel>(builder: (context, viewModel, child) {
            return Positioned(
              top: 140.0,
              left: 0,
              right: 0,
              child: Container(
                height: 48.0,
                padding: EdgeInsets.symmetric(horizontal: AppDesign.spacing12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: keywords.length,
                  itemBuilder: (context, index) {
                    final keyword = keywords[index];
                    final icon = viewModel.keywordIcons[keyword];
                    final isActive = viewModel.activeKeywords.contains(keyword);

                    return Container(
                      margin: EdgeInsets.only(
                        left: index == 0
                            ? AppDesign.spacing4
                            : AppDesign.spacing8,
                        right: index == keywords.length - 1
                            ? AppDesign.spacing4
                            : 0,
                      ),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isActive ? AppDesign.primaryGradient : null,
                          color: isActive ? null : AppDesign.cardBg,
                          borderRadius:
                              BorderRadius.circular(AppDesign.radiusXL),
                          boxShadow: isActive
                              ? AppDesign.glowShadow
                              : AppDesign.softShadow,
                          border: isActive
                              ? null
                              : Border.all(
                                  color: AppDesign.borderColor,
                                  width: 1,
                                ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(AppDesign.radiusXL),
                            onTap: () {
                              context
                                  .read<MapSampleViewModel>()
                                  .toggleKeyword(keyword);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDesign.spacing16,
                                vertical: AppDesign.spacing12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    color: isActive
                                        ? AppDesign.whiteText
                                        : AppDesign.secondaryText,
                                    size: 18,
                                  ),
                                  SizedBox(width: AppDesign.spacing8),
                                  Text(
                                    keyword,
                                    style: AppDesign.bodyMedium.copyWith(
                                      color: isActive
                                          ? AppDesign.whiteText
                                          : AppDesign.primaryText,
                                      fontWeight: FontWeight.w600,
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
            );
          }),
          // 플로팅 액션 버튼들 - 리디자인
          Positioned(
            bottom: 40,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: AppDesign.greenGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppDesign.elevatedShadow,
                  ),
                  child: FloatingActionButton(
                    heroTag: 'btn_location',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.my_location,
                                  color: AppDesign.whiteText, size: 20),
                              SizedBox(width: AppDesign.spacing8),
                              Text(
                                "현재 위치로 이동합니다",
                                style: AppDesign.bodyMedium
                                    .copyWith(color: AppDesign.whiteText),
                              ),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                          backgroundColor: AppDesign.travelGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDesign.radiusSmall),
                          ),
                        ),
                      );
                      context
                          .read<MapSampleViewModel>()
                          .moveToCurrentLocation();
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Icon(Icons.my_location_rounded,
                        color: AppDesign.whiteText),
                  ),
                ),
                SizedBox(height: AppDesign.spacing16),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppDesign.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppDesign.elevatedShadow,
                  ),
                  child: FloatingActionButton(
                    heroTag: 'btn_list',
                    onPressed: () => showUserLists(context),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Icon(Icons.list_rounded, color: AppDesign.whiteText),
                  ),
                ),
              ],
            ),
          ),
          // 검색 결과 바텀시트 - 리디자인
          if (searchResults.isNotEmpty) ...[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Dismissible(
                key: ValueKey(
                    'searchResultsBottomSheet_${searchResults.length}'),
                direction: DismissDirection.down,
                onDismissed: (direction) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<MapSampleViewModel>().clearSearchResults();
                  });
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppDesign.backgroundGradient,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppDesign.radiusLarge)),
                    boxShadow: AppDesign.elevatedShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin:
                            EdgeInsets.symmetric(vertical: AppDesign.spacing12),
                        decoration: BoxDecoration(
                          color: AppDesign.borderColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDesign.spacing20),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppDesign.travelBlue),
                            SizedBox(width: AppDesign.spacing8),
                            Text(
                              '검색 결과',
                              style: AppDesign.headingSmall,
                            ),
                            Spacer(),
                            Text(
                              '${searchResults.length}개',
                              style: AppDesign.caption.copyWith(
                                color: AppDesign.travelBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppDesign.spacing12),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppDesign.spacing16),
                          shrinkWrap: true,
                          itemCount: context
                              .watch<MapSampleViewModel>()
                              .searchResults
                              .length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: AppDesign.spacing8),
                          itemBuilder: (context, index) {
                            final marker = context
                                .watch<MapSampleViewModel>()
                                .searchResults[index];
                            final keyword = _markerKeywords[marker.markerId];
                            final icon = context
                                .watch<MapSampleViewModel>()
                                .keywordIcons[keyword];

                            return Container(
                              decoration: BoxDecoration(
                                color: AppDesign.cardBg,
                                borderRadius: BorderRadius.circular(
                                    AppDesign.radiusMedium),
                                boxShadow: AppDesign.softShadow,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                      AppDesign.radiusMedium),
                                  onTap: () {
                                    _controller?.animateCamera(
                                      CameraUpdate.newLatLng(marker.position),
                                    );
                                    _showMarkerInfoBottomSheet(
                                      context,
                                      marker,
                                      (Marker markerToDelete) {
                                        // 마커 삭제 로직
                                      },
                                      keyword ?? '',
                                      selectedListId ?? '',
                                    );
                                  },
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(AppDesign.spacing16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                              AppDesign.spacing8),
                                          decoration: BoxDecoration(
                                            gradient: AppDesign.sunsetGradient,
                                            borderRadius: BorderRadius.circular(
                                                AppDesign.radiusSmall),
                                          ),
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            color: AppDesign.whiteText,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: AppDesign.spacing12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                marker.infoWindow.title ??
                                                    'Untitled',
                                                style: AppDesign.bodyMedium
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (marker.infoWindow.snippet !=
                                                  null)
                                                Text(
                                                  marker.infoWindow.snippet!,
                                                  style: AppDesign.caption,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (keyword != null &&
                                            keyword.isNotEmpty)
                                          Container(
                                            margin: EdgeInsets.only(
                                                left: AppDesign.spacing8),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: AppDesign.spacing12,
                                              vertical: AppDesign.spacing8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppDesign.travelBlue
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppDesign.radiusXL),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(icon,
                                                    color: AppDesign.travelBlue,
                                                    size: 16),
                                                SizedBox(
                                                    width: AppDesign.spacing4),
                                                Text(
                                                  keyword,
                                                  style: AppDesign.caption
                                                      .copyWith(
                                                    color: AppDesign.travelBlue,
                                                    fontWeight: FontWeight.w600,
                                                  ),
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
                          },
                        ),
                      ),
                      SizedBox(height: AppDesign.spacing16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// MarkerInfoBottomSheet 위젯 리디자인
class MarkerInfoBottomSheet extends StatefulWidget {
  final Marker marker;
  final Future<void> Function(Marker, String, String) onSave;
  final Function(Marker) onDelete;
  final Function(Marker) onBookmark;
  final String keyword;
  final Function(BuildContext, Marker) navigateToMarkerDetailPage;
  final String listId;

  const MarkerInfoBottomSheet({
    required this.marker,
    required this.onSave,
    required this.onDelete,
    required this.onBookmark,
    required this.keyword,
    required this.navigateToMarkerDetailPage,
    required this.listId,
  });

  @override
  State<MarkerInfoBottomSheet> createState() => _MarkerInfoBottomSheetState();
}

class _MarkerInfoBottomSheetState extends State<MarkerInfoBottomSheet> {
  String _title = '제목 로딩 중...';
  String _address = '';
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _fetchMarkerDetail();
  }

  Future<void> _fetchMarkerDetail() async {
    final viewModel = context.read<MapSampleViewModel>();
    final result =
        await viewModel.fetchMarkerDetail(widget.marker.markerId.value);

    setState(() {
      _title = result['title'] ?? '제목 없음';
      _address = result['address'] ?? '주소 없음';
      _keyword = result['keyword'] ?? '키워드 없음';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDesign.spacing24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 50,
            height: 5,
            margin: EdgeInsets.only(bottom: AppDesign.spacing20),
            decoration: BoxDecoration(
              color: AppDesign.borderColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.navigateToMarkerDetailPage(context, widget.marker);
            },
            child: Container(
              padding: EdgeInsets.all(AppDesign.spacing16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppDesign.travelBlue.withOpacity(0.05),
                    AppDesign.travelPurple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                border: Border.all(
                  color: AppDesign.travelBlue.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppDesign.spacing8),
                        decoration: BoxDecoration(
                          gradient: AppDesign.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppDesign.radiusSmall),
                        ),
                        child: Icon(
                          Icons.place_rounded,
                          color: AppDesign.whiteText,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: AppDesign.spacing12),
                      Expanded(
                        child: Text(
                          _title,
                          style: AppDesign.headingSmall,
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        color: AppDesign.travelBlue,
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: AppDesign.spacing8),
                  Text(
                    '탭하여 상세 정보 보기',
                    style: AppDesign.caption.copyWith(
                      color: AppDesign.travelBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppDesign.spacing16),

          // 주소 정보
          if (_address.isNotEmpty)
            Container(
              padding: EdgeInsets.all(AppDesign.spacing16),
              decoration: BoxDecoration(
                color: AppDesign.lightGray,
                borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppDesign.spacing8),
                    decoration: BoxDecoration(
                      color: AppDesign.travelGreen.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDesign.radiusSmall),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: AppDesign.travelGreen,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppDesign.spacing12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '주소',
                          style: AppDesign.caption.copyWith(
                            color: AppDesign.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppDesign.spacing4),
                        Text(
                          _address,
                          style: AppDesign.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: AppDesign.spacing12),

          // 키워드 정보
          Container(
            padding: EdgeInsets.all(AppDesign.spacing16),
            decoration: BoxDecoration(
              color: AppDesign.lightGray,
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppDesign.spacing8),
                  decoration: BoxDecoration(
                    color: AppDesign.travelPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                  ),
                  child: Icon(
                    Icons.label_outline_rounded,
                    color: AppDesign.travelPurple,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppDesign.spacing12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '카테고리',
                      style: AppDesign.caption.copyWith(
                        color: AppDesign.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppDesign.spacing4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDesign.spacing12,
                        vertical: AppDesign.spacing8,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppDesign.primaryGradient,
                        borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                      ),
                      child: Text(
                        _keyword.isNotEmpty ? _keyword : '기본 카테고리',
                        style: AppDesign.bodyMedium.copyWith(
                          color: AppDesign.whiteText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
