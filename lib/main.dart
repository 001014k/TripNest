import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertrip/Dashboard_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class MapSampleState extends State<MapSample> {
  final Map<MarkerId, String> _markerKeywords = {}; //마커의 키워드 저장
  Set<Marker> _allMarkers = {}; // 모든 마커 저장
  Set<Marker> _filteredMarkers = {}; // 필터링된 마커 저장
  Set<String> _activeKeywords = {}; //활성화 된 키워드 저장
  GoogleMapController? _controller;
  Marker? _selectedMarker;
  LatLng? _pendingLatLng;
  location.LocationData? _currentLocation;
  final location.Location _location = location.Location();
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  late GoogleMapController _mapController;
  String? _result;
  List<Marker> _searchResults = [];
  List<Marker> bookmarkedMarkers = [];
  CollectionReference markersCollection =
      FirebaseFirestore.instance.collection('users');
  int _selectedIndex = 0;
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
          final markerKeyword =
              _markerKeywords[marker.markerId]?.toLowerCase() ?? '';
          return _activeKeywords.contains(markerKeyword);
        }).toSet();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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
      setState(() async {
        _markers.clear();
        _allMarkers.clear();
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String keyword = data['keyword'] ?? 'default';
          final String? markerImagePath = keywordMarkerImages[keyword];

          // 커스텀 마커 이미지 로드 (비동기 처리)
          final BitmapDescriptor markerIcon = markerImagePath != null
              ? await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(48, 48)),
            markerImagePath,
          )
            : BitmapDescriptor.defaultMarkerWithHue(
        data['hue'] != null
        ? (data['hue'] as num).toDouble()
            : BitmapDescriptor.hueOrange,
        );

          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['lat'], data['lng']),
            infoWindow: InfoWindow(
              title: data['title'],
              snippet: data['snippet'],
            ),
            icon: markerIcon,
            onTap: () {
              _onMarkerTapped(context, MarkerId(doc.id));
            },
          );
          _markers.add(marker);
          _allMarkers.add(marker); //모든 마커 저장
          _markerKeywords[marker.markerId] = data['keyword'] ?? '';
        }
        _filteredMarkers = _allMarkers; //초기 상태에서 모든 마커 표시
      });
    }
  }

  Future<void> _showMarkersInVisibleRegion() async {
    if (_controller == null) return;

    LatLngBounds bounds = await _controller!.getVisibleRegion();

    // LatLngBounds의 northEast와 southWest를 사용하여 중앙 좌표 계산
    LatLng center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    setState(() {
      _filteredMarkers = _allMarkers.where((marker) {
        return bounds.contains(marker.position);
      }).toSet();
    });

    // 사용자의 위치를 지도 중앙으로 이동
    _controller!.animateCamera(CameraUpdate.newLatLng(center));
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


  Future<void> _updateMarker(Marker marker, String keyword, String markerImagePath) async {
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
  Future<void> _saveMarker(Marker marker, String keyword, String markerImagePath) async {
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
            final markerImagePath = keywordMarkerImages[updatedKeyword] ?? 'assets/default_marker.png';
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

  Future<Uint8List> _bitmapDescriptorToBytes(
      BitmapDescriptor descriptor) async {
    // BitmapDescriptor를 바이트로 변환하는 로직을 추가해야 합니다.
    return Uint8List(0);
  }

  Future<Uint8List> _fileToBytes(File file) async {
    return file.readAsBytes();
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

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  void _moveToCurrentLocation() {
    if (_controller != null && _currentLocation != null) {
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentLocation!.latitude!,
              _currentLocation!.longitude!,
            ),
            zoom: 30,
          ),
        ),
      );
    }
  }

  void _onMarkerTapped(BuildContext context, MarkerId markerId) {
    final marker = _markers.firstWhere(
      (m) => m.markerId == markerId,
      orElse: () => throw Exception('Marker not found for ID: $markerId'),
    );
    setState(() {
      _selectedMarker = marker;
    });
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
            final markerImagePath = keywordMarkerImages[keyword] ?? 'assets/default_marker.png';
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
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              onTap: () {
                setState(() {
                  // _allMarkers의 내용을 _filteredMarkers로 복사하여 초기화
                  _filteredMarkers = Set<Marker>.from(_allMarkers);
                });
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

  void _addMarker(
      String? title, String? snippet, LatLng position, String keyword) async {
    // 키워드에 따른 이미지 경로를 가져옴
    final markerImagePath = keywordMarkerImages[keyword] ?? 'assets/default_marker.png';

    // 이미지 경로에 따른 커스텀 마커 생성
    final markerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(24, 24), devicePixelRatio: 1.0),
      markerImagePath,
    );

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
  }

  void _onSearchSubmitted(String query) async {

    // 검색어가 비어 있는 경우
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = []; // 검색 결과를 비웁니다.
      });
      return; // 검색을 중단합니다.
    }

    //1. 기존 마커 제목 검색기능
    setState(() {
      _searchResults = _markers.where((marker) {
        final title = marker.infoWindow.title?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();
    });

    // 2. geocoding API를 사용하여 주소반환
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
        // 모든 마커에 대한 검색을 새로 고침
        //_updateSearchResults(query);
        // 3. 검색 결과를 화면에 표시
        _showSearchResults();
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 검색 결과에 대한 로직
  void _showSearchResults() {
    showModalBottomSheet(
      context: context,
      isDismissible: true, // 하단 시트를 드래그 하여 내릴수 있게 설정
      enableDrag: true, // 하단 시트 드래그 기능 활성화
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final marker = _searchResults[index];
              return ListTile(
                leading: Icon(Icons.location_on, color: Colors.red,),
                title: Text(
                  marker.infoWindow.title ?? 'Untitled',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _controller?.animateCamera(
                    CameraUpdate.newLatLng(marker.position),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _updateSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
    } else {
      setState(() {
        _searchResults = _markers.where((marker) {
          final title = marker.infoWindow.title?.toLowerCase() ?? '';
          return title.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, //햄버거 아이콘 색상을 화이트 색상으로 변경
        ),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '주소 및 마커검색...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: TextStyle(color: Colors.white),
          onChanged: _updateSearchResults,
          onSubmitted: _onSearchSubmitted,
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            color: Colors.white,
            onPressed: () => _onSearchSubmitted(_searchController.text),
          ),
        ],
      ),
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
                            title: Text('로그아웃 확인'),
                            content: Text('로그아웃하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text('예'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text('아니오'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pop(); // Drawer 닫기
                        Navigator.of(context).pushReplacementNamed('/login'); // 로그인 화면으로 이동
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
              title: Text('지도'),
              onTap: () {
                _onItemTapped(0); //구글 맵 화면으로 이동
              },
            ),
            ListTile(
              leading: Icon(
                Icons.account_circle,
                color: Colors.grey[850],
              ),
              title: Text('프로필'),
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
            ListTile(
              leading: Icon(
                Icons.list,
                color: Colors.grey[850],
              ),
              title: Text('북마크/리스트'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MainPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _loadMarkers();
              _controller!.setMapStyle(mapStyle);
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
            zoomControlsEnabled: false, // 확대/축소 버튼 숨기기
            myLocationEnabled: true,
            // 내 위치 아이콘 표시 여부
            myLocationButtonEnabled: false,
            //GPS 버튼 비활성화
            markers: Set<Marker>.from(_filteredMarkers),
            //필터링된 마커를 사용
            onTap: (latLng) => _onMapTapped(context, latLng),
          ),
          if (_searchResults.isNotEmpty) ...[
            // 화면 하단에 검색 결과를 표시하는 기능
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final marker = _searchResults[index];
                    return ListTile(
                      title: Text(marker.infoWindow.title ?? 'Untitled'),
                      subtitle: Text(marker.infoWindow.snippet ?? ''),
                      onTap: () {
                        _controller?.animateCamera(
                          CameraUpdate.newLatLng(marker.position),
                        );
                        setState(() {
                          _selectedMarker = marker;
                        });
                        _showMarkerInfoBottomSheet(context, marker,
                            (Marker markerToDelte) {
                          // 여기에 마커 삭제 로직 추가
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
          Positioned(
            top: 20.0,
            left: 0,
            right: 0,
            child: Container(
              height: 40.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: keywords.length,
                itemBuilder: (context, index) {
                  final keyword = keywords[index];
                  final isActive = _activeKeywords.contains(keyword);
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 5.0),
                    // 키워드 버튼 간격 조정
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.grey : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10),
                        // horizontal : 가로 방향에 각각 몇 픽셀의 패딩을 추가
                        // vertical: 세로 방향에 각각 몇 픽셀의 패딩을 추가 (Textstyle에 값과 비슷하게 설정할것)
                      ),
                      onPressed: () {
                        _toggleKeyword(keyword);
                      },
                      child: Text(
                        keyword,
                        style: TextStyle(
                            color: Colors.black, fontSize: 12), // 글씨 크기 조정
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
                  onPressed: _moveToCurrentLocation,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location),
                ),
                SizedBox(height: 16),
                FloatingActionButton(
                    onPressed: _showMarkersInVisibleRegion,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.place)),
                SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: _showUserLists,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.list),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> keywords = ['카페', '호텔', '사진', '음식점', '전시회'];

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
                    )
                  ],
                ),
                SizedBox(height: 4), // 제목과 언더바 사이의 간격
                Container(
                  height: 2, //언더바의 두께
                  color: Colors.black, // 언더바의 색상
                  width: double.infinity, // 언더바의 길이를 화면 너비에 맞춤
                ),
                SizedBox(height: 8), // 언더바와 힌트 텍스트 사이의 간격
                Text(
                  '클릭하여 자세히 보기',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
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