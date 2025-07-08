import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import '../services/marker_service.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart'as cluster_manager;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import '../viewmodels/add_markers_to_list_viewmodel.dart';

class MapSampleViewModel extends ChangeNotifier {
  Set<Marker> _clusteredMarkers = {};
  Set<Marker> get clusteredMarkers => _clusteredMarkers;

  Set<Marker> _filteredMarkers = {};
  Set<Marker> get filteredMarkers => _filteredMarkers;

  Set<Marker> get displayMarkers {
    if (currentZoom >= 15) {
      return _filteredMarkers; // 개별 마커
    } else {
      return _clusteredMarkers.toSet(); // 클러스터 마커
    }
  }

  // 리스트별로 순서가 있는 마커 저장
  List<Marker> _orderedMarkers = [];
  List<Marker> get orderedMarkers => _orderedMarkers;

  List<LatLng> _polygonPoints = [];
  List<LatLng> get polygonPoints => _polygonPoints;


  cluster_manager.ClusterManager<Place>? _clusterManager;
  cluster_manager.ClusterManager<Place>? get clusterManager => _clusterManager;

  List<Place> _filteredPlaces = [];
  Set<Marker> _allMarkers = {}; // 모든 마커 저장

  List<Marker> _searchResults = [];
  List<Marker> get searchResults => _searchResults;
  void clearSearchResults() {
    searchResults.clear();
    notifyListeners();
  }

  void Function(Marker)? onMarkerTappedCallback; // 마커 클릭 콜백
  File? _image;
  File? get image => _image;
  Marker? _selectedMarker; // 선택된 마커를 저장
  Marker? get selectedMarker => _selectedMarker; // 외부에서 접근용 getter
  final Map<MarkerId, String> _markerKeywords = {}; //마커의 키워드 저장
  String getKeywordByMarkerId(String markerId) {
    return _markerKeywords[MarkerId(markerId)] ?? '';
  }
  LatLng? _currentLocation;
  LatLng? get currentLocation => _currentLocation;
  LatLng get seoulCityHall => _seoulCityHall;
  String get mapStyle => _mapStyle;
  double currentZoom = 15.0; // 초기 줌 레벨
  Set<String> activeKeywords = {}; //활성화 된 키워드 저장
  final location.Location _location = location.Location();
  late Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _controller;
  set controller(GoogleMapController controller) {
    _controller = controller;
  }
  List<Marker> bookmarkedMarkers = [];
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _userLists = [];
  List<Map<String, dynamic>> get userLists => _userLists;
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

  Map<String, IconData> get keywordIcons => _keywordIcons;

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

        // 중복 마커 제거
        final uniqueMarkerMap = <MarkerId, Marker>{};
        for (var marker in filteredMarkers) {
          uniqueMarkerMap[marker.markerId] = marker;
        }
        _filteredMarkers = uniqueMarkerMap.values.toSet();
      }

      // 키워드에 맞게 클러스터링에 있는 마커 갯수 표현
      _filteredPlaces = _filteredMarkers.map((marker){
        return Place(
          id: marker.markerId.value,
          title: marker.infoWindow.title ?? '',
          snippet: marker.infoWindow.snippet ?? '',
          latLng: marker.position,
        );
      }).toList();

      print("Active Keywords: $activeKeywords");
      print('Filtered Markers count: ${_filteredMarkers.length}');
      print('Filtered Marker IDs: ${_filteredMarkers.map((m) => m.markerId.value).toSet().length}');

      print('Clustered Markers count: ${_clusteredMarkers.length}');
      print('Clustered Marker IDs: ${_clusteredMarkers.map((m) => m.markerId.value).toSet().length}');

      _clusterManager?.setItems(_filteredPlaces); // 키워드에 맞게 클러스터링에 있는 마커 갯수 표현
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

  void addMarker({
    required String? title,
    required String? snippet,
    required LatLng position,
    required String keyword,
    required void Function(MarkerId) onTapCallback,
  }) async {
    final markerImagePath = keywordMarkerImages[keyword] ?? 'assets/default_marker.png';
    final markerIcon = await createCustomMarkerImage(markerImagePath, 128, 128);
    final markerId = MarkerId(position.toString());

    final marker = Marker(
      markerId: markerId,
      position: position,
      infoWindow: InfoWindow(title: title, snippet: snippet),
      icon: markerIcon,
      onTap: () {
        onTapCallback(markerId);
      },
    );

    _markers.add(marker);
    _allMarkers.add(marker);
    _filteredMarkers = _allMarkers;
    _markerKeywords[marker.markerId] = keyword;

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client.from('user_markers').insert({
          'user_id': user.id,
          'title': title,
          'snippet': snippet,
          'lat': position.latitude,
          'lng': position.longitude,
          'keyword': keyword,
          'marker_image_path': markerImagePath,
        }).select();

        print('Insert 성공: $response');
      } catch (error) {
        print('Supabase insert 실패: $error');
      }
    }


    _filteredPlaces = _filteredMarkers.map((marker) {
      return Place(
        id: marker.markerId.value,
        title: marker.infoWindow.title ?? '',
        snippet: marker.infoWindow.snippet ?? '',
        latLng: marker.position,
      );
    }).toList();

    _clusterManager?.setItems(_filteredPlaces);
    notifyListeners();
  }


  Future<void> loadMarkers() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('user_markers')
        .select()
        .eq('user_id', user.id);

    _markers.clear();
    _allMarkers.clear();
    final Map<MarkerId, Marker> uniqueMarkersMap = {};

    for (var data in response) {
      final String keyword = data['keyword'] ?? 'default';
      final String? markerImagePath = keywordMarkerImages[keyword];

      final BitmapDescriptor markerIcon = markerImagePath != null
          ? await createCustomMarkerImage(markerImagePath, 128, 128)
          : BitmapDescriptor.defaultMarkerWithHue(
        data['hue'] != null
            ? (data['hue'] as num).toDouble()
            : BitmapDescriptor.hueOrange,
      );

      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();

      final markerId = MarkerId(data['id']);
      final marker = Marker(
        markerId: markerId,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: data['title'],
          snippet: data['snippet'],
        ),
        icon: markerIcon,
        onTap: () {
          onMarkerTapped(markerId);
        },
      );

      uniqueMarkersMap[markerId] = marker;
      _markerKeywords[markerId] = keyword;
    }

    _markers = uniqueMarkersMap.values.toSet();
    _allMarkers = uniqueMarkersMap.values.toSet();
    _filteredMarkers = _allMarkers.toSet();

    _filteredPlaces = _filteredMarkers.map((marker) {
      return Place(
        id: marker.markerId.value,
        title: marker.infoWindow.title ?? '',
        snippet: marker.infoWindow.snippet ?? '',
        latLng: marker.position,
      );
    }).toList();

    _clusterManager?.setItems(_filteredPlaces);
    _clusterManager?.updateMap();
    notifyListeners();
  }

  void clearPolylines() {
    _polygonPoints.clear();
    notifyListeners();
  }

  Future<void> reorderMarkers(int oldIndex, int newIndex, String listId, AddMarkersToListViewModel addMarkersVM) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final marker = _orderedMarkers.removeAt(oldIndex);
    _orderedMarkers.insert(newIndex, marker);
    _polygonPoints = _orderedMarkers.map((m) => m.position).toList();

    // context.read 대신, 인스턴스를 직접 전달받아 사용
    await addMarkersVM.updateMarkerOrders(listId, _orderedMarkers);
    await loadMarkersForList(listId);
    _updatePolygonPoints();
    notifyListeners();
  }


  void _updatePolygonPoints() {
    _polygonPoints = _orderedMarkers.map((m) => m.position).toList();
  }


  Future<void> loadMarkersForList(String listId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('list_bookmarks')
        .select('id, title, snippet, lat, lng, keyword')
        .eq('list_id', listId)
        .order('order')
        .limit(100) // optional
        .withConverter<List<Map<String, dynamic>>>((data) => data as List<Map<String, dynamic>>);

    final markers = await Future.wait(response.map((doc) async {
      final String keyword = doc['keyword']?.toString() ?? 'default';
      final String? markerImagePath = keywordMarkerImages[keyword];

      final BitmapDescriptor markerIcon = markerImagePath != null
          ? await createCustomMarkerImage(markerImagePath, 128, 128)
          : BitmapDescriptor.defaultMarkerWithHue(
        (doc['hue'] as num?)?.toDouble() ?? BitmapDescriptor.hueOrange,
      );

      return Marker(
        markerId: MarkerId(doc['id']),
        position: LatLng(doc['lat'], doc['lng']),
        infoWindow: InfoWindow(
          title: doc['title'] ?? '제목 없음',
          snippet: doc['snippet'] ?? '설명 없음',
        ),
        icon: markerIcon,
        onTap: () => onMarkerTapped(MarkerId(doc['id'])),
      );
    }).toList());

    _orderedMarkers = markers;
    _polygonPoints = _orderedMarkers.map((m) => m.position).toList();
    setFilteredMarkers(markers);
    notifyListeners();
  }


  Future<Marker> Function(cluster_manager.Cluster<Place>) get _markerBuilder => (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),       // 클러스터 ID
          position: cluster.location,                 // 클러스터 위치
          icon: await _getMarkerBitmap(
            cluster.isMultiple ? 125 : 75,           // 클러스터 크기 다르게
            text: cluster.isMultiple ? cluster.count.toString() : null,  // 묶음 개수 표시
          ),
          onTap: () async {
            if (cluster.isMultiple) {
              if (_controller != null) {
                _controller!.animateCamera(
                  CameraUpdate.newLatLngZoom(cluster.location, 15),
                );
              }
            } else {
              onSinglePlaceTap(cluster.items.first);
            }
            print('클러스터 클릭됨: ${cluster.getId()} - 아이템 개수: ${cluster.count}');
            cluster.items.forEach((item) => print(item));
          },
        );
      };

  void onSinglePlaceTap(Place place) {
    // 여기서 place에 대한 상세 처리 구현
    print('단일 마커 클릭됨: ${place.title}');
    // 예: _selectedPlace = place; notifyListeners(); 등
  }

  Future<BitmapDescriptor> _getMarkerBitmap(int size, {String? text}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = Colors.blue;   // 외곽 원 색
    final Paint paint2 = Paint()..color = Colors.white;  // 내부 원 색

    // 외곽 원
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);
    // 내부 원
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    // 더 작은 외곽 원
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.8, paint1);

    // 텍스트가 있으면 중앙에 숫자 표시
    if (text != null) {
      TextPainter painter = TextPainter(
        textDirection: TextDirection.ltr,
      );
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size / 3,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    // 이미지로 변환
    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }


  Future<void> applyMarkersToCluster(GoogleMapController controller) async {
    if (_clusterManager == null) {
      _clusterManager = cluster_manager.ClusterManager<Place>(
        _filteredPlaces,
        _updateMarkers,
        markerBuilder: _markerBuilder,
        levels: [1, 5, 10, 15, 20],
        extraPercent: 0.2,
      );
      _clusterManager!.setMapId(controller.mapId);
    } else {
      _clusterManager!.setItems(_filteredPlaces);
    }

    // 클러스터 업데이트
    _clusterManager!.updateMap();
  }

  void onCameraMove(CameraPosition position) {
    currentZoom = position.zoom;
    notifyListeners();
  }

  void _updateMarkers(markers) {
    _clusteredMarkers = markers.toSet();
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

  Future<BitmapDescriptor> createCustomMarkerImage(String imagePath, int width, int height) async {
    print('커스텀 마커 이미지 생성 시작: $imagePath, 크기: ${width}x$height');
    // 이미지 파일 로드
    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List bytes = data.buffer.asUint8List();

    // 이미지 디코딩 및 크기 조정
    final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: width, targetHeight: height);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData =
    await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

    // 크기 조정된 이미지 데이터를 바이트 배열로 변환
    final Uint8List resizedBytes = byteData!.buffer.asUint8List();

    print('커스텀 마커 이미지 생성 완료: $imagePath');
    // BitmapDescriptor로 변환
    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  void updateMarker(Marker marker, String keyword, String markerImagePath) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('user_markers')
          .update({
        'title': marker.infoWindow.title,
        'snippet': marker.infoWindow.snippet,
        'keyword': keyword,
        'marker_image_path': markerImagePath,
      })
          .eq('user_id', user.id)
          .eq('id', marker.markerId.value);

      if (response.error != null) {
        print('Error updating marker: ${response.error!.message}');
      }
    }
  }

// 파이어베이스: 'set' vs 'update'
// set: 기존 문서를 덮어 쓰거나 문서가 없을 경우 새로 생성
// update: 문서가 이미 존재하는 경우에만 특정 필드를 수정하며 문서가 존재하지 않으면 에러를 발생


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

  // 리스트에 있는 마커를 필터링하여 지도에 표시
  void setFilteredMarkers(List<Marker> markers) {
    _filteredMarkers = markers.toSet();

    _filteredPlaces = markers.map((marker) {
      return Place(
        latLng: marker.position,
        title: marker.infoWindow.title ?? '',
        snippet: marker.infoWindow.snippet ?? '',
        id: marker.markerId.value,
      );
    }).toList();

    // 클러스터 매니저에 새 데이터 세팅
    if (_clusterManager != null) {
      _clusterManager!.setItems(_filteredPlaces);
      _clusterManager!.updateMap();
    }

    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getUserLists() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('lists')
          .select()
          .eq('user_id', user.id);

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching user lists: $e');
      return [];
    }
  }

  void moveToCurrentLocation() async {
    if (_controller != null && _currentLocation != null) {
      LatLng currentLatLng = LatLng(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
      );

      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 18.0),
      );
    }
  }

  Marker? getMarkerById(MarkerId markerId) {
    try {
      return _markers.firstWhere((m) => m.markerId == markerId);
    } catch (e) {
      return null;
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

    if (_controller == null) {
      print("GoogleMapController has not been initialized yet.");
      return;
    }

    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(marker.position, 18.0),
    );

    _selectedMarker = marker;
    notifyListeners();

    onMarkerTappedCallback?.call(marker);
  }

  void updateSearchResults(String query) {
    query = query.trim();

    if (query.isEmpty) {
      _searchResults.clear();
    } else {
      final filteredMarkers = _markers.where((marker) {
        final title = marker.infoWindow.title?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();

      final uniqueResults = {
        for (var marker in filteredMarkers) marker.markerId: marker
      }.values.toList();

      _searchResults = uniqueResults;
    }

    notifyListeners();
  }

  void onSearchSubmitted(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    // 1. 사용자 마커 필터링
    final filteredMarkers = _markers.where((marker) {
      final title = marker.infoWindow.title?.toLowerCase() ?? '';
      return title.contains(query.toLowerCase());
    }).toList();

    final uniqueResults = {
      for (var marker in filteredMarkers) marker.markerId: marker
    }.values.toList();

    _searchResults = uniqueResults;

    // 2. Places API 호출 (places:searchText)
    final placesUrl = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText?&key=${Config.placesApiKey}');
    final requestBody = json.encode({
      "textQuery": query,
      "languageCode": "ko",
    });

    try {
      final placesResponse = await http.post(
        placesUrl,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-FieldMask':
          'places.displayName,places.formattedAddress,places.location,places.id',
        },
        body: requestBody,
      );

      if (placesResponse.statusCode == 200) {
        final placesData = json.decode(placesResponse.body);
        print("Places API Response: ${placesResponse.body}");

        if (placesData['places'] != null && (placesData['places'] as List).isNotEmpty) {
          final placesResults = placesData['places'] as List;
          List<Marker> placesMarkers = [];

          for (var result in placesResults) {
            final placeId = result['id'] ?? '';
            final formattedAddress = result['formattedAddress'] ?? '';
            final locationJson = result['location'];
            final lat = locationJson['latitude'];
            final lng = locationJson['longitude'];
            final latLng = LatLng(lat, lng);

            String? title;
            String displayNameRaw = result['displayName']?['text']?.trim() ?? '';

            // 1단계: displayName이 의미 있고 숫자만 아니면 우선 사용
            if (displayNameRaw.isNotEmpty && !RegExp(r'^\d+$').hasMatch(displayNameRaw)) {
              title = displayNameRaw;
            }

            // 2단계: displayName이 숫자거나 무의미하면 Place Details API 호출해서 장소명 가져오기
            if (title == null || title.trim().isEmpty || RegExp(r'^\d+$').hasMatch(displayNameRaw)) {
              try {
                final detailsUrl = Uri.parse(
                    'https://maps.googleapis.com/maps/api/place/details/json'
                        '?place_id=$placeId&language=ko&fields=name,formatted_address&key=${Config.placesApiKey}'
                );
                final detailsResponse = await http.get(detailsUrl);

                if (detailsResponse.statusCode == 200) {
                  final detailsData = json.decode(detailsResponse.body);
                  final result = detailsData['result'];

                  if (result != null) {
                    final placeName = result['name'] ?? '';
                    final placeAddress = result['formatted_address'] ?? '';

                    if (placeName.isNotEmpty) {
                      title = placeName;
                    }
                    if (placeAddress.isNotEmpty) {
                      // 필요시 주소 업데이트
                      // formattedAddress = placeAddress;
                    }
                  }
                } else {
                  print("Place Details API failed: ${detailsResponse.statusCode}");
                }
              } catch (e) {
                print("Place Details API exception: $e");
              }
            }

            // 3단계: 그래도 title 없으면 geocoding fallback
            if (title == null || title.trim().isEmpty) {
              try {
                List<geocoding.Placemark> placemarks =
                await geocoding.placemarkFromCoordinates(lat, lng);
                if (placemarks.isNotEmpty) {
                  final place = placemarks.first;
                  title = place.name ??
                      place.street ??
                      place.locality ??
                      formattedAddress ??
                      query;
                }
              } catch (e) {
                print("Geocoding fallback failed: $e");
                title = formattedAddress.isNotEmpty ? formattedAddress : query;
              }
            }

            final finalTitle = title ?? query;
            final finalAddress = formattedAddress;

            print('Marker added: title=$finalTitle, address=$finalAddress');

            placesMarkers.add(
              Marker(
                markerId: MarkerId(placeId),
                position: latLng,
                infoWindow: InfoWindow(
                  title: finalTitle,
                  snippet: finalAddress,
                ),
              ),
            );
          }

          _searchResults = placesMarkers;

          if (placesMarkers.isNotEmpty) {
            final firstResult = placesMarkers.first.position;
            _controller?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: firstResult, zoom: 20),
              ),
            );
          }

          notifyListeners();
          return;
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

    // 3. Places API 실패 시 Geocoding fallback
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latlng = LatLng(location.latitude, location.longitude);

        String fallbackAddress = '';
        try {
          List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            fallbackAddress =
                "${place.administrativeArea ?? ''} ${place.locality ?? ''} ${place.street ?? ''}".trim();
          }
        } catch (e) {
          print("Placemark parsing failed: $e");
        }

        _searchResults = [
          Marker(
            markerId: MarkerId('geocodingFallback'),
            position: latlng,
            infoWindow: InfoWindow(
              title: query,
              snippet: fallbackAddress,
            ),
          )
        ];

        _controller?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: latlng,
              zoom: 20,
            ),
          ),
        );
      }
    } catch (e) {
      print('Geocoding search failed: $e');
    }

    notifyListeners();
  }
}