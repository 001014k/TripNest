import '../widgets/selected_location_sheet.dart';
import '../widgets/address_photo_preview.dart';
import '../widgets/place_keyword_icon.dart';
import '../navigation/app_page_route.dart';
import '../widgets/app_overlays.dart';
import '../widgets/map_keyword_sheet.dart';
import '../widgets/map_trip_list_sheet.dart';
import '../widgets/tripnest_navigation.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fluttertrip/views/markercreationscreen_view.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_markers_to_list_viewmodel.dart';
import '../views/markerdetail_view.dart';
import '../viewmodels/mapsample_viewmodel.dart';
import '../design/app_design.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'chat_recommendation_view.dart';

/// A focused map opened from a detail page owns its controller so that closing
/// it does not detach the retained map tab's controller or callbacks.
class MapPreviewView extends StatelessWidget {
  const MapPreviewView({super.key, this.initialMarkerId, this.initialListId});
  final MarkerId? initialMarkerId;
  final String? initialListId;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => MapSampleViewModel(),
        child: MapSampleView(
            initialMarkerId: initialMarkerId, initialListId: initialListId),
      );
}

class MapSampleView extends StatefulWidget {
  final MarkerId? initialMarkerId;
  final String? initialListId;

  const MapSampleView({super.key, this.initialMarkerId, this.initialListId});

  @override
  State<MapSampleView> createState() => _MapSampleViewState();
}

class _MapSampleViewState extends State<MapSampleView> {
  late MapSampleViewModel _viewModel;
  final ZoomDrawerController zoomDrawerController = ZoomDrawerController();
  GoogleMapController? _controller; // late를 추가하면 오류가 뜨고 삭제하면 해당 위치에 대한 결과가 뜸
  final Map<MarkerId, String> _markerKeywords = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isMapInitialized = false;
  bool _hasLoadedMarkers = false;
  final Map<String, String> keywordMarkerImages = {
    '카페': 'assets/cafe_marker.png',
    '호텔': 'assets/hotel_marker.png',
    '사진': 'assets/photo_marker.png',
    '음식점': 'assets/restaurant_marker.png',
    '전시회': 'assets/exhibition_marker.png',
  };
  LatLng? _pendingLatLng;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _viewModel = context.read<MapSampleViewModel>();

    // 검색 마커 클릭 처리
    _viewModel.onSearchMarkerTapped = (Marker marker) async {
      debugPrint("✅ [Search Marker Tap] 클릭됨 → ${marker.markerId.value}");

      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        builder: (sheet) => SelectedLocationSheet(
          marker: marker,
          metadata: _viewModel.searchPlaceMetadata[marker.markerId.value],
          currentLocation: _viewModel.currentLocation,
          onAdd: () => Navigator.pop(sheet, true),
        ),
      );
      if (!mounted || confirmed != true) return;
      final result = await Navigator.push(
        context,
        AppPageRoute(
          motion: AppMotion.editor,
          builder: (context) => MarkerCreationScreen(
            initialLatLng: marker.position,
            initialTitle: marker.infoWindow.title,
            initialAddress: marker.infoWindow.snippet,
          ),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        if (!mounted) return;
        final saved = await _viewModel.addMarker(
          title: result['title'],
          snippet: result['snippet'],
          position: marker.position,
          keyword: result['keyword'],
          address: result['address'] ?? '',
          listId: result['listId'],
          onTapCallback: (id) => _viewModel.onMarkerTapped(id),
        );

        if (!mounted) return;
        if (!saved) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('마커를 저장하지 못했어요. 다시 시도해주세요.')));
          return;
        }
        _viewModel.clearSearchResults();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('마커가 저장되었습니다'),
            backgroundColor: AppDesign.travelGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
            ),
          ),
        );
      }
    };

    // onSearchCompleted를 이렇게 변경하세요
    _viewModel.onSearchCompleted = (List<Marker> searchMarkers) async {
      if (searchMarkers.isEmpty) return;

      debugPrint("✅ 검색 완료 - ${searchMarkers.length}개 마커 → 카메라 이동 시도");

      final positions = searchMarkers.map((m) => m.position).toList();
      if (positions.isEmpty) return;

      LatLng southwest = positions.reduce((a, b) => LatLng(
            a.latitude < b.latitude ? a.latitude : b.latitude,
            a.longitude < b.longitude ? a.longitude : b.longitude,
          ));

      LatLng northeast = positions.reduce((a, b) => LatLng(
            a.latitude > b.latitude ? a.latitude : b.latitude,
            a.longitude > b.longitude ? a.longitude : b.longitude,
          ));

      final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

      // controller가 준비될 때까지 기다리는 함수
      Future<void> moveCamera() async {
        if (_controller != null) {
          try {
            await _controller!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 120.0),
            );
            debugPrint("✅ 카메라 이동 성공!");
            return;
          } catch (e) {
            debugPrint("❌ animateCamera 실패: $e");
          }
        }

        // controller가 아직 null이면 GoogleMap이 완전히 빌드될 때까지 대기
        debugPrint("⏳ controller null → GoogleMap 빌드 대기");

        // GoogleMap이 onMapCreated 될 때까지 최대 1.5초 대기
        int attempts = 0;
        while (_controller == null && attempts < 15) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }

        if (_controller != null) {
          try {
            await _controller!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 120.0),
            );
            debugPrint("✅ 대기 후 카메라 이동 성공!");
          } catch (e) {
            debugPrint("❌ 대기 후에도 이동 실패: $e");
          }
        } else {
          debugPrint("❌ 최종 실패: controller가 초기화되지 않음");

          // 최후의 수단: 첫 번째 마커 위치로 이동
          if (searchMarkers.isNotEmpty) {
            _controller?.animateCamera(
              CameraUpdate.newLatLngZoom(searchMarkers.first.position, 14.0),
            );
          }
        }
      }

      // 이동 실행
      moveCamera();
    };
  }

  @override
  void dispose() {
    // dispose 단계에서는 비활성화된 context로 Provider를 조회하지 않습니다.
    _searchController.dispose();
    _viewModel.detachMap();
    _viewModel.onSearchMarkerTapped = null;
    _viewModel.onSearchCompleted = null;

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<MapSampleViewModel>();
      await viewModel.loadMarkers();

      viewModel.onMarkerTappedCallback = (marker) {
        String keyword = viewModel.getKeywordByMarkerId(marker.markerId.value);
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
              navigateToMarkerDetailPage: (_, m) {
                Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (_) => MarkerDetailView(
                      marker: m,
                      keyword: keyword,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      };

      final initialMarkerId = (widget).initialMarkerId;
      if (initialMarkerId != null) {
        await viewModel.onMarkerTapped(initialMarkerId);
      }
    });
  }

  void _onMapTapped(BuildContext context, LatLng latLng) async {
    final bool? shouldAddMarker = await showDialog<bool>(
        context: context,
        builder: (_) => const AppConfirmDialog(
            title: '마커를 추가할까요?',
            message: '선택한 위치에 새 장소를 저장할 수 있어요.',
            confirmLabel: '마커 추가',
            icon: Icons.add_location_alt_outlined));
    if (shouldAddMarker == true) {
      if (!context.mounted) return;
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
      AppPageRoute(
        motion: AppMotion.editor,
        builder: (BuildContext context) =>
            MarkerCreationScreen(initialLatLng: latLng),
      ),
    );

    if (result != null && _pendingLatLng != null) {
      if (!context.mounted) return;
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

  Future<void> _showKeywordFilter() async {
    final vm = context.read<MapSampleViewModel>();
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => MapKeywordSheet(
          keywords: vm.keywordIcons, selected: vm.activeKeywords),
    );
    if (selected == null || !mounted) return;
    _searchController.clear();
    vm.clearSearchResults();
    vm.clearPolylines();
    vm.setSelectedListId(null);
    await vm.applyKeywords(selected);
  }

  void showUserLists(BuildContext context) async {
    List<Map<String, dynamic>> userLists =
        await context.read<MapSampleViewModel>().getUserLists();
    if (!mounted) return;

    if (userLists.isEmpty) {
      if (!context.mounted) return;
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
    if (!context.mounted) return;
    final viewModel = context.read<MapSampleViewModel>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (sheetContext) => MapTripListSheet(
        lists: userLists,
        selectedListId: viewModel.selectedListId,
        onSelect: (listId) {
          viewModel.setSelectedListId(listId);
          Navigator.pop(sheetContext);
          showMarkersForSelectedList(listId);
        },
        onReset: () {
          viewModel.clearPolylines();
          viewModel.setSelectedListId(null);
          viewModel.showAllMarkers();
          Navigator.pop(sheetContext);
        },
      ),
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
        final details =
            await viewModel.fetchMarkerDetail(marker.markerId.value);
        markerDetailsMap[marker.markerId.value] = details;
      }),
    );

    if (!mounted) return;
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
                        color: Colors.black.withValues(alpha: 0.2),
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
                              margin:
                                  EdgeInsets.only(bottom: AppDesign.spacing16),
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
                                    borderRadius: BorderRadius.circular(
                                        AppDesign.radiusXL),
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
                                    AppDesign.travelBlue.withValues(alpha: 0.1),
                                    AppDesign.travelPurple
                                        .withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppDesign.radiusMedium),
                                border: Border.all(
                                  color: AppDesign.travelBlue
                                      .withValues(alpha: 0.2),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            color: AppDesign.travelBlue
                                                .withValues(alpha: 0.8),
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
                                onReorderItem:
                                    (int oldIndex, int newIndex) async {
                                  HapticFeedback.lightImpact(); // 햅틱 피드백 추가
                                  await viewModel.reorderMarkers(
                                    oldIndex,
                                    newIndex,
                                    listId,
                                    context.read<AddMarkersToListViewModel>(),
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final marker =
                                      viewModel.orderedMarkers[index];
                                  final details =
                                      markerDetailsMap[marker.markerId.value] ??
                                          {
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
                                  final keywordColor = keywordColors[keyword] ??
                                      AppDesign.travelBlue;

                                  return Container(
                                    key: ValueKey(marker.markerId.value),
                                    margin: EdgeInsets.only(
                                        bottom: AppDesign.spacing12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          Navigator.pop(context);
                                          viewModel
                                              .onMarkerTapped(marker.markerId);
                                        },
                                        borderRadius: BorderRadius.circular(
                                            AppDesign.radiusLarge),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppDesign.cardBg,
                                            borderRadius: BorderRadius.circular(
                                                AppDesign.radiusLarge),
                                            border: Border.all(
                                              color: AppDesign.borderColor
                                                  .withValues(alpha: 0.5),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: keywordColor.withValues(
                                                    alpha: 0.08),
                                                blurRadius: 12,
                                                offset: Offset(0, 4),
                                              ),
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.04),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                                AppDesign.spacing16),
                                            child: Row(
                                              children: [
                                                // 드래그 핸들과 순서 번호
                                                Column(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .drag_indicator_rounded,
                                                      color:
                                                          AppDesign.subtleText,
                                                      size: 20,
                                                    ),
                                                    Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            keywordColor,
                                                            keywordColor
                                                                .withValues(
                                                                    alpha: 0.7),
                                                          ],
                                                        ),
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: keywordColor
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            blurRadius: 8,
                                                            offset:
                                                                Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          orderNumber
                                                              .toString(),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                    width: AppDesign.spacing16),
                                                // 콘텐츠
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              title,
                                                              style: AppDesign
                                                                  .bodyMedium
                                                                  .copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 15,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              width: AppDesign
                                                                  .spacing8),
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                              horizontal:
                                                                  AppDesign
                                                                      .spacing10,
                                                              vertical:
                                                                  AppDesign
                                                                      .spacing4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: keywordColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          AppDesign
                                                                              .radiusXL),
                                                              border:
                                                                  Border.all(
                                                                color: keywordColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.2),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  _getKeywordIcon(
                                                                      keyword),
                                                                  size: 12,
                                                                  color:
                                                                      keywordColor,
                                                                ),
                                                                SizedBox(
                                                                    width: AppDesign
                                                                        .spacing4),
                                                                Text(
                                                                  keyword,
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        keywordColor,
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (address
                                                          .isNotEmpty) ...[
                                                        SizedBox(
                                                            height: AppDesign
                                                                .spacing8),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .location_on_outlined,
                                                              size: 14,
                                                              color: AppDesign
                                                                  .subtleText,
                                                            ),
                                                            SizedBox(
                                                                width: AppDesign
                                                                    .spacing4),
                                                            Expanded(
                                                              child: Text(
                                                                address,
                                                                style: AppDesign
                                                                    .caption
                                                                    .copyWith(
                                                                  color: AppDesign
                                                                      .secondaryText,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
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
                                                  padding: EdgeInsets.all(
                                                      AppDesign.spacing8),
                                                  decoration: BoxDecoration(
                                                    color: AppDesign.lightGray,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons
                                                        .arrow_forward_ios_rounded,
                                                    color:
                                                        AppDesign.secondaryText,
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                                    borderRadius: BorderRadius.circular(
                                        AppDesign.radiusMedium),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(
                                          AppDesign.radiusMedium),
                                      onTap: () {
                                        Navigator.pop(context);
                                        showUserLists(context);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: AppDesign.spacing16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.arrow_back_rounded,
                                              color: AppDesign.secondaryText,
                                              size: 20,
                                            ),
                                            SizedBox(width: AppDesign.spacing8),
                                            Text(
                                              '뒤로가기',
                                              style:
                                                  AppDesign.bodyMedium.copyWith(
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
                                    borderRadius: BorderRadius.circular(
                                        AppDesign.radiusMedium),
                                    boxShadow: AppDesign.glowShadow,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(
                                          AppDesign.radiusMedium),
                                      onTap: () {
                                        Navigator.pop(context);
                                        final viewModel = context.read<
                                            MapSampleViewModel>(); // ViewModel 타입에 맞게 바꿔주세요
                                        viewModel.showPolyline();
                                        // 경로 최적화 또는 네비게이션 시작
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.navigation_rounded,
                                                    color: Colors.white,
                                                    size: 20),
                                                SizedBox(
                                                    width: AppDesign.spacing8),
                                                Text('경로 안내를 시작합니다'),
                                              ],
                                            ),
                                            backgroundColor:
                                                AppDesign.travelGreen,
                                            behavior: SnackBarBehavior.floating,
                                            margin: EdgeInsets.all(
                                                AppDesign.spacing16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppDesign.radiusMedium),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: AppDesign.spacing16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.navigation_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: AppDesign.spacing8),
                                            Text(
                                              '경로 시작',
                                              style:
                                                  AppDesign.bodyMedium.copyWith(
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

  @override
  Widget build(BuildContext context) {
    final List<String> keywords =
        context.read<MapSampleViewModel>().keywordIcons.keys.toList();
    final searchResults = context.watch<MapSampleViewModel>().searchResults;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const TripNestNavigation(currentRoute: '/map'),
      body: Stack(
        children: [
          Consumer<MapSampleViewModel>(
            builder: (context, viewModel, child) {
              return GoogleMap(
                style: viewModel.mapStyle,
                padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + 126, bottom: 24),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer()),
                },
                onMapCreated: (GoogleMapController controller) async {
                  if (_isMapInitialized) return;
                  _isMapInitialized = true;

                  // View 로컬 컨트롤러에 할당
                  setState(() {
                    _controller = controller;
                  });
                  viewModel.controller = controller; //viewmodel에도 전달
                  await viewModel.initializeMapMarkers(controller);
                  if (mounted) {
                    setState(() => _hasLoadedMarkers = true);
                  }

                  // 핵심 수정: initialMarkerId가 있으면 내 위치 이동 안 함!
                  if (widget.initialMarkerId == null &&
                      viewModel.currentLocation != null) {
                    // 처음 앱 켤 때만 내 위치로 이동
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(viewModel.currentLocation!.latitude,
                              viewModel.currentLocation!.longitude),
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
                    if (widget.initialListId != null && mounted) {
                      viewModel.setSelectedListId(widget.initialListId);
                      showMarkersForSelectedList(widget.initialListId!);
                    }
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
                //markers: viewModel.displayMarkers,

                markers: {
                  // 1. 기존 사용자 마커들 (클러스터 등)
                  ...viewModel.displayMarkers,

                  // 2. 검색 결과 마커들 전체 추가 ← 이게 핵심!!
                  ...viewModel.searchResults,

                  // 3. 임시 마커 (첫 번째 결과 강조용, 선택사항)
                  if (viewModel.temporaryMarker != null)
                    viewModel.temporaryMarker!.copyWith(
                      onTapParam: () {
                        final LatLng latLng =
                            viewModel.temporaryMarker!.position;
                        _onMapTapped(context, latLng);
                      },
                    ),
                },

                polylines: {
                  if (viewModel.polygonPoints.length >= 2)
                    Polyline(
                      polylineId: PolylineId('ordered_polyline'),
                      points: viewModel.polygonPoints,
                      color: AppDesign.travelBlue,
                      width: 5,
                    ),
                },
                //onTap: (latLng) => _onMapTapped(context, latLng),
                onCameraMove: (position) {
                  viewModel.onCameraMove(position);
                },
                onCameraIdle: () {
                  viewModel.onCameraIdle();
                },
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.paddingOf(context).top + 8, 16, 0),
              child: Column(children: [
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0xFFE5E5E7)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 18,
                            offset: Offset(0, 4))
                      ]),
                  child: Row(children: [
                    IconButton(
                        tooltip: '장소 검색',
                        icon: const Icon(Icons.search, size: 27),
                        onPressed: () => _viewModel
                            .onSearchSubmitted(_searchController.text)),
                    Expanded(
                        child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                          hintText: '어디로 떠날까요?',
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintStyle: TextStyle(color: Color(0xFF88898E)),
                          contentPadding: EdgeInsets.symmetric(vertical: 16)),
                      onSubmitted: _viewModel.onSearchSubmitted,
                      onChanged: (value) {
                        if (value.trim().isEmpty) {
                          _viewModel.clearSearchResults();
                        } else {
                          _viewModel.updateSearchResults(value);
                        }
                      },
                    )),
                    IconButton(
                        tooltip: '키워드 필터',
                        onPressed: _showKeywordFilter,
                        icon: const Icon(Icons.tune_rounded)),
                  ]),
                ),
              ]),
            ),
          ),
          // 지도 초기화 로딩 인디케이터
          if (!_hasLoadedMarkers)
            Positioned.fill(
              child: Container(
                color: AppDesign.primaryBg.withValues(alpha: 0.9),
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
          if (_hasLoadedMarkers &&
              context.watch<MapSampleViewModel>().filteredMarkers.isEmpty &&
              searchResults.isEmpty)
            Center(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(AppDesign.spacing20),
                  decoration: BoxDecoration(
                    color: AppDesign.cardBg,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                    boxShadow: AppDesign.softShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_outlined,
                          color: AppDesign.primary, size: 28),
                      const SizedBox(height: AppDesign.spacing12),
                      const Text('표시할 장소가 없어요', style: AppDesign.headingSmall),
                      const SizedBox(height: AppDesign.spacing8),
                      Text(
                        '검색하거나 다른 필터를 선택해 보세요',
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
          Positioned(
            top: MediaQuery.paddingOf(context).top + 76,
            left: 0,
            right: 0,
            child: SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: keywords.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final vm = context.watch<MapSampleViewModel>();
                    final keyword = index == 0 ? '전체' : keywords[index - 1];
                    final active = index == 0
                        ? vm.activeKeywords.isEmpty
                        : vm.activeKeywords.contains(keyword);
                    return ActionChip(
                      backgroundColor:
                          active ? const Color(0xFF202020) : Colors.white,
                      side: BorderSide(
                          color: active
                              ? const Color(0xFF202020)
                              : const Color(0xFFE5E5E7)),
                      shape: const StadiumBorder(),
                      avatar: index == 0
                          ? null
                          : Icon(vm.keywordIcons[keyword],
                              size: 18,
                              color: active
                                  ? Colors.white
                                  : const Color(0xFF202020)),
                      label: Text({'호텔': '숙소', '음식점': '맛집'}[keyword] ?? keyword,
                          style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : const Color(0xFF202020))),
                      onPressed: () async {
                        if (index == 0) {
                          for (final key in vm.activeKeywords.toList()) {
                            await vm.toggleKeyword(key);
                          }
                        } else {
                          await vm.toggleKeyword(keyword);
                        }
                      },
                    );
                  },
                )),
          ),
          Positioned(
            bottom: 18,
            right: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'btn_ai_chat',
                  elevation: 3,
                  tooltip: 'AI 여행 플래너',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF202020),
                  shape: const CircleBorder(),
                  onPressed: () => Navigator.push(
                      context,
                      AppPageRoute(
                          builder: (_) => const ChatRecommendationScreen())),
                  child: const Icon(Icons.smart_toy_outlined, size: 27),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'btn_list',
                  elevation: 3,
                  tooltip: '여행 리스트 선택 및 필터 초기화',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF202020),
                  shape: const CircleBorder(),
                  onPressed: () => showUserLists(context),
                  child:
                      const Icon(Icons.format_list_bulleted_rounded, size: 27),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'btn_location',
                  tooltip: '현재 위치',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF202020),
                  shape: const CircleBorder(),
                  elevation: 3,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('현재 위치로 이동합니다'),
                          duration: Duration(seconds: 2)),
                    );
                    _viewModel.moveToCurrentLocation();
                  },
                  child: const Icon(Icons.my_location_rounded, size: 27),
                ),
              ],
            ),
          ),
          // 검색 결과 바텀시트 - 리디자인
          if (context.read<MapSampleViewModel>().searchResults.isNotEmpty) ...[
            DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.0,
              maxChildSize: 0.6,
              snap: true,
              snapSizes: [0.0, 0.4],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: AppDesign.backgroundGradient,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppDesign.radiusLarge)),
                    boxShadow: AppDesign.elevatedShadow,
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      // 드래그 핸들
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          margin: EdgeInsets.symmetric(
                              vertical: AppDesign.spacing12),
                          decoration: BoxDecoration(
                            color: AppDesign.borderColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      // 헤더
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDesign.spacing20),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppDesign.travelBlue),
                            SizedBox(width: AppDesign.spacing8),
                            Text('검색 결과', style: AppDesign.headingSmall),
                            Spacer(),
                            Text(
                              '${context.read<MapSampleViewModel>().searchResults.length}개',
                              style: AppDesign.caption.copyWith(
                                color: AppDesign.travelBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppDesign.spacing12),
                      // 검색 결과 리스트
                      ListView.separated(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDesign.spacing16),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: context
                            .read<MapSampleViewModel>()
                            .searchResults
                            .length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: AppDesign.spacing8),
                        itemBuilder: (context, index) {
                          final marker = context
                              .read<MapSampleViewModel>()
                              .searchResults[index];
                          final keyword = _markerKeywords[marker.markerId];
                          final icon = context
                              .read<MapSampleViewModel>()
                              .keywordIcons[keyword];

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
                                borderRadius: BorderRadius.circular(
                                    AppDesign.radiusMedium),
                                onTap: () async {
                                  debugPrint(
                                      "검색 결과 클릭 → ${marker.markerId.value}");
                                  final viewModel =
                                      context.read<MapSampleViewModel>();

                                  // 컨트롤러 대기
                                  if (viewModel.controller == null) {
                                    debugPrint("controller null → 기다리는 중...");
                                    await Future.delayed(
                                        const Duration(seconds: 5));
                                    if (viewModel.controller == null) {
                                      debugPrint("5초 후에도 controller 없음 → 포기");
                                      return;
                                    }
                                  }

                                  try {
                                    await viewModel.controller!.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: marker.position,
                                          zoom: 17.0,
                                        ),
                                      ),
                                    );
                                    debugPrint("카메라 이동 성공!");
                                  } catch (e) {
                                    debugPrint("카메라 이동 실패: $e");
                                  }

                                  if (mounted) {
                                    viewModel.onSearchMarkerTapped
                                        ?.call(marker);
                                  }
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(AppDesign.spacing16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            EdgeInsets.all(AppDesign.spacing8),
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
                                              style:
                                                  AppDesign.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (marker.infoWindow.snippet !=
                                                null)
                                              Text(
                                                marker.infoWindow.snippet!,
                                                style: AppDesign.caption,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (keyword != null && keyword.isNotEmpty)
                                        Container(
                                          margin: EdgeInsets.only(
                                              left: AppDesign.spacing8),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppDesign.spacing12,
                                            vertical: AppDesign.spacing8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppDesign.travelBlue
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
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
                                                style:
                                                    AppDesign.caption.copyWith(
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
                      SizedBox(height: AppDesign.spacing16),
                    ],
                  ),
                );
              },
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
    super.key,
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
  late String _title;
  String _address = '';
  late String _keyword;

  @override
  void initState() {
    super.initState();
    _title = widget.marker.infoWindow.title ?? '저장한 장소';
    _keyword = widget.keyword;
    _fetchMarkerDetail();
  }

  Future<void> _fetchMarkerDetail() async {
    final viewModel = context.read<MapSampleViewModel>();
    final result =
        await viewModel.fetchMarkerDetail(widget.marker.markerId.value);
    if (!mounted) return;
    setState(() {
      _title = result['title'] ?? _title;
      _address = (result['address'] ?? '').trim();
      if (_address.isEmpty) _address = '주소 정보가 없어요.';
      _keyword = result['keyword'] ?? _keyword;
    });
  }

  void _openDetail() {
    Navigator.pop(context);
    widget.navigateToMarkerDetailPage(context, widget.marker);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D2D6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.bookmark_rounded,
                    size: 16, color: Color(0xFF777980)),
                SizedBox(width: 5),
                Text('저장한 장소',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF777980),
                    )),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: AddressPhotoPreview(
                      address: _address,
                      title: _title,
                      size: 88,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF191919),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(placeKeywordIcon(_keyword),
                                size: 17, color: const Color(0xFF333333)),
                            const SizedBox(width: 5),
                            Flexible(
                                child: Text(
                              _keyword.isEmpty ? '장소' : _keyword,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF444444)),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFEEEEF0)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 18, color: Color(0xFF80828A)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    _address.isEmpty ? '주소 확인 중…' : _address,
                    style: const TextStyle(
                        fontSize: 13, height: 1.45, color: Color(0xFF60626A)),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _openDetail,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF202020),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('장소 상세 보기',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
