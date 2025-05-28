import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/marker_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:markers_cluster_google_maps_flutter/markers_cluster_google_maps_flutter.dart';
import '../config.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class MapSampleViewModel extends ChangeNotifier {
  List<Marker> _clusteredMarkers = [];
  File? _image;
  File? get image => _image;
  Marker? _selectedMarker; // 선택된 마커를 저장
  Marker? get selectedMarker => _selectedMarker; // 외부에서 접근용 getter
  final Map<MarkerId, String> _markerKeywords = {}; //마커의 키워드 저장
  Set<Marker> _allMarkers = {}; // 모든 마커 저장
  Set<Marker>  _filteredMarkers = {}; // 필터링된 마커 저장
  Set<Marker>  get filteredMarkers => _filteredMarkers; // 필터링된 마커 저장
  Map<String, IconData> get keywordIcons => _keywordIcons;
  List<Marker> get clusteredMarkers => _clusteredMarkers;
  LatLng? _currentLocation;
  LatLng? get currentLocation => _currentLocation;
  LatLng get seoulCityHall => _seoulCityHall;
  String get mapStyle => _mapStyle;
  double get currentZoom => _currentZoom;
  set currentZoom(double value) {_currentZoom = value;}
  double _currentZoom = 15.0; // 초기 줌 레벨
  Set<String> activeKeywords = {}; //활성화 된 키워드 저장
  final location.Location _location = location.Location();
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _controller;
  set controller(GoogleMapController controller) {
    _controller = controller;
  }
  MarkersClusterManager? _clusterManager;
  MarkersClusterManager? get clusterManager => _clusterManager;
  List<Marker> searchResults = [];
  List<Marker> bookmarkedMarkers = [];
  CollectionReference markersCollection =
  FirebaseFirestore.instance.collection('users');
  List<QueryDocumentSnapshot> _userLists = [];
  List<QueryDocumentSnapshot> get userLists => _userLists;
  final Map<String, String> keywordMarkerImages = {
    '카페': 'assets/cafe_marker.png',
    '호텔': 'assets/hotel_marker.png',
    '사진': 'assets/photo_marker.png',
    '음식점': 'assets/restaurant_marker.png',
    '전시회': 'assets/exhibition_marker.png',
  };
  final MarkerService _markerService = MarkerService();
  static const LatLng _seoulCityHall = LatLng(37.5665, 126.9780);
  final String _mapStyle = '''
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
  final Map<String, IconData> _keywordIcons = {
    '카페': Icons.local_cafe,
    '호텔': Icons.hotel,
    '사진': Icons.camera_alt,
    '음식점': Icons.restaurant,
    '전시회': Icons.art_track,
  };

  void setMapController(GoogleMapController controller) {
    _controller = controller;
  }

  Future<void> toggleKeyword(String keyword) async {
      if (activeKeywords.contains(keyword)) {
        activeKeywords.remove(keyword);
      } else {
        activeKeywords.add(keyword);
      }

      if (activeKeywords.isEmpty) {
        _filteredMarkers = _allMarkers;
      } else {
        _filteredMarkers = _allMarkers.where((marker) {
          final markerKeyword = _markerKeywords[marker.markerId]?.toLowerCase() ?? '';
          return activeKeywords.contains(markerKeyword);
        }).toSet();
      }

      print("Active Keywords: $activeKeywords");
      print("Filtered Markers Count: ${_filteredMarkers.length}");

      await applyMarkersToCluster(); // 클러스터 매니저에 필터링된 마커 적용
      notifyListeners(); // 상태 변경알림
  }

  void onItemTapped(int index) {
    // 구글 맵 화면으로 이동하는 경우 맵 초기화
    if (index == 0 && _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(_seoulCityHall, 15.0),
      );
    }
  }

  Future<String> getAddressFromCoordinates(double latitude,
      double longitude) async {
    try {
      List<geocoding.Placemark> placemarks =
      await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.country ?? ''} ${placemark.administrativeArea ??
            ''} ${placemark.locality ?? ''} ${placemark.street ?? ''}';
      }
      return 'Unknown Address';
    } catch (e) {
      print('Error getting address: $e');
      return 'Error fetching address'; // Error message
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _image = File(pickedFile.path);
      notifyListeners();// 상태 변경 알림
    }
  }

  void addMarker({
    required String? title,
    required String? snippet,
    required LatLng position,
    required String keyword,
    required void Function(MarkerId) onTapCallback, // 👈 콜백 추가
  }) async {
    // 키워드에 따른 이미지 경로를 가져옴
    final markerImagePath = keywordMarkerImages[keyword] ?? 'assets/default_marker.png';
    // 원하는 크기 지정 (width와 height는 조정하고 싶은 크기로 설정)
    final markerIcon = await createCustomMarkerImage(markerImagePath, 128, 128); // 128x128 크기로 설정
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
        onTapCallback(markerId);
      },
    );

      _markers.add(marker);
      _allMarkers.add(marker); //모든 마커 저장
      _filteredMarkers = _allMarkers; // 모든 마커를 필터링된 마커로 설정
      _markerKeywords[marker.markerId] = keyword ?? ''; //키워드 저장
      saveMarker(marker, keyword, markerImagePath); //키워드와 hue 값을 포함한 마커 저장
      updateSearchResults(_searchController.text);

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
    applyMarkersToCluster(); // 클러스터 갱신
  }

  Future<void> loadMarkers() async {
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
            ? await createCustomMarkerImage(
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
            onMarkerTapped(MarkerId(doc.id));
          },
        );
        _markers.add(marker); //화면에 표시될 마커만 _markers에 저장
        _allMarkers.add(marker); //모든 마커 저장
        _markerKeywords[marker.markerId] = data['keyword'] ?? '';
      }

      _filteredMarkers = _allMarkers; //초기 상태에서 모든 마커 표시
      // 클러스터 갱신
      await applyMarkersToCluster();
      notifyListeners(); // 상태 변경 알림
    }
  }

  Future<BitmapDescriptor> createCustomMarkerImage(String imagePath, int width, int height) async {
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

  Future<void> applyMarkersToCluster() async {
    if (_clusterManager == null) {
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
          if (_controller == null) return;
          _controller!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: position, zoom: 16.0),
            ),
          );
        },
      );
    }

    _clusteredMarkers.clear();
    print('Applying ${_filteredMarkers.length} filtered markers to cluster');

    for (var marker in _filteredMarkers) {
      if (!_clusteredMarkers.any((m) => m.markerId == marker.markerId)) {
        _clusterManager!.addMarker(marker);
        _clusteredMarkers.add(marker);
      }
    }

    await updateClusters();
  }


  Future<void> updateClusters() async {
    if (_clusterManager != null) {
      await _clusterManager!.updateClusters(zoomLevel: _currentZoom);
    }
    notifyListeners();
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

        _markers.removeWhere((m) => m.markerId == updatedMarker.markerId);
        _markers.add(newMarker);
        _allMarkers.removeWhere((m) => m.markerId == updatedMarker.markerId);
        _allMarkers.add(newMarker);

        notifyListeners(); // 상태 변경 알림

      updateMarker(newMarker, keyword, markerImagePath);
    }
  }

  void updateMarker(Marker marker, String keyword,
      String markerImagePath) async {
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
  void saveMarker(Marker marker, String keyword,
      String markerImagePath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_markers');

      // 좌표로부터 주소를 가져온다
      String address = await getAddressFromCoordinates(
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

  void getLocation() async {
    final hasPermission = await _location.hasPermission();
    if (hasPermission == location.PermissionStatus.denied) {
      final requested = await _location.requestPermission();
      if (requested != location.PermissionStatus.granted) {
        // 권한이 없을 때 처리
        return;
      }
    }
    final locationData = await _location.getLocation();
    _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
    notifyListeners();

    // 위치 변경 스트림 구독
    _location.onLocationChanged.listen((location.LocationData newLocationData) {
      _currentLocation = LatLng(
        newLocationData.latitude!,
        newLocationData.longitude!,
      );
      notifyListeners();
    });
  }

  Future<List<QueryDocumentSnapshot>> getUserLists() async {
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

  void moveToCurrentLocation() async {
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

  Marker? getMarkerById(MarkerId markerId) {
    try {
      return _markers.firstWhere((m) => m.markerId == markerId);
    } catch (e) {
      return null; // 못 찾으면 null 반환
    }
  }

  void deleteMarker(Marker marker) {
    _markers.removeWhere((m) => m.markerId == marker.markerId);
    notifyListeners();
  }



  Future<void> onMarkerTapped(MarkerId markerId) async {
    final marker = _markers.firstWhere(
          (m) => m.markerId == markerId,
      orElse: () => throw Exception('Marker not found for ID: $markerId'),
    );
    // 마커 위치로 카메라 이동 (await 작업은 마커를 눌렀을때만 적용 나머지는 불필요함)
    print('Marker Position: ${marker.position}');

    if (_controller == null) {
      print("GoogleMapController has not been initialized yet.");
      return;
    }

    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(marker.position, 18.0),
    );

    _selectedMarker = marker;
    notifyListeners(); // View가 마커 상태를 알 수 있도록 알림
  }

  void updateSearchResults(String query) {
    query = query.trim();

    if (query.isEmpty) {
        searchResults.clear();
    } else {
      final filteredMarkers = _markers.where((marker) {
        final title = marker.infoWindow.title?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();

      // 중복 제거: MarkerId로 중복 확인
      final uniqueResults = {
        for (var marker in filteredMarkers) marker.markerId: marker
      }.values.toList();

        searchResults = uniqueResults;
    }
  }

  void onSearchSubmitted(String query) async {
    // 1. 사용자 마커 검색
    // 검색어가 비어 있는 경우
    if (query.trim().isEmpty) {
        searchResults = []; // 검색 결과를 비웁니다.
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
        searchResults = uniqueResults;
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

            searchResults = placesMarkers;

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
          searchResults = [
            Marker(
              markerId: MarkerId('searchLocation'),
              position: latlng,
              infoWindow: InfoWindow(title: query),
            )
          ];
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void showUserLists(BuildContext context) async {
    List<QueryDocumentSnapshot> userLists = await getUserLists();

    if (userLists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장된 리스트가 없습니다')),
      );
      return;
    }
  }
}





