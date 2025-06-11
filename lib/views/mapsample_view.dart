import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../views/markerdetail_view.dart';
import '../views/profile_view.dart';
import '../views/friend_management_view.dart';
import '../viewmodels/mapsample_viewmodel.dart';
import '../views/BookmarkListTab_view.dart';


class MapSampleView extends StatefulWidget {
  const MapSampleView({Key? key}) : super(key: key); // MapSampleView 생성자

  @override
  _MapSampleViewState createState() => _MapSampleViewState();
}

class _MapSampleViewState extends State<MapSampleView> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<MapSampleViewModel>();
      viewModel.loadMarkers(); // 첫 로딩 시점에서 호출

      viewModel.onMarkerTappedCallback = (marker) {
        String keyword = viewModel.getKeywordByMarkerId(marker.markerId.value) ?? '';
        showModalBottomSheet(
          context: context,
          builder: (_) => MarkerInfoBottomSheet(
            marker: marker,
            keyword: keyword.isNotEmpty ? keyword : '',
            onSave: (m, value) async {
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

  @override
  void dispose() {
    context.read<MapSampleViewModel>().dispose(); // 리소스 해제
    super.dispose();
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
    // 확인 대화상자 표시
    final bool? shouldAddMarker = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                '마커 생성',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
          content: Text('마커를 생성하시겠습니까?'),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: Text(
                '예',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // "예" 선택 시 true 반환
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: Text(
                '아니오',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false); // "아니오" 선택 시 false 반환
              },
            ),
          ],
        );
      },
    );

    // 사용자가 "예"를 선택한 경우에만 마커 생성 창으로 이동
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
      context.read<MapSampleViewModel>().addMarker(
        title: result['title'],
        snippet: result['snippet'],
        position: _pendingLatLng!,
        keyword: keyword,
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

  void _showMarkerInfoBottomSheet(BuildContext context,Marker marker, Function(Marker) onDelete, String keyword,) {
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
              onSave: (updatedMarker, keyword) async {
                // 키워드에 따른 이미지 경로를 가져옴
                final markerImagePath = keywordMarkerImages[keyword] ?? 'assets/default_marker.png';
                context.read<MapSampleViewModel>().saveMarker(updatedMarker, keyword, markerImagePath);
              },
              onDelete: onDelete,
              keyword: keyword,
              onBookmark: (marker) {
                _bookmarkLocation(context, marker);
              },
              navigateToMarkerDetailPage: _navigateToMarkerDetailPage,
            ),
          ),
    );
  }

  void showUserLists(BuildContext context) async {
    List<QueryDocumentSnapshot> userLists =
    await context.read<MapSampleViewModel>().getUserLists();

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
                  final list = userLists[index].data() as Map<String, dynamic>;
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
                        showMarkersForSelectedList(context, userLists[index].id);
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



  void showMarkersForSelectedList(BuildContext context, String listId) async {
    final viewModel = context.read<MapSampleViewModel>();
    await viewModel.loadMarkersForList(listId);
    final markers = viewModel.filteredMarkers.toList();

    if (markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해당 리스트에 마커가 없습니다.')),
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
                      onReorder: (int oldIndex, int newIndex) {
                        viewModel.reorderMarkers(oldIndex, newIndex);
                        setState(() {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final marker = markers.removeAt(oldIndex);
                          markers.insert(newIndex, marker);
                        });
                      },
                      itemBuilder: (context, index) {
                        final marker = markers[index];
                        final title = marker.infoWindow.title ?? '제목 없음';
                        final snippet = marker.infoWindow.snippet ?? '';
                        final keyword = snippet.isNotEmpty ? snippet : '키워드 없음';

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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final List<String> keywords = context.read<MapSampleViewModel>().keywordIcons.keys.toList();
    final searchResults = context.watch<MapSampleViewModel>().searchResults;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/cad.png'),
              ),
              accountName: Text('kim'),
              accountEmail: Row(
                children: [
                  Expanded(
                    child: Text(
                      user != null ? user.email ?? 'No email' : 'Not logged in',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      // 로그아웃 확인 다이얼로그 표시
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              '로그아웃',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: Text('로그아웃하시겠습니까?'),
                            actions: [
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(
                                  '예',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(
                                  '아니오',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pop(); // Drawer 닫기
                        Navigator.of(context)
                            .pushReplacementNamed('/login'); // 로그인 화면으로 이동
                      }
                    },
                  ),
                ],
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40.0),
                  bottomRight: Radius.circular(40.0),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.map,
                color: Colors.grey[850],
              ),
              title: Text(
                '지도',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                context.read<MapSampleViewModel>().onItemTapped(0); //구글 맵 화면으로 이동
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.account_circle,
                color: Colors.grey[850],
              ),
              title: Text(
                '프로필',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  // 로그인한 사용자가 있는 경우
                  String userId = user.uid;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfilePage(userId: userId)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('로그인 후 사용해 주세요.')),
                  );
                }
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.list,
                color: Colors.grey[850],
              ),
              title: Text(
                '북마크/리스트',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookmarklisttabView(initialIndex: 0), // 북마크 탭 index
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.person_add,
                color: Colors.grey[850],
              ),
              title: Text(
                '친구',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendManagementView(),
                  ),
                );
              },
            ),
            Divider(),
          ],
        ),
      ),
      body: Stack(
        children: [
          Consumer<MapSampleViewModel>(
            builder: (context, viewModel, child) {
              return GoogleMap(
                onMapCreated: (GoogleMapController controller) async {
                  viewModel.controller = controller;
                  setState(() {
                    _isMapInitialized = true;
                    print('_isMapInitialized set to true');
                  });
                  viewModel.controller = controller;
                  await viewModel.loadMarkers();
                  await viewModel.applyMarkersToCluster(controller); // 클러스터 매니저 초기화
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
                            Scaffold.of(context).openDrawer();
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

class MarkerCreationScreen extends StatefulWidget {
  final LatLng initialLatLng;

  MarkerCreationScreen({required this.initialLatLng}); //생성자에서 LatLng 받기

  @override
  _MarkerCreationScreenState createState() => _MarkerCreationScreenState();
}

class _MarkerCreationScreenState extends State<MarkerCreationScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _snippetController = TextEditingController();
  String? _selectedKeyword; // 드롭다운 메뉴를 통해 키워드 선택
  File? _image;
  String _address = 'Fetching address...';


  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MapSampleViewModel>(context, listen: false);
    final List<String> keywords = viewModel.keywordIcons.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('마커생성'),
        titleTextStyle: TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.title, color: Colors.black),
                      SizedBox(width: 2),
                      Text(
                        '이름',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )),
            ),
            TextField(
              controller: _snippetController,
              decoration: InputDecoration(
                labelText: '설명',
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '$_address',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label, color: Colors.blue),
                  SizedBox(height: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedKeyword,
                      hint: Text('키워드 선택'),
                      items: keywords.map((String keyword) {
                        return DropdownMenuItem<String>(
                          value: keyword,
                          child: Text(keyword),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedKeyword = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final viewModel = Provider.of<MapSampleViewModel>(context, listen: false);
                viewModel.pickImage();
              },
              child: Text('이미지를 고르시오'),
            ),
            SizedBox(height: 16.0),
            _image != null
                ? Image.file(
              _image!,
              height: 200,
            )
                : Text('이미지가 선택된게 없습니다.'),
            SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'title': _titleController.text,
                  'snippet': _snippetController.text,
                  'keyword': _selectedKeyword, // 키워드 포함
                  'image': _image,
                });
              },
              child: Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}


class MarkerInfoBottomSheet extends StatelessWidget {
  final Marker marker;
  final Future<void> Function(Marker, String) onSave;
  final Function(Marker) onDelete;
  final Function(Marker) onBookmark;
  final String keyword;
  final Function(BuildContext, Marker) navigateToMarkerDetailPage;

  MarkerInfoBottomSheet({
    required this.marker,
    required this.onSave,
    required this.onDelete,
    required this.onBookmark,
    required this.keyword,
    required this.navigateToMarkerDetailPage,
  });

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
              navigateToMarkerDetailPage(context, marker);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.title, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      marker.infoWindow.title ?? '제목 없음',
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
          Text(marker.infoWindow.snippet ?? ''),
          Row(
            children: [
              Icon(Icons.label, color: Colors.blue),
              SizedBox(height: 10),
              Text(
                keyword.isNotEmpty ? keyword : '기본 키워드',
                style: TextStyle(color: Colors.black,fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }
}