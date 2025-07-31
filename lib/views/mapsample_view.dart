import 'package:flutter/foundation.dart';
import 'package:fluttertrip/views/markercreationscreen_view.dart';
import 'package:fluttertrip/views/widgets/zoom_drawer_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../viewmodels/add_markers_to_list_viewmodel.dart';
import '../viewmodels/markercreationscreen_viewmodel.dart';
import '../viewmodels/nickname_dialog_viewmodel.dart';
import '../views/markerdetail_view.dart';
import '../viewmodels/mapsample_viewmodel.dart';
import 'nickname_dialog_view.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:flutter/gestures.dart';
import '../viewmodels/markerdetail_viewmodel.dart';


class MapSampleView extends StatefulWidget {
  const MapSampleView({Key? key}) : super(key: key); // MapSampleView 생성자

  @override
  _MapSampleViewState createState() => _MapSampleViewState();
}

class _MapSampleViewState extends State<MapSampleView> {
  int selectedIndex = 0; // 선택된 메뉴 인덱스 상태

  @override
  Widget build(BuildContext context) {
    return ZoomDrawerContainer(
      selectedIndex: selectedIndex,
      onItemSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
      mainScreenBuilder: (context) => _buildMainScreen(context),
    );
  }

  late MapSampleViewModel viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    viewModel = context.read<MapSampleViewModel>(); // 여기서 미리 가져와 저장
  }

  @override
  void dispose() {
    super.dispose();
  }


  final ZoomDrawerController zoomDrawerController = ZoomDrawerController();
  late GoogleMapController _controller;
  Set<Marker> _markers = {}; // 현재 화면에 표시되는 마커들
  Set<Marker> _allMarkers = {}; // 전체 마커들
  Map<MarkerId, String> _markerKeywords = {}; // 마커 ID와 키워드 매핑
  TextEditingController _searchController = TextEditingController();
  bool _isMapInitialized = false;
  final Map<String, String> keywordMarkerImages = {
    '카페': 'assets/cafe_marker.png',
    '호텔': 'assets/hotel_marker.png',
    '사진': 'assets/photo_marker.png',
    '음식점': 'assets/restaurant_marker.png',
    '전시회': 'assets/exhibition_marker.png',
  };
  LatLng? _pendingLatLng; // 마커 생성 대기 중인 위치
  List<Marker> bookmarkedMarkers = []; // 북마크 된 마커 리스트

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<MapSampleViewModel>();
      await viewModel.loadMarkers(); // 첫 로딩 시점에서 호출

      // ✅ 닉네임 확인 및 다이얼로그 표시
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userService = UserService();
        final hasNickname = await userService.hasNickname(user.id);
        if (!hasNickname) {
          showDialog(
            context: context,
            barrierDismissible: false, // 닫기 방지
            builder: (_) => ChangeNotifierProvider(
              create: (_) => NicknameDialogViewModel(userId: user.id),
              child: NicknameDialogView(),
            ),
          );
        }
      }

      viewModel.onMarkerTappedCallback = (marker) {
        String keyword = viewModel.getKeywordByMarkerId(marker.markerId.value) ?? '';
        final selectedListId = context.read<MapSampleViewModel>().selectedListId;


        showModalBottomSheet(
          context: context,
          builder: (_) => MarkerInfoBottomSheet(
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
                    marker: m, keyword: '',
                    onSave: (Marker , String ) {  },
                    onDelete: (Marker ) {  },
                    onBookmark: (Marker ) {  },
                  ),
                ),
              );
            },
          ),
        );
      };
    });
  }


// 마커 세부사항 페이지로 들어가 새로고침 하는 로직
  void _navigateToMarkerDetailPage(BuildContext context, Marker marker) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MarkerDetailView(
              marker: marker,
              onSave: (Marker updatedMarker, String updatedKeyword) {
                setState(() {
                  // UI에서 마커 업데이트
                  _markers.removeWhere((m) =>
                  m.markerId == updatedMarker.markerId);
                  _markers.add(updatedMarker);
                  _allMarkers
                      .removeWhere((m) => m.markerId == updatedMarker.markerId);
                  _allMarkers.add(updatedMarker);

                  // 키워드 업데이트
                  _markerKeywords[updatedMarker.markerId] = updatedKeyword;
                });

                // Firestore에 마커 정보 업데이트
                // 키워드에 따른 이미지 경로를 가져옴
                final markerImagePath = keywordMarkerImages[updatedKeyword] ??
                    'assets/default_marker.png';
                context.read<MapSampleViewModel>().updateMarker(
                    updatedMarker, updatedKeyword, markerImagePath);
              },
              keyword: _markerKeywords[marker.markerId] ?? 'default',
              onBookmark: (Marker bookmarkedMarker) {
                // 북마크 처리 로직
              },
              onDelete: (Marker deletedMarker) {
                setState(() {
                  // 마커를 UI에서 제거
                  _markers.removeWhere((m) =>
                  m.markerId == deletedMarker.markerId);
                  _allMarkers
                      .removeWhere((m) => m.markerId == deletedMarker.markerId);
                });
              },
            ),
      ),
    );

    // 마커 세부 페이지에서 돌아온 후 마커를 다시 로드
    if (result == true) {
      context.read<MapSampleViewModel>().loadMarkers();
    }
  }

//구글 마커 생성 클릭 이벤트
  void _onMapTapped(BuildContext context, LatLng latLng) async {
    final bool? shouldAddMarker = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.only(bottom: 12, right: 12, left: 12),

          title: Row(
            children: const [
              Icon(
                Icons.add_location_alt_outlined,
                color: Colors.black87,
              ),
              SizedBox(width: 10),
              Text(
                '마커 추가',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          content: const Text(
            '이 위치에 마커를 추가할까요?',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),

          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '마커 추가',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
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

  void _navigateToMarkerCreationScreen(BuildContext context, LatLng latLng) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) =>
            MarkerCreationScreen(initialLatLng: latLng),
      ),
    );

    if (result != null && _pendingLatLng != null) {
      final keyword = result['keyword'] ?? 'default'; // 키워드가 없을 경우 기본값 설정
      final listId = result['listId']; // ✅ 리스트 ID도 추출
      final address = result['address'] ?? '';
      context.read<MapSampleViewModel>().addMarker(
        title: result['title'],
        snippet: result['snippet'],
        position: _pendingLatLng!,
        keyword: keyword,
        address: address,
        listId: listId, // ✅ 이걸 넘겨야 저장 가능
        onTapCallback: (markerId) {
          context.read<MapSampleViewModel>().onMarkerTapped(markerId);
        },
      );
      _pendingLatLng = null;
    }
  }

  void _bookmarkLocation(BuildContext context,Marker marker) {
    setState(() {
      bookmarkedMarkers.add(marker); // 마커를 북마크 리스트에 추가
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('북마크에 추가되었습니다.')),
    );
  }

  void _showMarkerInfoBottomSheet(BuildContext context,Marker marker, Function(Marker) onDelete, String keyword,String listId,) {
    print('showMarkerInfoBottomSheet called for marker: ${marker.markerId}');  // 디버깅용 로그

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, //하단시트에서 스크롤
      builder: (BuildContext context) =>
          Container(
            width: MediaQuery
                .of(context)
                .size
                .width, //화면 전체 너비 사용
            padding: EdgeInsets.all(16.0),
            child: MarkerInfoBottomSheet(
              marker: marker,
              keyword: keyword,
              listId: listId, // ✅ 전달
              onSave: (updatedMarker, keyword, address) async {
                // 키워드에 따른 이미지 경로를 가져옴
                final markerImagePath = keywordMarkerImages[keyword] ?? 'assets/default_marker.png';
                context.read<MarkerCreationScreenViewModel>().saveMarker(
                  marker: updatedMarker,
                  keyword: keyword,
                  markerImagePath: markerImagePath,
                  listId: listId, // ✅ 전달
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
    List<Map<String, dynamic>> userLists = await context.read<MapSampleViewModel>().getUserLists();

    if (userLists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장된 리스트가 없습니다')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView.separated(
                shrinkWrap: true,
                itemCount: userLists.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final list = userLists[index];
                  final listName = list['name'] ?? '이름 없음';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(context);
                        showMarkersForSelectedList(userLists[index]['id']);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.list_alt_rounded, color: Colors.blueAccent),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                listName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    context.read<MapSampleViewModel>().loadMarkers();
                    context.read<MapSampleViewModel>().clearPolylines();
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.redAccent),
                        SizedBox(width: 16),
                        Text(
                          '초기화',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
        const SnackBar(content: Text('해당 리스트에 마커가 없습니다.')),
      );
      return;
    }

    final backgroundColor = Theme.of(context).colorScheme.background;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: backgroundColor,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 안내 메시지
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.drag_handle, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '드래그해서 순서를 변경하세요',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 드래그로 순서 변경 가능한 리스트
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: markers.length,
                      onReorder: (int oldIndex, int newIndex) async {
                        await viewModel.reorderMarkers(
                          oldIndex,
                          newIndex,
                          listId, // 현재 리스트의 ID
                          context.read<AddMarkersToListViewModel>(), // 필요한 ViewModel 인스턴스
                        );
                        setState(() {});
                      },
                        itemBuilder: (context, index) {
                          final marker = viewModel.orderedMarkers[index];
                          final title = marker.infoWindow.title ?? '제목 없음';
                          final snippet = marker.infoWindow.snippet ?? '';
                          final keyword = snippet.isNotEmpty ? snippet : '키워드 없음';
                          final orderNumber = index + 1; // 1번부터 시작

                          return Container(
                            key: ValueKey(marker.markerId.value),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.drag_handle, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    // 번호를 동그라미로 표시
                                    CircleAvatar(
                                      backgroundColor: Colors.deepOrange,
                                      radius: 14,
                                      child: Text(
                                        orderNumber.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.place, color: Colors.deepOrange),
                                  ],
                                ),
                                title: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    keyword,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.pop(context);
                                  _controller?.animateCamera(
                                    CameraUpdate.newLatLng(marker.position),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 뒤로가기 카드 버튼
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(context);
                        showUserLists(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back, color: Colors.black87),
                            SizedBox(width: 16),
                            Text(
                              '뒤로가기',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
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
  }

  @override
  Widget _buildMainScreen(BuildContext context) {
    final List<String> keywords = context.read<MapSampleViewModel>().keywordIcons.keys.toList();
    final searchResults = context.watch<MapSampleViewModel>().searchResults;
    final selectedListId = context.read<MapSampleViewModel>().selectedListId;

    return Scaffold(
      body: Stack(
        children: [
          Consumer<MapSampleViewModel>(
            builder: (context, viewModel, child) {
              return GoogleMap(
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
                onMapCreated: (GoogleMapController controller) async {
                  if (_isMapInitialized) return;  // 이미 초기화 되었다면 함수 종료
                  _isMapInitialized = true;

                  viewModel.controller = controller;
                  await viewModel.loadMarkers();
                  await viewModel.applyMarkersToCluster(controller);
                  controller.setMapStyle(viewModel.mapStyle);

                  //현재 위치가 설정된 경우 카메라 이동
                  if (viewModel.currentLocation != null) {
                    controller!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(
                              viewModel.currentLocation!.latitude!,
                              viewModel.currentLocation!.longitude!),
                          zoom: 15,
                        ),
                      ),
                    );
                  }
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
                // 확대/축소 버튼 숨기기
                zoomControlsEnabled: false,
                // 내 위치 아이콘 표시 여부
                myLocationEnabled: true,
                // 내 위치 버튼 숨기기
                myLocationButtonEnabled: false,
                // 마커 표시
                markers: viewModel.displayMarkers,
                polylines: {
                  if (viewModel.polygonPoints.length >= 2)
                    Polyline(
                      polylineId: PolylineId('ordered_polyline'),
                      points: viewModel.polygonPoints,
                      color: Colors.blue,
                      width: 5,
                    ),
                },
                // 클러스터링된 마커 사용
                onTap: (latLng) => _onMapTapped(context, latLng),
                onCameraMove: (position) {
                  viewModel.onCameraMove(position);
                  viewModel.clusterManager?.onCameraMove(position);
                },

                // 카메라 이동이 완료되면 클러스터 업데이트
                onCameraIdle: () {
                  viewModel.clusterManager?.updateMap();
                },
              );
            },
          ),
          // 검색창 (지도 위)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Builder(
              builder: (context) =>
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            ZoomDrawer.of(context)?.toggle();
                          },
                          child: Icon(Icons.menu, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: '주소, 장소명 검색...',
                              hintStyle: TextStyle(color: Colors.white54),
                              // 입력창 테두리 스타일
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(40.0), // 모서리 둥글게
                              ),
                            ),
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            onSubmitted: context.read<MapSampleViewModel>().onSearchSubmitted,
                            onChanged: context.read<MapSampleViewModel>().updateSearchResults,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.white),
                          onPressed: () =>
                              context.read<MapSampleViewModel>().onSearchSubmitted(_searchController.text),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
          // 지도 초기화 완료 상태를 표시하는 예제
          if (!_isMapInitialized)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: const Text(
                  "지도를 초기화하는 중...",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          Consumer<MapSampleViewModel>(builder: (context, viewModel, child) {
            return Positioned(
              top: 140.0,
              left: 0,
              right: 0,
              child: Container(
                height: 40.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: keywords.length,
                  itemBuilder: (context, index) {
                    final keyword = keywords[index]; // 인덱스에 해당하는 키워드 가져오기
                    final icon = viewModel.keywordIcons[keyword]; // 해당 키워드에 맞는 아이콘 가져오기
                    final isActive = viewModel.activeKeywords.contains(keyword);
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 5.0),
                      // 키워드 버튼 간격 조정
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isActive ? Colors.grey : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 12),
                          // horizontal : 가로 방향에 각각 몇 픽셀의 패딩을 추가
                          // vertical: 세로 방향에 각각 몇 픽셀의 패딩을 추가 (Textstyle에 값과 비슷하게 설정할것)
                        ),
                        onPressed: () {
                          context.read<MapSampleViewModel>().toggleKeyword(keyword);
                        },
                        icon: Icon(icon, color: Colors.white, size: 12),
                        label: Text(
                          keyword,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold), // 글씨 크기 조정
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
          Positioned(
            bottom: 40,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'btn_location',
                  onPressed: () {
                    // SnackBar를 화면 하단에 표시
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "현재 사용자 위치로 이동합니다",
                          style: TextStyle(color: Colors.white),
                        ), // 표시할 문구
                        duration: Duration(seconds: 2), // 문구가 표시되는 시간
                        backgroundColor: Colors.black,
                      ),
                    );
                    context.read<MapSampleViewModel>().moveToCurrentLocation();
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location),
                ),
                SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'btn_list',
                  onPressed: () => showUserLists(context),
                  backgroundColor: Colors.white,
                  child: Icon(Icons.list),
                )
              ],
            ),
          ),
          // 검색창에 입력한 제목을 화면 하단에 검색 결과를 표시하는 기능
          if (searchResults.isNotEmpty) ...[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Dismissible(
                key: ValueKey('searchResultsBottomSheet_${searchResults.length}'),
                direction: DismissDirection.down, // 아래로 스와이프 가능
                onDismissed: (direction) {
                  // 상태를 즉시 바꿔서 트리에서 제거되도록 유도
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<MapSampleViewModel>().clearSearchResults();
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8), // 지도가 완전히 가려지지 않도록
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4, // 화면의 40% 높이 제한
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 드래그 핸들 추가 (사용자가 쉽게 끌어내릴 수 있도록)
                      Container(
                        width: 50,
                        height: 5,
                        margin: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          //리스트 상하 여백 제거
                          shrinkWrap: true,
                          itemCount: context.watch<MapSampleViewModel>().searchResults.length,
                          separatorBuilder: (context, index) =>
                              Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                          itemBuilder: (context, index) {
                            final marker = context.watch<MapSampleViewModel>().searchResults[index]; // 검색 결과에서 마커 가져오기
                            final keyword = _markerKeywords[marker.markerId]; // 키워드 가져오기
                            final icon = context.watch<MapSampleViewModel>().keywordIcons[keyword]; // 키워드에 해당하는 아이콘 가져오기

                            return ListTile(
                              leading: Icon(
                                Icons.location_on,
                                color: Colors.red,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      marker.infoWindow.title ?? 'Untitled',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (keyword != null && keyword.isNotEmpty)
                                    Container(
                                      margin: EdgeInsets.only(left: 8),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(icon,
                                              color: Colors.black, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            keyword,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                marker.infoWindow.snippet ?? 'Untitled',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              onTap: () {
                                _controller?.animateCamera(
                                  CameraUpdate.newLatLng(marker.position),
                                );
                                _showMarkerInfoBottomSheet(
                                  context,
                                  marker,
                                      (Marker markerToDelete) {
                                    // 마커 삭제 로직 추가 가능
                                  },
                                  keyword ?? '',
                                  selectedListId ?? '',
                                );
                              },
                            );
                          },
                        ),
                      ),
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('user_markers')
          .select('title, address, keyword')
          .eq('id', widget.marker.markerId.value)
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _title = data['title'] ?? '제목 없음';
          _address = data['address'] ?? '주소 없음';
          _keyword = data['keyword'] ?? '키워드 없음';
        });
      } else {
        setState(() {
          _title = '제목 없음';
          _address = '주소 없음';
          _keyword = '키워드 없음';
        });
      }
    } catch (e) {
      print('마커 정보 불러오기 오류: $e');
      setState(() {
        _title = '오류 발생';
        _address = '';
        _keyword = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.navigateToMarkerDetailPage(context, widget.marker);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.title, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      _title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.touch_app, color: Colors.grey, size: 20),
                    Text('클릭하여 자세히 보기',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 4),
                Container(
                    height: 2, color: Colors.black, width: double.infinity),
                SizedBox(height: 8),
              ],
            ),
          ),

          // ✅ 주소
          if (_address.isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _address,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: 10),

          // ✅ 키워드
          Row(
            children: [
              Icon(Icons.label, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                _keyword.isNotEmpty ? _keyword : '기본 키워드',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
