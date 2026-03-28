import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:location/location.dart' as location;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart' as cluster_manager;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../models/marker_model.dart';
import '../models/place_model.dart';
import '../viewmodels/add_markers_to_list_viewmodel.dart';
import 'package:geolocator/geolocator.dart';

class MapSampleViewModel extends ChangeNotifier {
  void Function(Marker)? onSearchMarkerTapped;
  void Function(List<Marker> searchMarkers)? onSearchCompleted;

  Marker? temporaryMarker; // 임시 마커 저장용

  // 리스트에 저장된 마커 목록을 저장할 필드 추가
  List<MarkerModel> currentMarkers = [];

  // (또는 getter만 구현)
  // List<MarkerModel> get currentMarkers => _markersFromSelectedList;

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

  set clusterManager(cluster_manager.ClusterManager<Place>? manager) {
    _clusterManager = manager;
  }

  // list_bookmarks 테이블의 row id를 marker_id로 역참조하기 위한 매핑
  final Map<String, String> _listBookmarkRowIdByMarkerId = {};

  List<Place> _filteredPlaces = [];
  Set<Marker> _allMarkers = {}; // 모든 마커 저장

  List<Marker> _searchResults = [];

  List<Marker> get searchResults => _searchResults;

  String? _selectedListId;

  String? get selectedListId => _selectedListId;

  void setSelectedListId(String? listId) {
    _selectedListId = listId;
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
  double currentZoom = 14.0; // 초기 줌 레벨
  Set<String> activeKeywords = {}; //활성화 된 키워드 저장
  final location.Location _location = location.Location();
  late Set<Marker> _markers = {};
  GoogleMapController? _controller;

  GoogleMapController? get controller => _controller;

  set controller(GoogleMapController? controller) {
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

  bool _isDisposed = false;

  void clearSearchResults() {
    _searchResults.clear();
    temporaryMarker = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _clusterManager = null;
    _controller = null;
    super.dispose();
  }

  Future<void> _forceClusterUpdate() async {
    if (_isDisposed || _controller == null || _clusterManager == null) return;

    debugPrint('Forcing cluster update...');

    int retry = 0;
    const maxRetry = 5;
    while (retry < maxRetry) {
      try {
        await _controller!.getVisibleRegion(); // Check if channel is ready
        _clusterManager!.updateMap();
        notifyListeners(); // Notify UI to rebuild with new markers
        debugPrint('Force cluster update successful.');
        break;
      } catch (e) {
        retry++;
        debugPrint('Force cluster update failed, retry $retry/$maxRetry: $e');
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }


  // Map detach용 안전 메서드
  void detachMap() {
    if (controller != null && clusterManager != null) {
      try {
        clusterManager!.setMapId(controller!.mapId); // null 대신 안전하게 mapId 사용
      } catch (e) {
        debugPrint('detachMap: setMapId failed: $e');
      }
    }

    clusterManager = null;
    controller = null;
  }

  void setMapController(GoogleMapController controller) {
    _controller = controller;
  }

  void clearMarkers() {
    // 클러스터링 마커 초기화
    _clusteredMarkers.clear();

    // 필터링된 마커 초기화
    _filteredMarkers.clear();

    // 모든 마커 초기화
    _allMarkers.clear();

    // 검색 결과 초기화
    _searchResults.clear();

    // 클러스터용 Place 리스트 초기화
    _filteredPlaces.clear();

    // 순서가 있는 마커 초기화
    _orderedMarkers.clear();

    // 선택된 마커 초기화
    _selectedMarker = null;

    // 키워드 맵 초기화
    _markerKeywords.clear();

    // 북마크된 마커 초기화
    bookmarkedMarkers.clear();

    // 현재 위치는 유지할 수도 있고, 필요하면 초기화
    // _currentLocation = null;

    // 🔐 클러스터 매니저 dispose + null 처리
    _clusterManager = null;

    // 필요하면 구글맵 컨트롤러도 null 처리 (대개는 안 함)
    // _controller = null;

    notifyListeners();
  }

  void initializeMap(MarkerId? markerId) {
    if (markerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onMarkerTapped(markerId); // 해당 마커로 카메라 이동
      });
    }
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
        final markerKeyword =
            _markerKeywords[marker.markerId]?.toLowerCase() ?? '';
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
    _filteredPlaces = _filteredMarkers.map((marker) {
      return Place(
        id: marker.markerId.value,
        title: marker.infoWindow.title ?? '',
        snippet: marker.infoWindow.snippet ?? '',
        latLng: marker.position,
      );
    }).toList();

    print("Active Keywords: $activeKeywords");
    print('Filtered Markers count: ${_filteredMarkers.length}');
    print(
        'Filtered Marker IDs: ${_filteredMarkers
            .map((m) => m.markerId.value)
            .toSet()
            .length}');

    print('Clustered Markers count: ${_clusteredMarkers.length}');
    print(
        'Clustered Marker IDs: ${_clusteredMarkers
            .map((m) => m.markerId.value)
            .toSet()
            .length}');

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
    String? listId,
    required String address,
  }) async {
    final uuid = const Uuid().v4(); // ✅ UUID 생성
    final markerId = MarkerId(uuid);

    final markerImagePath =
        keywordMarkerImages[keyword] ?? 'assets/default_marker.png';
    final markerIcon = await createCustomMarkerImage(markerImagePath, 128, 128);

    final marker = Marker(
      markerId: markerId,
      position: position,
      infoWindow: const InfoWindow(title: '', snippet: ''),
      // ✅ 말풍선 숨기기
      icon: markerIcon,
      onTap: () => onTapCallback(markerId),
    );

    _markers.add(marker);
    _allMarkers.add(marker);
    _filteredMarkers = _allMarkers;
    _markerKeywords[marker.markerId] = keyword;

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response =
        await Supabase.instance.client.from('user_markers').insert({
          'id': uuid, // ✅ 여기서 Supabase에 저장할 마커 ID
          'user_id': user.id,
          'title': title,
          'snippet': snippet,
          'lat': position.latitude,
          'lng': position.longitude,
          'keyword': keyword,
          'marker_image_path': markerImagePath,
          'address': address,
        }).select();

        print('Insert 성공: $response');
      } catch (error) {
        print('Supabase insert 실패: $error');
      }

      if (listId != null) {
        try {
          await Supabase.instance.client.from('list_bookmarks').insert({
            'list_id': listId,
            'marker_id': uuid,
            'title': title,
            'keyword': keyword,
            'lat': position.latitude,
            'lng': position.longitude,
            'snippet': snippet,
            'created_at': DateTime.now().toIso8601String(),
          });
          print('list_bookmarks Insert 성공');
        } catch (error) {
          print('list_bookmarks Insert 실패: $error');
        }
      }
    }

    _filteredPlaces = _filteredMarkers.map((marker) {
      return Place(
        id: marker.markerId.value, // ✅ UUID가 들어감
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
          snippet: data['address']
              ?.toString()
              .isNotEmpty == true
              ? data['address']
              : '주소 정보 없음', // 또는 data['snippet'] 써도 됨
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

  void _updateMarkers(markers) {
    debugPrint('Updating clustered markers count: ${markers.length}');
    _clusteredMarkers = markers.toSet();
    notifyListeners();
  }

  void clearPolylines() {
    _polygonPoints.clear();
    notifyListeners();
  }

  Future<void> reorderMarkers(int oldIndex,
      int newIndex,
      String listId,
      AddMarkersToListViewModel addMarkersVM,) async {
    if (oldIndex < newIndex) newIndex -= 1;

    final marker = _orderedMarkers.removeAt(oldIndex);
    _orderedMarkers.insert(newIndex, marker);

    _polygonPoints = _orderedMarkers.map((m) => m.position).toList();
    _updatePolygonPoints();
    notifyListeners();

    try {
      await updateMarkerOrdersForList(listId);
      print('✅ updateMarkerOrdersForList 호출 성공');
    } catch (e) {
      print('❌ updateMarkerOrdersForList 호출 에러: $e');
    }
    await loadMarkersForList(listId); // 여기서 notifyListeners 포함
  }

  void _updatePolygonPoints() {
    _polygonPoints = _orderedMarkers.map((m) => m.position).toList();
  }

  Future<void> loadMarkersForList(String listId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('list_bookmarks')
        .select(
        'id, marker_id, title, snippet, lat, lng, keyword, sort_order') // sort_order도 같이 받아서 출력해보기
        .eq('list_id', listId)
        .order('sort_order', ascending: true) // 정렬 보장
        .limit(100)
        .withConverter<List<Map<String, dynamic>>>((data) => data as List<Map<String, dynamic>>);

    print('DB에서 불러온 마커 ID 및 순서:');
    for (final item in response) {
      print('ID: ${item['id']}, sort_order: ${item['sort_order']}');
    }

    // 매핑 초기화 후 최신 매핑 저장
    _listBookmarkRowIdByMarkerId.clear();

    final markers = await Future.wait(response.map((doc) async {
      final String rowId = doc['id']?.toString() ?? '';
      final String markerIdStr = doc['marker_id']?.toString() ?? '';
      if (rowId.isNotEmpty && markerIdStr.isNotEmpty) {
        _listBookmarkRowIdByMarkerId[markerIdStr] = rowId;
      }
      final String keyword = doc['keyword']?.toString() ?? 'default';
      final String? markerImagePath = keywordMarkerImages[keyword];

      final BitmapDescriptor markerIcon = markerImagePath != null
          ? await createCustomMarkerImage(markerImagePath, 128, 128)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

      return Marker(
        markerId: MarkerId(doc['marker_id']),
        position: LatLng(doc['lat'], doc['lng']),
        infoWindow: InfoWindow(
          title: doc['title'] ?? '제목 없음',
          snippet: doc['snippet'] ?? '설명 없음',
        ),
        icon: markerIcon,
        onTap: () => onMarkerTapped(MarkerId(doc['marker_id'])),
      );
    }).toList());

    print(
        'ViewModel _orderedMarkers ID 순서: ${markers
            .map((m) => m.markerId.value)
            .toList()}');
    _orderedMarkers = markers;
    setFilteredMarkers(markers);
    notifyListeners();
  }

  void showPolyline() {
    _polygonPoints = _orderedMarkers.map((m) => m.position).toList();
    notifyListeners();
  }

  Future<void> updateMarkerOrdersForList(String listId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // 현재 메모리상의 순서를 list_bookmarks의 row id 기준으로 변환
    print('updateMarkerOrdersForList: _orderedMarkers.length=${_orderedMarkers
        .length}');
    print('updateMarkerOrdersForList: ordered markerIds=${_orderedMarkers.map((
        m) => m.markerId.value).toList()}');
    print(
        'updateMarkerOrdersForList: mapping keys=${_listBookmarkRowIdByMarkerId
            .keys.toList()}');
    final List<Map<String, dynamic>> orders = _orderedMarkers
        .asMap()
        .entries
        .map((entry) {
      final int index = entry.key;
      final String markerId = entry.value.markerId.value;
      final String? rowId = _listBookmarkRowIdByMarkerId[markerId];
      if (rowId == null) return null;
      return {
        'id': rowId, // list_bookmarks의 PK id
        'sort_order': index,
      };
    })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (orders.isEmpty) {
      print(
          '⚠️ updateMarkerOrdersForList: 업데이트할 orders가 비어있습니다. 매핑 리프레시를 시도합니다.');
      await _ensureRowIdMappingForList(listId);

      final refreshedOrders = _orderedMarkers
          .asMap()
          .entries
          .map((entry) {
        final int index = entry.key;
        final String markerId = entry.value.markerId.value;
        final String? rowId = _listBookmarkRowIdByMarkerId[markerId];
        if (rowId == null) return null;
        return {
          'id': rowId,
          'sort_order': index,
        };
      })
          .whereType<Map<String, dynamic>>()
          .toList();

      if (refreshedOrders.isEmpty) {
        print(
            '⚠️ updateMarkerOrdersForList: 리프레시 후에도 orders 비어있음 → marker_id 기반 폴백 업데이트 수행');
        await _fallbackUpdateOrdersByMarkerId(listId);
        return;
      }

      // 리프레시된 orders로 진행
      await _performRpcOrFallback(listId, refreshedOrders);
      return;
    }

    await _performRpcOrFallback(listId, orders);
  }

  Future<void> _performRpcOrFallback(String listId,
      List<Map<String, dynamic>> orders) async {
    try {
      final result = await Supabase.instance.client.rpc(
        'update_marker_orders',
        params: {
          'p_list_id': listId,
          'p_orders': orders,
        },
      );
      print('✅ RPC(update_marker_orders) 결과: $result');
    } on PostgrestException catch (e) {
      print('❌ RPC PostgrestException: ${e.message}, code=${e.code}');
      print('➡️ 두 단계 폴백(id 기반)을 시도합니다.');
      await _fallbackUpdateOrdersByRowId(listId, orders);
    } catch (e) {
      print('❌ RPC 예외: $e');
      print('➡️ 두 단계 폴백(id 기반)을 시도합니다.');
      await _fallbackUpdateOrdersByRowId(listId, orders);
    }
  }

  Future<void> _fallbackUpdateOrdersByRowId(String listId,
      List<Map<String, dynamic>> orders) async {
    // 1) 현재 최대 sort_order를 조회하여 충돌 없는 스테이징 오프셋 계산
    final int offset = await _getSortOrderOffset(listId);
    print('fallbackByRowId: using offset=$offset');

    // 2) 1차: 각 행을 고유한 스테이징 값으로 이동 (offset + index)
    for (final order in orders) {
      final String rowId = order['id'] as String;
      final int index = order['sort_order'] as int;
      final int stagingOrder = offset + index;
      try {
        await Supabase.instance.client
            .from('list_bookmarks')
            .update({'sort_order': stagingOrder})
            .eq('id', rowId)
            .eq('list_id', listId);
      } on PostgrestException catch (e) {
        print('❌ 1차(스테이징) 업데이트 실패 (row id=$rowId): ${e.message}');
      } catch (e) {
        print('❌ 1차(스테이징) 업데이트 예외 (row id=$rowId): $e');
      }
    }

    // 3) 2차: 최종 인덱스로 정렬 값 재설정
    for (final order in orders) {
      final String rowId = order['id'] as String;
      final int finalOrder = order['sort_order'] as int;
      try {
        await Supabase.instance.client
            .from('list_bookmarks')
            .update({'sort_order': finalOrder})
            .eq('id', rowId)
            .eq('list_id', listId);
      } on PostgrestException catch (e) {
        print('❌ 2차(최종) 업데이트 실패 (row id=$rowId): ${e.message}');
      } catch (e) {
        print('❌ 2차(최종) 업데이트 예외 (row id=$rowId): $e');
      }
    }

    print('✅ 폴백 개별 업데이트(id 기반, 2단계) 완료');
  }

  Future<void> _fallbackUpdateOrdersByMarkerId(String listId) async {
    final List<Map<String, dynamic>> markerIdOrders = _orderedMarkers
        .asMap()
        .entries
        .map((entry) =>
    {
      'marker_id': entry.value.markerId.value,
      'sort_order': entry.key,
    })
        .toList();

    // 1) 현재 최대 sort_order를 조회하여 충돌 없는 스테이징 오프셋 계산
    final int offset = await _getSortOrderOffset(listId);
    print('fallbackByMarkerId: using offset=$offset');

    // 2) 1차: 스테이징 값으로 이동
    for (final order in markerIdOrders) {
      final String markerId = order['marker_id'] as String;
      final int index = order['sort_order'] as int;
      final int stagingOrder = offset + index;
      try {
        await Supabase.instance.client
            .from('list_bookmarks')
            .update({'sort_order': stagingOrder})
            .eq('list_id', listId)
            .eq('marker_id', markerId);
      } on PostgrestException catch (e) {
        print('❌ 1차(스테이징) 업데이트 실패 (marker_id=$markerId): ${e.message}');
      } catch (e) {
        print('❌ 1차(스테이징) 업데이트 예외 (marker_id=$markerId): $e');
      }
    }

    // 3) 2차: 최종 인덱스로 재설정
    for (final order in markerIdOrders) {
      final String markerId = order['marker_id'] as String;
      final int finalOrder = order['sort_order'] as int;
      try {
        await Supabase.instance.client
            .from('list_bookmarks')
            .update({'sort_order': finalOrder})
            .eq('list_id', listId)
            .eq('marker_id', markerId);
      } on PostgrestException catch (e) {
        print('❌ 2차(최종) 업데이트 실패 (marker_id=$markerId): ${e.message}');
      } catch (e) {
        print('❌ 2차(최종) 업데이트 예외 (marker_id=$markerId): $e');
      }
    }

    print('✅ 폴백 개별 업데이트(marker_id 기반, 2단계) 완료');
  }

  Future<int> _getSortOrderOffset(String listId) async {
    try {
      final rows = await Supabase.instance.client
          .from('list_bookmarks')
          .select('sort_order')
          .eq('list_id', listId);
      int maxOrder = -1;
      for (final row in rows as List) {
        final dynamic v = row['sort_order'];
        if (v is int) {
          if (v > maxOrder) maxOrder = v;
        } else if (v is num) {
          final int vi = v.toInt();
          if (vi > maxOrder) maxOrder = vi;
        }
      }
      return maxOrder + 1000; // 넉넉한 오프셋
    } catch (e) {
      print('sort_order offset 조회 실패: $e');
      return 1000; // 조회 실패 시 기본 오프셋
    }
  }

  Future<void> _ensureRowIdMappingForList(String listId) async {
    try {
      final rows = await Supabase.instance.client
          .from('list_bookmarks')
          .select('id, marker_id')
          .eq('list_id', listId);

      _listBookmarkRowIdByMarkerId.clear();
      for (final row in rows as List) {
        final String rowId = row['id']?.toString() ?? '';
        final String markerId = row['marker_id']?.toString() ?? '';
        if (rowId.isNotEmpty && markerId.isNotEmpty) {
          _listBookmarkRowIdByMarkerId[markerId] = rowId;
        }
      }

      print('ensureRowIdMapping: mapping size=${_listBookmarkRowIdByMarkerId
          .length}');
    } catch (e) {
      print('ensureRowIdMapping 실패: $e');
    }
  }

  Future<Marker> Function(cluster_manager.Cluster<Place>) get _markerBuilder =>
          (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()), // 클러스터 ID
          position: cluster.location, // 클러스터 위치
          icon: await _getMarkerBitmap(
            cluster.isMultiple ? 125 : 75, // 클러스터 크기 다르게
            text: cluster.isMultiple
                ? cluster.count.toString()
                : null, // 묶음 개수 표시
          ),
          onTap: () async {
            if (cluster.isMultiple) {
              if (_controller != null) {
                final currentZoom = await _controller!.getZoomLevel();

                double nextZoom = currentZoom + 2; // Force a 2-level jump
                if (nextZoom > 21) nextZoom = 21; // Cap at max zoom

                await _controller!.animateCamera(
                  CameraUpdate.newLatLngZoom(cluster.location, nextZoom),
                );

                await Future.delayed(const Duration(milliseconds: 300));
                await _forceClusterUpdate();
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
    final Paint paint1 = Paint()
      ..color = Colors.blue; // 외곽 원 색
    final Paint paint2 = Paint()
      ..color = Colors.white; // 내부 원 색

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

  Future<void> applyMarkersToCluster(GoogleMapController? controller) async {
    if (_isDisposed || controller == null) return;

    debugPrint(
        'applyMarkersToCluster called with ${_filteredPlaces.length} places');

    // iOS에서 네이티브 채널 안정화를 위한 딜레이
    if (Platform.isIOS) await Future.delayed(const Duration(milliseconds: 400));

    // ClusterManager 초기화
    if (_clusterManager == null) {
      _clusterManager = cluster_manager.ClusterManager<Place>(
        _filteredPlaces,
        _updateMarkers,
        markerBuilder: _markerBuilder,
        levels: [1, 4, 7, 9, 11, 13, 15, 16, 17, 18, 20],
        extraPercent: 0.2,
      );

      try {
        _clusterManager!.setMapId(controller.mapId);
      } catch (e) {
        debugPrint('setMapId failed: $e');
        return; // 채널 연결 실패 시 종료
      }
    } else {
      _clusterManager!.setItems(_filteredPlaces);
    }

    // updateMap 안전 실행 (채널 준비 확인 + 재시도)
    int retry = 0;
    const maxRetry = 5;
    while (retry < maxRetry) {
      try {
        await controller.getVisibleRegion(); // 채널 연결 확인
        _clusterManager!.updateMap(); // updateMap은 void
        break; // 성공하면 루프 종료
      } catch (e) {
        retry++;
        debugPrint('getVisibleRegion not ready, retry $retry/$maxRetry: $e');
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  void setTemporaryMarker(Marker marker) {
    temporaryMarker = marker;
    notifyListeners();
  }

  void clearTemporaryMarker() {
    temporaryMarker = null;
    notifyListeners();
  }


  void onCameraMove(CameraPosition position) {
    currentZoom = position.zoom;
    _currentCameraPosition = position;
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

  Future<BitmapDescriptor> createCustomMarkerImage(String imagePath, int width,
      int height) async {
    print('커스텀 마커 이미지 생성 시작: $imagePath, 크기: ${width}x$height');
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

    print('커스텀 마커 이미지 생성 완료: $imagePath');
    // BitmapDescriptor로 변환
    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  void updateMarker(Marker marker, String keyword,
      String markerImagePath) async {
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
      // 1️⃣ 내가 생성한 리스트
      final List<dynamic> myLists = await Supabase.instance.client
          .from('lists')
          .select()
          .eq('user_id', user.id);

      // 2️⃣ 내가 멤버로 속한 리스트
      final List<dynamic> invitedLists = await Supabase.instance.client
          .from('list_members')
          .select('lists(*)') // list_members에 연결된 리스트를 가져오기
          .eq('user_id', user.id);

      // invitedLists에서 lists 필드만 추출
      final List<Map<String, dynamic>> invitedListsData = invitedLists
          .map<Map<String, dynamic>>((item) =>
      item['lists'] as Map<String, dynamic>)
          .toList();

      // 3️⃣ 합치고 중복 제거
      final Map<String, Map<String, dynamic>> tempLists = {};

      for (var list in myLists.cast<Map<String, dynamic>>()) {
        tempLists[list['id']] = list;
      }
      for (var list in invitedListsData) {
        tempLists[list['id']] = list;
      }

      return tempLists.values.toList();
    } catch (e) {
      print('Error fetching user lists: $e');
      return [];
    }
  }

  Future<void> checkLocationPermissionAndFetch() async {
    print("📍 checkLocationPermissionAndFetch 호출됨");
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ 위치 권한이 거부되었습니다.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ 위치 권한이 영구적으로 거부되었습니다.');
      return;
    }

    // ✅ 위치 권한이 허용된 경우
    Position position = await Geolocator.getCurrentPosition();
    _currentLocation = LatLng(position.latitude, position.longitude);
    print('✅ 현재 위치: $_currentLocation');

    // ✅ 지도 이동: controller가 초기화된 뒤라면 바로 이동
    if (_controller != null) {
      moveToCurrentLocation();
    } else {
      // ❗ controller가 아직 null이면 이후에 한 번 더 이동 시도
      Future.delayed(Duration(milliseconds: 500), () {
        if (_controller != null && _currentLocation != null) {
          moveToCurrentLocation();
        }
      });
    }

    notifyListeners();
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

  Future<Map<String, String>> fetchMarkerDetail(String markerId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return {
      'title': '제목 없음',
      'address': '주소 없음',
      'keyword': '키워드 없음',
    };
    }

    try {
      final data = await Supabase.instance.client
          .from('user_markers')
          .select('title, address, keyword')
          .eq('id', markerId)
          .maybeSingle();

      return {
        'title': data?['title'] ?? '제목 없음',
        'address': data?['address'] ?? '주소 없음',
        'keyword': data?['keyword'] ?? '키워드 없음',
      };
    } catch (e) {
      print('마커 정보 로딩 오류: $e');
      return {
        'title': '오류 발생',
        'address': '',
        'keyword': '',
      };
    }
  }


  void deleteMarker(Marker marker) {
    _markers.removeWhere((m) => m.markerId == marker.markerId);
    notifyListeners();
  }

  void updateSearchResults(String query) {
    query = query.trim();

    if (query.isEmpty) {
      _searchResults.clear();
      temporaryMarker = null; // 🔹 임시 마커 제거
      print("ℹ️ 검색어 비움 → 임시 마커 제거 및 검색 결과 초기화");
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

  // 실시간 지도 중심 위치 저장용 변수 추가
  CameraPosition _currentCameraPosition = const CameraPosition(
    target: LatLng(37.5665, 126.9780), // 초기값: 서울 (fallback)
    zoom: 15,
  );

  CameraPosition get currentCameraPosition => _currentCameraPosition;


  Future<void> onSearchSubmitted(String query) async {
    query = query.trim();
    if (query.isEmpty) {
      _searchResults = [];
      temporaryMarker = null;
      notifyListeners();
      return;
    }

    final originalQuery = query;

    // 기존 사용자 마커 필터링
    final filteredMarkers = _markers.where((m) {
      final title = m.infoWindow.title?.toLowerCase() ?? '';
      return title.contains(originalQuery.toLowerCase());
    }).toList();

    _searchResults = {for (var m in filteredMarkers) m.markerId: m}.values.toList();

    try {
      // Places API 호출
      double centerLat = _currentCameraPosition.target.latitude;
      double centerLng = _currentCameraPosition.target.longitude;

      if (centerLat == 37.5665 && centerLng == 126.9780 && _currentLocation != null) {
        centerLat = _currentLocation!.latitude;
        centerLng = _currentLocation!.longitude;
      }

      final placesUrl = Uri.parse(
          'https://places.googleapis.com/v1/places:searchText?key=${Env.googleMapsApiKey}');

      final requestBody = json.encode({
        "textQuery": originalQuery,
        "languageCode": "ko",
        "maxResultCount": 20,
        "rankPreference": "DISTANCE",
        "locationBias": {
          "circle": {
            "center": {"latitude": centerLat, "longitude": centerLng},
            "radius": 5000.0,
          }
        }
      });

      final placesResponse = await http.post(
        placesUrl,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location',
        },
        body: requestBody,
      );

      if (placesResponse.statusCode == 200) {
        final data = json.decode(placesResponse.body);
        final list = (data['places'] as List?) ?? [];

        if (list.isNotEmpty) {
          final Map<String, Map<String, dynamic>> uniquePlaces = {};
          for (var place in list) {
            final latStr = place['location']?['latitude']?.toStringAsFixed(6);
            final lngStr = place['location']?['longitude']?.toStringAsFixed(6);
            if (latStr != null && lngStr != null) {
              uniquePlaces.putIfAbsent('$latStr,$lngStr', () => place);
            }
          }

          final newSearchMarkers = <Marker>[];
          int addedCount = 0;

          for (var place in uniquePlaces.values) {
            if (addedCount >= 10) break;

            final lat = place['location']?['latitude'] as double?;
            final lng = place['location']?['longitude'] as double?;
            if (lat == null || lng == null) continue;

            final latLng = LatLng(lat, lng);
            final placeId = place['id'] ?? 'result_$addedCount';

            final marker = Marker(
              markerId: MarkerId('search_$placeId'),
              position: latLng,
              infoWindow: InfoWindow(
                title: place['displayName']?['text'] ?? originalQuery,
                snippet: place['formattedAddress'] ?? '',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
              onTap: () => onMarkerTapped(MarkerId('search_$placeId')),
            );

            newSearchMarkers.add(marker);
            addedCount++;
          }

          _searchResults = [..._searchResults, ...newSearchMarkers];

          // 검색 완료 신호 보내기 (카메라 이동용)
          onSearchCompleted?.call(_searchResults);

          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint("Places 검색 오류: $e");
    }

    notifyListeners();
  }

  Future<void> onMarkerTapped(MarkerId markerId) async {
    // 1. 검색 결과에 없으면 기존 사용자 마커에서 확인
    Marker? marker= _searchResults.firstWhereOrNull(
          (m) => m.markerId == markerId,
    );

    // 1. 검색 결과 마커인지 확인
    marker ??= _allMarkers.cast<Marker>().firstWhereOrNull(
          (m) => m.markerId == markerId,
    );



    if (marker == null) {
      debugPrint("클릭된 마커를 찾을 수 없음: ${markerId.value}");
      return;
    }

    // 카메라 이동 (클릭한 마커 중심)
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(marker.position, 18.0),
    );

    _selectedMarker = marker;
    notifyListeners();

    if (marker.markerId.value.startsWith('search_')) {
      debugPrint("검색 마커 클릭됨: ${markerId.value} -> 생성 화면 이동");

      onSearchMarkerTapped?.call(marker);
    } else {
      onMarkerTappedCallback?.call(marker);
    }
  }
}
