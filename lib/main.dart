import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertrip/Dashboard_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:markers_cluster_google_maps_flutter/markers_cluster_google_maps_flutter.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertrip/config.dart';
import 'friend_management_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'ForgotPassword_page.dart';
import 'user_list_page.dart';
import 'SplashScreen_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'markerdetail_page.dart';
import 'page.dart';
import 'marker_service.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 앱이 시작될 때 동기화 작업을 수행
  await MarkerService().syncOfflineMarkers();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/forgot_password': (context) => ForgotPasswordPage(),
        '/user_list': (context) => UserListPage(),
        '/home': (context) => MapSample(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

//class MapSampleState
//class MarkerCreationScreen
final Map<String, IconData> keywordIcons = {
  '카페': Icons.local_cafe,
  '호텔': Icons.hotel,
  '사진': Icons.camera_alt,
  '음식점': Icons.restaurant,
  '전시회': Icons.art_track,
};

class MapSampleState extends State<MapSample> {
  final Map<MarkerId, String> _markerKeywords = {}; //마커의 키워드 저장
  Set<Marker> _allMarkers = {}; // 모든 마커 저장
  Set<Marker> _filteredMarkers = {}; // 필터링된 마커 저장
  Set<String> _activeKeywords = {}; //활성화 된 키워드 저장
  LatLng? _pendingLatLng;
  location.LocationData? _currentLocation;
  final location.Location _location = location.Location();
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isMapInitialized = false;
  late GoogleMapController _controller;
  late MarkersClusterManager _clusterManager;
  double _currentZoom = 15.0; // 초기 줌 레벨
  List<Marker> _searchResults = [];
  List<Marker> bookmarkedMarkers = [];
  CollectionReference markersCollection =
      FirebaseFirestore.instance.collection('users');
  final Map<String, String> keywordMarkerImages = {
    '카페': 'assets/cafe_marker.png',
    '호텔': 'assets/hotel_marker.png',
    '사진': 'assets/photo_marker.png',
    '음식점': 'assets/restaurant_marker.png',
    '전시회': 'assets/exhibition_marker.png',
  };
  final MarkerService _markerService = MarkerService();

  static const LatLng _seoulCityHall = LatLng(37.5665, 126.9780);

  final String mapStyle = '''
  [
    {
      "featureType": "poi",
      "elementType": "labels.icon",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    }
  ]
  ''';

  void _toggleKeyword(String keyword) {
    setState(() {
      if (_activeKeywords.contains(keyword)) {
        _activeKeywords.remove(keyword);
      } else {
        _activeKeywords.add(keyword);
      }

      if (_activeKeywords.isEmpty) {
        _filteredMarkers = _allMarkers;
      } else {
        _filteredMarkers = _allMarkers.where((marker) {
          final markerKeyword = _markerKeywords[marker.markerId]?.toLowerCase() ?? '';
          return _activeKeywords.contains(markerKeyword);
        }).toSet();
      }

      _applyMarkersToCluster(); // 클러스터 매니저에 필터링된 마커 적용
    });
  }

  void _onItemTapped(int index) {
    // 구글 맵 화면으로 이동하는 경우 맵 초기화
    if (index == 0 && _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(_seoulCityHall, 15.0),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadMarkers();
    _applyMarkersToCluster();
  }

  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.country ?? ''} ${placemark.administrativeArea ?? ''} ${placemark.locality ?? ''} ${placemark.street ?? ''}';
      }
      return 'Unknown Address';
    } catch (e) {
      print('Error getting address: $e');
      return 'Error fetching address'; // Error message
    }
  }

  Future<void> _loadMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_markers');

      final QuerySnapshot querySnapshot = await userMarkersCollection.get();

      _markers.clear();
      _allMarkers.clear();
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String keyword = data['keyword'] ?? 'default';
        final String? markerImagePath = keywordMarkerImages[keyword];

        // 커스텀 마커 이미지 로드 (비동기 처리) 및 크기 조절
        final BitmapDescriptor markerIcon = markerImagePath != null
            ? await _createCustomMarkerImage(
                markerImagePath, 128, 128) // 크기를 조정
            : BitmapDescriptor.defaultMarkerWithHue(
                data['hue'] != null
                    ? (data['hue'] as num).toDouble()
                    : BitmapDescriptor.hueOrange,
              );

        final lat =
            data['lat'] != null ? data['lat'] as double : 0.0; // 기본값 0.0으로 설정
        final lng =
            data['lng'] != null ? data['lng'] as double : 0.0; // 기본값 0.0으로 설정

        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: data['title'],
            snippet: data['snippet'],
          ),
          icon: markerIcon,
          onTap: () {
            _onMarkerTapped(context, MarkerId(doc.id));
          },
        );
        _markers.add(marker); //화면에 표시될 마커만 _markers에 저장
        _allMarkers.add(marker); //모든 마커 저장
        _markerKeywords[marker.markerId] = data['keyword'] ?? '';
      }
      setState(() {
        _filteredMarkers = _allMarkers; //초기 상태에서 모든 마커 표시
      });
      // 클러스터 갱신
      _applyMarkersToCluster();
    }
  }

  void _applyMarkersToCluster() {
    // 기존 클러스터 매니저를 새로 생성하여 초기화
    _clusterManager = MarkersClusterManager(
      clusterColor: Colors.black,
      clusterBorderThickness: 10.0,
      clusterBorderColor: Colors.black,
      clusterOpacity: 1.0,
      clusterTextStyle: TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      onMarkerTap: (LatLng position) async {
        final GoogleMapController mapController = await _controller;
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: position,
              zoom: 16.0,
            ),
          ),
        );
      },
    );

    // 필터링된 마커 추가
    for (var marker in _filteredMarkers) {
      _clusterManager.addMarker(marker);
    }

    _updateClusters();
  }


  Future<void> _updateClusters() async {
    await _clusterManager.updateClusters(zoomLevel: _currentZoom);
    setState(() {});
  }

  void onEdit(Marker updatedMarker) async {
    final keyword = _markerKeywords[updatedMarker.markerId] ?? 'default';
    final markerImagePath = keywordMarkerImages[keyword];

    if (markerImagePath != null) {
      final customMarker = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        markerImagePath,
      );

      final newMarker = updatedMarker.copyWith(iconParam: customMarker);

      setState(() {
        _markers.removeWhere((m) => m.markerId == updatedMarker.markerId);
        _markers.add(newMarker);
        _allMarkers.removeWhere((m) => m.markerId == updatedMarker.markerId);
        _allMarkers.add(newMarker);
      });

      _updateMarker(newMarker, keyword, markerImagePath);
    }
  }

  Future<void> _updateMarker(
      Marker marker, String keyword, String markerImagePath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_markers');

      await userMarkersCollection.doc(marker.markerId.value).update({
        'title': marker.infoWindow.title,
        'snippet': marker.infoWindow.snippet,
        'keyword': keyword,
        'markerImagePath': markerImagePath,
      });
    }
  }

  // 파이어베이스: 'set' vs 'update'
  // set: 기존 문서를 덮어 쓰거나 문서가 없을 경우 새로 생성
  // update: 문서가 이미 존재하는 경우에만 특정 필드를 수정하며 문서가 존재하지 않으면 에러를 발생

  // 새 마커 생성
  Future<void> _saveMarker(
      Marker marker, String keyword, String markerImagePath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_markers');

      // 좌표로부터 주소를 가져온다
      String address = await _getAddressFromCoordinates(
        marker.position.latitude,
        marker.position.longitude,
      );

      await userMarkersCollection.doc(marker.markerId.value).set({
        'title': marker.infoWindow.title,
        'snippet': marker.infoWindow.snippet,
        'lat': marker.position.latitude,
        'lng': marker.position.longitude,
        'address': address,
        'keyword': keyword,
        'markerImagePath': markerImagePath,
      });
    }
  }

  // 마커 세부사항 페이지로 들어가 새로고침 하는 로직
  void _navigateToMarkerDetailPage(BuildContext context, Marker marker) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkerDetailPage(
          marker: marker,
          onSave: (Marker updatedMarker, String updatedKeyword) {
            setState(() {
              // UI에서 마커 업데이트
              _markers.removeWhere((m) => m.markerId == updatedMarker.markerId);
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
            _updateMarker(updatedMarker, updatedKeyword, markerImagePath);
          },
          keyword: _markerKeywords[marker.markerId] ?? 'default',
          onBookmark: (Marker bookmarkedMarker) {
            // 북마크 처리 로직
          },
          onDelete: (Marker deletedMarker) {
            setState(() {
              // 마커를 UI에서 제거
              _markers.removeWhere((m) => m.markerId == deletedMarker.markerId);
              _allMarkers
                  .removeWhere((m) => m.markerId == deletedMarker.markerId);
            });
          },
        ),
      ),
    );

    // 마커 세부 페이지에서 돌아온 후 마커를 다시 로드
    if (result == true) {
      _loadMarkers();
    }
  }

  Future<void> _getLocation() async {
    final hasPermission = await _location.hasPermission();
    if (hasPermission == location.PermissionStatus.denied) {
      final requested = await _location.requestPermission();
      if (requested != location.PermissionStatus.granted) {
        // 권한이 없을 때 처리
        return;
      }
    }
    _currentLocation = await _location.getLocation();
    _location.onLocationChanged.listen((location.LocationData locationData) {
      setState(() {
        _currentLocation = locationData;
      });
    });
  }

  Future<void> _moveToCurrentLocation() async {
    if (_controller != null && _currentLocation != null) {
      // 사용자의 현재 위치로 이동
      LatLng currentLatLng = LatLng(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
      );

      // 카메라를 현재 위치로 바로 이동
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
            currentLatLng, 18.0 // 사용자의 현재 위치를 중앙으로 이동 및 확대
            ),
      );
    }
  }

  Future<void> _onMarkerTapped(BuildContext context, MarkerId markerId) async {
    final marker = _markers.firstWhere(
      (m) => m.markerId == markerId,
      orElse: () => throw Exception('Marker not found for ID: $markerId'),
    );
    // 마커 위치로 카메라 이동 (await 작업은 마커를 눌렀을때만 적용 나머지는 불필요함)
    print('Marker Position: ${marker.position}');
    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(
          marker.position, 18.0), // 마커의 위치로 카메라 이동,마커 확대기능
    );

    _showMarkerInfoBottomSheet(context, marker, (Marker markerToDelete) {
      // 마커 누르면 하단 창 나옴
    });
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
      final keyword = result['keyword'] ?? 'default'; // 키워드가 없을 경우 기본값 설정
      _addMarker(
          result['title'],
          result['snippet'], // String? 타입
          _pendingLatLng!, // LatLng 타입
          keyword // String 타입
          );
      _pendingLatLng = null;
    }
  }

  void _bookmarkLocation(Marker marker) {
    setState(() {
      bookmarkedMarkers.add(marker); // 마커를 북마크 리스트에 추가
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('북마크에 추가되었습니다.')),
    );
  }

  void _showMarkerInfoBottomSheet(
      BuildContext context, Marker marker, Function(Marker) onDelete) {
    final String keyword = _markerKeywords[marker.markerId] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, //하단시트에서 스크롤
      builder: (BuildContext context) => Container(
        width: MediaQuery.of(context).size.width, //화면 전체 너비 사용
        padding: EdgeInsets.all(16.0),
        child: MarkerInfoBottomSheet(
          marker: marker,
          onSave: (updatedMarker, keyword) async {
            // 키워드에 따른 이미지 경로를 가져옴
            final markerImagePath =
                keywordMarkerImages[keyword] ?? 'assets/default_marker.png';
            await _saveMarker(updatedMarker, keyword, markerImagePath);
          },
          onDelete: onDelete,
          keyword: keyword,
          onBookmark: (marker) {
            _bookmarkLocation(marker);
          },
          navigateToMarkerDetailPage: _navigateToMarkerDetailPage,
        ),
      ),
    );
  }

  Future<List<QueryDocumentSnapshot>> _getUserLists() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return [];
    }

    final listSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .get();

    return listSnapshot.docs;
  }

  void _showUserLists() async {
    List<QueryDocumentSnapshot> userLists = await _getUserLists();

    if (userLists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장된 리스트가 없습니다')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView.separated(
              shrinkWrap: true,
              itemCount: userLists.length,
              itemBuilder: (context, index) {
                final list = userLists[index].data() as Map<String, dynamic>;
                final listName = list['name'] ?? '이름 없음';

                return ListTile(
                  leading: Icon(Icons.list, color: Colors.blue),
                  title: Text(
                    listName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showMarkersForSelectedList(userLists[index].id);
                  },
                );
              },
              separatorBuilder: (context, index) {
                return Divider(
                  color: Colors.grey,
                  thickness: 1,
                );
              },
            ),
            Divider(color: Colors.grey, thickness: 1), // 구분선 추가
            ListTile(
              leading: Icon(Icons.refresh, color: Colors.red),
              title: Text(
                '초기화',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              onTap: () {
                // 만약 동기화가 필요하면 마커 로드 함수 호출
                //초기화 버튼을 누르면 모든 마커 표시
                _loadMarkers();
                Navigator.pop(context); // 모달 닫기
              },
            ),
          ],
        );
      },
    );
  }

  void _showMarkersForSelectedList(String listId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final markerSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .doc(listId)
        .collection('bookmarks')
        .get();

    final markers = markerSnapshot.docs.map((doc) {
      final data = doc.data();
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(data['lat'], data['lng']),
        infoWindow: InfoWindow(
          title: data['title'] ?? '제목 없음',
          snippet: data['snippet'] ?? '설명 없음',
        ),
        onTap: () => _onMarkerTapped(context, MarkerId(doc.id)),
      );
    }).toList();

    if (markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 리스트에 마커가 없습니다')),
      );
      return;
    }

    // 기존 필터링된 마커들을 업데이트
    setState(() {
      _filteredMarkers.clear(); // 기존 필터링된 마커 제거
      _filteredMarkers.addAll(markers); // 새로운 마커들 추가
    });

    // 클러스터 매니저를 업데이트하기 위해 _applyMarkersToCluster() 호출
    _applyMarkersToCluster();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.separated(
          itemCount: markers.length,
          itemBuilder: (context, index) {
            final marker = markers[index];
            final keyword = marker.infoWindow.snippet ?? '키워드 없음';

            return ListTile(
              leading: Icon(Icons.location_on, color: Colors.red),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    marker.infoWindow.title ?? '제목 없음',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    keyword,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              subtitle: Text(marker.infoWindow.snippet ?? '설명 없음'),
              onTap: () {
                Navigator.pop(context);
                _controller!.animateCamera(
                  CameraUpdate.newLatLng(marker.position),
                );
              },
            );
          },
          separatorBuilder: (context, index) {
            return Divider(
              color: Colors.grey,
              thickness: 1,
            );
          },
        );
      },
    );
  }

  Future<BitmapDescriptor> _createCustomMarkerImage(
      String imagePath, int width, int height) async {
    // 이미지 파일 로드
    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List bytes = data.buffer.asUint8List();

    // 이미지 디코딩 및 크기 조정
    final ui.Codec codec = await ui.instantiateImageCodec(bytes,
        targetWidth: width, targetHeight: height);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

    // 크기 조정된 이미지 데이터를 바이트 배열로 변환
    final Uint8List resizedBytes = byteData!.buffer.asUint8List();

    // BitmapDescriptor로 변환
    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  void _addMarker(
      String? title, String? snippet, LatLng position, String keyword) async {
    // 키워드에 따른 이미지 경로를 가져옴
    final markerImagePath =
        keywordMarkerImages[keyword] ?? 'assets/default_marker.png';

    // 원하는 크기 지정 (width와 height는 조정하고 싶은 크기로 설정)
    final markerIcon = await _createCustomMarkerImage(
        markerImagePath, 128, 128); // 128x128 크기로 설정

    final markerId = MarkerId(position.toString());

    final marker = Marker(
      markerId: markerId,
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: markerIcon,
      onTap: () {
        _onMarkerTapped(context, MarkerId(position.toString()));
      },
    );

    setState(() {
      _markers.add(marker);
      _allMarkers.add(marker); //모든 마커 저장
      _filteredMarkers = _allMarkers; // 모든 마커를 필터링된 마커로 설정
      _markerKeywords[marker.markerId] = keyword ?? ''; //키워드 저장
      _saveMarker(marker, keyword, markerImagePath); //키워드와 hue 값을 포함한 마커 저장
      _updateSearchResults(_searchController.text);
    });

    // 마커 데이터를 Map으로 변환하여 오프라인/온라인 저장 처리
    final markerData = {
      'id': markerId.value,
      'title': title,
      'description': snippet,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'synced': 0, // 처음엔 비동기화 상태로 저장
    };

    // 오프라인/온라인 상태에 따라 마커를 저장
    await _markerService.saveMarkerOfflineOrOnline(markerData);

    // 클러스터링을 새로 갱신하여 지도에 마커를 반영
    _applyMarkersToCluster(); // 클러스터 갱신
  }

  void _onSearchSubmitted(String query) async {
    // 1. 사용자 마커 검색
    // 검색어가 비어 있는 경우
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = []; // 검색 결과를 비웁니다.
      });
      return; // 검색을 중단합니다.
    } else {
      final filteredMarkers = _markers.where((marker) {
        final title = marker.infoWindow.title?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();

      // 중복 제거: MarkerId로 중복 확인
      final uniqueResults = {
        for (var marker in filteredMarkers) marker.markerId: marker
      }.values.toList();

      setState(() {
        _searchResults = uniqueResults;
      });
    }

    // 2. Places API (new) POST 요청: Find Place from Text

    // 인코딩 : 사람이 읽을수 있는 문자열 -> URL-safe 문자열
    // ex) Uri.encodeComponent("서울역 & 강남역")
    //     결과: %EC%84%9C%EC%9A%B8%EC%97%AD%20%26%20%EA%B0%95%EB%82%A8%EC%97%AD
    // 디코딩 : URL-safe 문자열 -> 사람이 읽을 수 있는 문자열
    // ex) Uri.decodeComponent("%EC%84%9C%EC%9A%B8%EC%97%AD%20%26%20%EA%B0%95%EB%82%A8%EC%97%AD")
    //     결과: "서울역 & 강남역"
    // 즉 인코딩은 사용자 입력값 또는 동적으로 생성된 값이 URL에 포함될 때 사용
    final encodedQuery = Uri.encodeComponent(query);
    // URL 구성 – 여기서는 textsearch 대신 findplacefromtext 대신 textsearch 엔드포인트 사용 예시
    // 만약 findplacefromtext를 사용하려면 아래 URL을 사용하세요:
    // 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$encodedQuery&inputtype=textquery&fields=place_id,name,geometry,formatted_address&language=ko&key=$_apiKey'
    //
    // 여기서는 설명서에 따른 textsearch 엔드포인트(POST)를 사용합니다.
    final placesUrl = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText?&key=${Config.placesApiKey}');

    // 요청 본문 (JSON 형식)
    final requestBody = json.encode({
      "textQuery": query,
      "languageCode": "ko",
    });

    try {
      final placesResponse = await http.post(
        placesUrl,
        headers: {
          'Content-Type': 'application/json',
          // 요청에 필요한 추가 헤더가 있다면 여기에 추가합니다.
          'X-Goog-FieldMask':
              'places.displayName,places.formattedAddress,places.priceLevel,places.location'
        },
        body: requestBody,
      );

      if (placesResponse.statusCode == 200) {
        final placesData = json.decode(placesResponse.body);
        print("Places API Response: ${placesResponse.body}");

        if (placesData['places'] != null &&
            (placesData['places'] as List).isNotEmpty) {
          final placesResults = placesData['places'] as List;
          List<Marker> placesMarkers = [];

          for (var result in placesResults) {
            // 결과에서 장소 정보 추출
            // 예: displayName (텍스트), formattedAddress, 그리고 location (lat, lng)
            final displayName = result['displayName']['text'];
            final formattedAddress = result['formattedAddress'];
            // 예시 응답에서는 "location"이라는 필드가 있어야 합니다.
            final locationJson = result['location'];
            final lat = locationJson['latitude'];
            final lng = locationJson['longitude'];
            final latLng = LatLng(lat, lng);
            // place_id가 없는 경우에는 fallback으로 displayName 사용 (여기서는 간단히 처리)
            final placeId = result['place_id'] ?? displayName;

            placesMarkers.add(
              Marker(
                markerId: MarkerId(placeId),
                position: latLng,
                infoWindow:
                    InfoWindow(title: displayName, snippet: formattedAddress),
              ),
            );
          }

          setState(() {
            _searchResults = placesMarkers;
          });

          // 첫 번째 결과로 지도 이동
          if (placesMarkers.isNotEmpty) {
            final firstResult = placesMarkers.first.position;
            _controller?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: firstResult, zoom: 20),
              ),
            );
          }
        } else {
          print("No places API results found.");
        }
      } else {
        print("Failed to fetch data: ${placesResponse.statusCode}");
        print("Error Response: ${placesResponse.body}");
      }
    } catch (e) {
      print("Error during Places API call: $e");
    }

    // 3. geocoding API를 사용하여 주소반환
    try {
      List<geocoding.Location> locations =
          await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latlng = LatLng(location.latitude, location.longitude);

        //지도 위치 이동
        if (_controller != null) {
          _controller!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: latlng,
                zoom: 20, // 확대 비율
              ),
            ),
          );
        }
        setState(() {
          _searchResults = [
            Marker(
              markerId: MarkerId('searchLocation'),
              position: latlng,
              infoWindow: InfoWindow(title: query),
            )
          ];
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _updateSearchResults(String query) {
    query = query.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
    } else {
      final filteredMarkers = _markers.where((marker) {
        final title = marker.infoWindow.title?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();

      // 중복 제거: MarkerId로 중복 확인
      final uniqueResults = {
        for (var marker in filteredMarkers) marker.markerId: marker
      }.values.toList();

      setState(() {
        _searchResults = uniqueResults;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final List<String> keywords = keywordIcons.keys.toList();

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
                _onItemTapped(0); //구글 맵 화면으로 이동
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
                    builder: (context) => MainPage(),
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
                    builder: (context) => FriendManagementPage(),
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
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              setState(() {
                // 컨트롤러가 초기화되었음을 알림
                _isMapInitialized = true;
              });
              _loadMarkers();
              _applyMarkersToCluster(); // 클러스터 매니저 초기화
              _controller!.setMapStyle(mapStyle);

              //현재 위치가 설정된 경우 카메라 이동
              if (_currentLocation != null) {
                _controller!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(_currentLocation!.latitude!,
                          _currentLocation!.longitude!),
                      zoom: 15,
                    ),
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentLocation?.latitude ?? _seoulCityHall.latitude,
                _currentLocation?.longitude ?? _seoulCityHall.longitude,
              ),
              zoom: 15.0,
            ),
            zoomControlsEnabled: false,
            // 확대/축소 버튼 숨기기
            myLocationEnabled: true,
            // 내 위치 아이콘 표시 여부
            myLocationButtonEnabled: false,
            // 내 위치 아이콘 표시 여부
            markers: Set<Marker>.of(_clusterManager.getClusteredMarkers()),
            // 클러스터링된 마커 사용
            onTap: (latLng) => _onMapTapped(context, latLng),
            onCameraMove: (CameraPosition position) {
              setState(() {
                _currentZoom = position.zoom;
              });
              _updateClusters();
            },
          ),

          // 검색창 (지도 위)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Builder(
              builder: (context) => Container(
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
                        onSubmitted: _onSearchSubmitted,
                        onChanged: _updateSearchResults,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.white),
                      onPressed: () =>
                          _onSearchSubmitted(_searchController.text),
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
          Positioned(
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
                  final icon = keywordIcons[keyword]; // 해당 키워드에 맞는 아이콘 가져오기
                  final isActive = _activeKeywords.contains(keyword);
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 5.0),
                    // 키워드 버튼 간격 조정
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.grey : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 12),
                        // horizontal : 가로 방향에 각각 몇 픽셀의 패딩을 추가
                        // vertical: 세로 방향에 각각 몇 픽셀의 패딩을 추가 (Textstyle에 값과 비슷하게 설정할것)
                      ),
                      onPressed: () {
                        _toggleKeyword(keyword);
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
          ),
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
                    _moveToCurrentLocation();
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location),
                ),
                SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: _showUserLists,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.list),
                )
              ],
            ),
          ),
          // 검색창에 입력한 제목을 화면 하단에 검색 결과를 표시하는 기능
          if (_searchResults.isNotEmpty) ...[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Dismissible(
                key: ValueKey('searchResultsBottomSheet'),
                direction: DismissDirection.down, // 아래로 스와이프 가능
                onDismissed: (direction) {
                  setState(() {
                    _searchResults.clear(); // 스와이프하면 검색 결과 숨김
                  });
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4, // 화면의 40% 높이 제한
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
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
                          padding: EdgeInsets.zero, //리스트 상하 여백 제거
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                          itemBuilder: (context, index) {
                            final marker = _searchResults[index];
                            final keyword = _markerKeywords[marker.markerId];
                            final icon = keywordIcons[keyword];

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
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (keyword != null && keyword.isNotEmpty)
                                    Container(
                                      margin: EdgeInsets.only(left: 8),
                                      padding:
                                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(icon, color: Colors.black, size: 16),
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
                                marker.infoWindow.snippet ?? '',
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
  void initState() {
    super.initState();
    _getAddressFromCoordinates(
      widget.initialLatLng.latitude,
      widget.initialLatLng.longitude,
    );
  }

  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        setState(() {
          final placemark = placemarks.first;
          _address =
              '${placemark.country ?? ''} ${placemark.administrativeArea ?? ''} ${placemark.locality ?? ''} ${placemark.street ?? ''}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _address = 'Error fetching address';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> keywords = keywordIcons.keys.toList();

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
              onPressed: _pickImage,
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
  final Function(Marker, String) onSave;
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
                    Icon(
                      Icons.title,
                      color: Colors.black,
                    ),
                    SizedBox(width: 8), // 아이콘과 텍스트 사이의 간격
                    Text(
                      marker.infoWindow.title ?? '제목 없음',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        color: Colors.black, //제목을 강조하기 위해 색상 적용
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.touch_app, //터치 힌트 아이콘
                      color: Colors.grey,
                      size: 20,
                    ),
                    Text(
                      '클릭하여 자세히 보기',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4), // 제목과 언더바 사이의 간격
                Container(
                  height: 2, //언더바의 두께
                  color: Colors.black, // 언더바의 색상
                  width: double.infinity, // 언더바의 길이를 화면 너비에 맞춤
                ),
                SizedBox(height: 8), // 언더바와 힌트 텍스트 사이의 간격
              ],
            ),
          ),
          Text(marker.infoWindow.snippet ?? ''),
          Row(
            children: [
              Icon(
                Icons.label, // 키워드 옆에 표시할 아이콘
                color: Colors.blue, // 아이콘 색상 설정
              ),
              SizedBox(height: 10),
              Text(
                '$keyword',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }
}
