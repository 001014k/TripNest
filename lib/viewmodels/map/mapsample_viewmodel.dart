import '../../services/map/map_marker_repository.dart';
import '../../services/map/map_route_repository.dart';
import '../../services/map/map_search_service.dart';
import '../../design/map_style.dart';
import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:location/location.dart' as location;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart'
    as cluster_manager;
import '../../models/markers/marker_model.dart';
import '../../models/places/place_model.dart';
import '../../services/map/marker_icon_service.dart';
import '../../services/markers/marker_service.dart';
import '../lists/add_markers_to_list_viewmodel.dart';
import 'package:geolocator/geolocator.dart';

class MapSampleViewModel extends ChangeNotifier {
  final MarkerIconService _markerIconService = MarkerIconService();
  MapSampleViewModel(
      {MarkerService? markerService,
      MapSearchService? searchService,
      MapMarkerRepository? markerRepository})
      : _markerService = markerService ?? MarkerService(),
        _searchService = searchService ?? MapSearchService(),
        _markerRepository =
            markerRepository ?? MapMarkerRepository(Supabase.instance.client);
  final MarkerService _markerService;
  final MapSearchService _searchService;
  final MapMarkerRepository _markerRepository;
  int _searchRevision = 0;
  // 확대해도 가까운 장소는 계속 묶고, 확대 단계마다 군집 범위를 줄인다.
  static const List<double> clusterLevels = [
    1,
    4,
    7,
    9,
    11,
    13,
    14,
    15,
    16,
    17,
    18,
    20
  ];
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

  Set<Marker>? _routeMarkers;
  int _routeRevision = 0;

  Set<Marker> get displayMarkers {
    if (_routeMarkers != null) return _routeMarkers!;
    // 클러스터 계산이 끝나기 전에는 저장된 마커를 임시로 표시한다.
    return _clusteredMarkers.isEmpty
        ? _filteredMarkers
        : _clusteredMarkers.toSet();
  }

  // 리스트별로 순서가 있는 마커 저장
  List<Marker> _orderedMarkers = [];

  List<Marker> get orderedMarkers => _orderedMarkers;

  List<LatLng> _polygonPoints = [];

  List<LatLng> get polygonPoints => _polygonPoints;

  cluster_manager.ClusterManager<Place>? clusterManager;
  Timer? _clusterRefreshTimer;

  // list_bookmarks 테이블의 row id를 marker_id로 역참조하기 위한 매핑
  final Map<String, String> _listBookmarkRowIdByMarkerId = {};

  List<Place> _filteredPlaces = [];
  Set<Marker> _allMarkers = {}; // 모든 마커 저장

  final Map<String, Map<String, dynamic>> searchPlaceMetadata = {};
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

  String get mapStyle => tripNestMapStyle;
  double currentZoom = 15.0; // GoogleMap의 initialCameraPosition과 일치
  Set<String> activeKeywords = {}; //활성화 된 키워드 저장
  final location.Location _location = location.Location();
  late Set<Marker> _markers = {};
  GoogleMapController? controller;

  List<Marker> bookmarkedMarkers = [];
  final supabase = Supabase.instance.client;
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> _userLists = [];

  List<Map<String, dynamic>> get userLists => _userLists;
  final Map<String, String> keywordMarkerImages = {
    '카페': 'assets/cafe_marker.png',
    '호텔': 'assets/hotel_marker.png',
    '사진': 'assets/photo_marker.png',
    '음식점': 'assets/restaurant_marker.png',
    '전시회': 'assets/exhibition_marker.png',
    '자연': 'nature',
    '관광명소': 'landmark',
    '쇼핑': 'shopping',
    '체험': 'activity',
  };
  static const LatLng _seoulCityHall = LatLng(37.5665, 126.9780);

  Map<String, IconData> get keywordIcons => _keywordIcons;

  final Map<String, IconData> _keywordIcons = {
    '카페': Icons.local_cafe,
    '호텔': Icons.hotel,
    '사진': Icons.camera_alt,
    '음식점': Icons.restaurant,
    '전시회': Icons.art_track,
    '자연': Icons.park_outlined,
    '관광명소': Icons.account_balance_outlined,
    '쇼핑': Icons.shopping_bag_outlined,
    '체험': Icons.local_activity_outlined,
  };

  bool _isDisposed = false;

  void clearSearchResults() {
    _searchRevision++;
    searchPlaceMetadata.clear();
    _searchResults.clear();
    temporaryMarker = null;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _routeRevision++;
    _searchRevision++;
    _isDisposed = true;
    _clusterRefreshTimer?.cancel();
    clusterManager = null;
    controller = null;
    super.dispose();
  }

  Future<void> fetchAllAccessibleMarkers() async {
    final markerModels = await _markerRepository.loadAccessible();
    if (_isDisposed) return;

    // ✅ 커스텀 아이콘 + 키워드 매핑까지 같이 처리
    final Map<MarkerId, Marker> uniqueMarkersMap = {};
    final Map<MarkerId, String> newKeywords = {};

    for (final model in markerModels) {
      final String keyword = model.keyword;
      final String? markerImagePath = keywordMarkerImages[keyword];

      final BitmapDescriptor markerIcon = markerImagePath != null
          ? await createCustomMarkerImage(markerImagePath, 128, 128)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

      final markerId = MarkerId(model.id);
      final marker = Marker(
        markerId: markerId,
        position: LatLng(model.lat, model.lng),
        infoWindow: InfoWindow(title: model.title),
        icon: markerIcon, // ← 핵심
        onTap: () => onMarkerTapped(markerId),
      );

      uniqueMarkersMap[markerId] = marker;
      newKeywords[markerId] = keyword;
    }

    _allMarkers = uniqueMarkersMap.values.toSet();
    _filteredMarkers = _allMarkers.toSet();
    _markerKeywords.addAll(newKeywords); // 기존 키워드도 유지하면서 추가

    // 클러스터용 Place 업데이트
    _filteredPlaces = _filteredMarkers.map((marker) {
      return Place(
        id: marker.markerId.value,
        title: marker.infoWindow.title ?? '',
        snippet: marker.infoWindow.snippet ?? '',
        latLng: marker.position,
      );
    }).toList();

    clusterManager?.setItems(_filteredPlaces);
    notifyListeners();
  }

  Future<void> _forceClusterUpdate() async {
    if (_isDisposed || controller == null || clusterManager == null) return;

    debugPrint('Forcing cluster update...');

    int retry = 0;
    const maxRetry = 5;
    while (retry < maxRetry) {
      try {
        await controller!.getVisibleRegion(); // 채널이 준비되었는지 확인합니다.
        clusterManager!.updateMap();
        notifyListeners(); // 새 마커로 화면을 다시 구성하도록 UI에 알립니다.
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
    _clusterRefreshTimer?.cancel();
    _clusterRefreshTimer = null;
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
    this.controller = controller;
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
    clusterManager = null;

    // 필요하면 구글맵 컨트롤러도 null 처리 (대개는 안 함)
    // controller = null;

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
    final next = Set<String>.of(activeKeywords);
    if (!next.add(keyword)) next.remove(keyword);
    await applyKeywords(next);
  }

  Future<void> applyKeywords(Set<String> keywords) async {
    activeKeywords = Set<String>.of(keywords);
    if (activeKeywords.isEmpty) {
      _filteredMarkers = _allMarkers.toSet();
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

    debugPrint("Active Keywords: $activeKeywords");
    debugPrint('Filtered Markers count: ${_filteredMarkers.length}');
    debugPrint(
        'Filtered Marker IDs: ${_filteredMarkers.map((m) => m.markerId.value).toSet().length}');

    debugPrint('Clustered Markers count: ${_clusteredMarkers.length}');
    debugPrint(
        'Clustered Marker IDs: ${_clusteredMarkers.map((m) => m.markerId.value).toSet().length}');

    clusterManager?.setItems(_filteredPlaces); // 키워드에 맞게 클러스터링에 있는 마커 갯수 표현
    notifyListeners(); // 상태 변경알림
  }

  void onItemTapped(int index) {
    // 구글 맵 화면으로 이동하는 경우 맵 초기화
    if (index == 0 && controller != null) {
      controller!.animateCamera(
        CameraUpdate.newLatLngZoom(_seoulCityHall, 15.0),
      );
    }
  }

  Future<String?> findSavedPlace(Marker place) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('로그인이 필요합니다.');
    final rows = await client
        .from('user_markers')
        .select('id, title')
        .eq('user_id', user.id)
        .gte('lat', place.position.latitude - .00001)
        .lte('lat', place.position.latitude + .00001)
        .gte('lng', place.position.longitude - .00001)
        .lte('lng', place.position.longitude + .00001);
    final title = (place.infoWindow.title ?? '').trim().toLowerCase();
    for (final row in rows) {
      if ((row['title']?.toString() ?? '').trim().toLowerCase() == title) {
        return row['id'].toString();
      }
    }
    return null;
  }

  Future<bool> addMarker({
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

    var saved = false;
    try {
      saved = await _markerService.createUserMarker(
        id: uuid,
        title: title,
        snippet: snippet,
        latitude: position.latitude,
        longitude: position.longitude,
        keyword: keyword,
        imagePath: markerImagePath,
        address: address,
        listId: listId,
      );
    } catch (error) {
      debugPrint('Supabase insert 실패: $error');
    }

    if (!saved) return false;
    if (_isDisposed) return true;
    _markers.add(marker);
    _allMarkers.add(marker);
    _filteredMarkers = _allMarkers.toSet();
    _markerKeywords[marker.markerId] = keyword;

    _filteredPlaces = _filteredMarkers.map((marker) {
      return Place(
        id: marker.markerId.value, // ✅ UUID가 들어감
        title: marker.infoWindow.title ?? '',
        snippet: marker.infoWindow.snippet ?? '',
        latLng: marker.position,
      );
    }).toList();

    clusterManager?.setItems(_filteredPlaces);
    notifyListeners();
    return true;
  }

  Future<void> loadMarkers() async {
    final response = await _markerRepository.loadOwn();
    if (_isDisposed) return;

    _markers.clear();
    _allMarkers.clear();
    _clusteredMarkers.clear();
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
        infoWindow: InfoWindow(),
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

    clusterManager?.setItems(_filteredPlaces);
    clusterManager?.updateMap();
    notifyListeners();
  }

  Future<void> initializeMapMarkers(GoogleMapController controller) async {
    await loadMarkers();
    try {
      await fetchAllAccessibleMarkers();
    } catch (error) {
      debugPrint('공유 마커 조회 실패: $error');
    }
    await applyMarkersToCluster(controller);
  }

  void _updateMarkers(Set<Marker> markers) {
    debugPrint('Updating clustered markers count: ${markers.length}');
    _clusteredMarkers = markers.toSet();
    notifyListeners();
  }

  void clearPolylines() {
    _routeRevision++;
    _routeMarkers = null;
    _polygonPoints.clear();
    notifyListeners();
  }

  /// 여행 리스트로 좁혀진 지도 표시를 사용자의 전체 마커로 되돌립니다.
  /// 경로 데이터와 마커 데이터는 서로 독립적으로 유지합니다.
  void showAllMarkers() {
    setFilteredMarkers(_allMarkers.toList());
    clusterManager?.updateMap();
  }

  Future<void> reorderMarkers(
    int oldIndex,
    int newIndex,
    String listId,
    AddMarkersToListViewModel addMarkersVM,
  ) async {
    final previous = List<Marker>.of(_orderedMarkers);
    final marker = _orderedMarkers.removeAt(oldIndex);
    _orderedMarkers.insert(newIndex, marker);

    _polygonPoints = _orderedMarkers.map((m) => m.position).toList();
    _updatePolygonPoints();
    notifyListeners();

    try {
      await updateMarkerOrdersForList(listId);
      debugPrint('✅ updateMarkerOrdersForList 호출 성공');
    } catch (e) {
      _orderedMarkers = previous;
      _updatePolygonPoints();
      notifyListeners();
      rethrow;
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
        .isFilter('deleted_at', null)
        .order('sort_order', ascending: true)
        .withConverter<List<Map<String, dynamic>>>((data) => data);

    debugPrint('DB에서 불러온 마커 ID 및 순서:');
    for (final item in response) {
      debugPrint('ID: ${item['id']}, sort_order: ${item['sort_order']}');
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

    debugPrint(
        'ViewModel _orderedMarkers ID 순서: ${markers.map((m) => m.markerId.value).toList()}');
    _orderedMarkers = markers;
    setFilteredMarkers(markers);
    notifyListeners();
  }

  Future<void> startOrderedRoute() async {
    final revision = ++_routeRevision;
    final markers = List<Marker>.of(_orderedMarkers);
    final numbered =
        await Future.wait(markers.asMap().entries.map((entry) async {
      final icon =
          await _markerIconService.createClusterMarker(40, '${entry.key + 1}');
      return entry.value.copyWith(
        iconParam: icon,
        anchorParam: const Offset(.5, .5),
        infoWindowParam: InfoWindow(
          title: '${entry.key + 1}. ${entry.value.infoWindow.title ?? '장소'}',
          snippet: entry.value.infoWindow.snippet,
        ),
      );
    }));
    if (revision != _routeRevision) return;
    _routeMarkers = numbered.toSet();
    _polygonPoints = markers.map((marker) => marker.position).toList();
    notifyListeners();
  }

  void showPolyline() {
    _polygonPoints = _orderedMarkers.map((m) => m.position).toList();
    notifyListeners();
  }

  Future<void> updateMarkerOrdersForList(String listId) => MapRouteRepository(
          _supabase, _orderedMarkers, _listBookmarkRowIdByMarkerId)
      .updateMarkerOrdersForList(listId);

  Future<Marker> Function(cluster_manager.Cluster<Place>) get _markerBuilder =>
      (cluster) async {
        // ===== 2개 이상 → 클러스터 마커 =====
        if (cluster.isMultiple) {
          return Marker(
            markerId: MarkerId(cluster.getId()),
            position: cluster.location,
            icon: await _markerIconService.createClusterMarker(
              cluster.count >= 10 ? 46 : 40,
              cluster.count.toString(),
            ),
            onTap: () async {
              if (controller != null) {
                final currentZoom = await controller!.getZoomLevel();
                double nextZoom = currentZoom + 2;
                if (nextZoom > 21) nextZoom = 21;

                await controller!.animateCamera(
                  CameraUpdate.newLatLngZoom(cluster.location, nextZoom),
                );

                await Future.delayed(const Duration(milliseconds: 300));
                await _forceClusterUpdate();
              }
            },
          );
        }

        // ===== 단일 마커 → 원래 커스텀 마커 사용 =====
        final place = cluster.items.first;
        final markerId = MarkerId(place.id);

        // 이미 만들어둔 커스텀 마커를 재사용
        Marker? original = _filteredMarkers
            .cast<Marker?>()
            .firstWhere((m) => m?.markerId == markerId, orElse: () => null);

        original ??= _allMarkers
            .cast<Marker?>()
            .firstWhere((m) => m?.markerId == markerId, orElse: () => null);

        if (original != null) {
          // 기존 커스텀 아이콘 + onTap 유지
          return original.copyWith(
            onTapParam: () => onMarkerTapped(markerId),
          );
        }

        // 혹시 없을 경우 대비 (fallback)
        final keyword = _markerKeywords[markerId] ?? 'default';
        final markerImagePath =
            keywordMarkerImages[keyword] ?? 'assets/default_marker.png';
        final icon = await createCustomMarkerImage(markerImagePath, 128, 128);

        return Marker(
          markerId: markerId,
          position: place.latLng,
          icon: icon,
          infoWindow: InfoWindow(title: place.title, snippet: place.snippet),
          onTap: () => onMarkerTapped(markerId),
        );
      };

  void onSinglePlaceTap(Place place) {
    // 여기서 place에 대한 상세 처리 구현
    debugPrint('단일 마커 클릭됨: ${place.title}');
    // 예: _selectedPlace = place; notifyListeners(); 등
  }

  Future<void> applyMarkersToCluster(GoogleMapController? controller) async {
    if (_isDisposed || controller == null) return;

    debugPrint(
        'applyMarkersToCluster called with ${_filteredPlaces.length} places');

    // iOS에서 네이티브 채널 안정화를 위한 딜레이
    if (Platform.isIOS) await Future.delayed(const Duration(milliseconds: 400));

    // ClusterManager 초기화
    if (clusterManager == null) {
      clusterManager = cluster_manager.ClusterManager<Place>(
        _filteredPlaces,
        _updateMarkers,
        markerBuilder: _markerBuilder,
        levels: clusterLevels,
        clusterAlgorithm: cluster_manager.ClusterAlgorithm.MAX_DIST,
        extraPercent: 0.2,
      );

      try {
        clusterManager!.setMapId(controller.mapId);
      } catch (e) {
        debugPrint('setMapId failed: $e');
        return; // 채널 연결 실패 시 종료
      }
    } else {
      clusterManager!.setItems(_filteredPlaces);
    }

    // updateMap 안전 실행 (채널 준비 확인 + 재시도)
    int retry = 0;
    const maxRetry = 5;
    while (retry < maxRetry) {
      try {
        await controller.getVisibleRegion(); // 채널 연결 확인
        clusterManager!.updateMap(); // updateMap은 void
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
    clusterManager?.onCameraMove(position);
    // 카메라 이동 중에도 갱신하되 매 프레임마다 지도 채널을 호출하지 않는다.
    _clusterRefreshTimer ??= Timer(const Duration(milliseconds: 150), () {
      _clusterRefreshTimer = null;
      if (!_isDisposed) clusterManager?.updateMap();
    });
  }

  void onCameraIdle() {
    _clusterRefreshTimer?.cancel();
    _clusterRefreshTimer = null;
    clusterManager?.updateMap();
  }

  void onEdit(Marker updatedMarker) async {
    final keyword = _markerKeywords[updatedMarker.markerId] ?? 'default';
    final markerImagePath = keywordMarkerImages[keyword];

    if (markerImagePath != null) {
      final customMarker =
          await createCustomMarkerImage(markerImagePath, 48, 52);

      final newMarker = updatedMarker.copyWith(iconParam: customMarker);

      _markers.removeWhere((m) => m.markerId == updatedMarker.markerId);
      _markers.add(newMarker);
      _allMarkers.removeWhere((m) => m.markerId == updatedMarker.markerId);
      _allMarkers.add(newMarker);

      notifyListeners(); // 상태 변경 알림

      updateMarker(newMarker, keyword, markerImagePath);
    }
  }

  Future<BitmapDescriptor> createCustomMarkerImage(
      String imagePath, int width, int height) async {
    return _markerIconService.createCustomMarkerImage(
      imagePath,
      width,
      height,
    );
  }

  void updateMarker(
      Marker marker, String keyword, String markerImagePath) async {
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
        debugPrint('Error updating marker: ${response.error!.message}');
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
    _currentLocation = LatLng(locationData.latitude, locationData.longitude);
    notifyListeners();

    // 위치 변경 스트림 구독
    _location.onLocationChanged.listen((location.LocationData newLocationData) {
      _currentLocation = LatLng(
        newLocationData.latitude,
        newLocationData.longitude,
      );
      notifyListeners();
    });
  }

  // 리스트에 있는 마커를 필터링하여 지도에 표시
  void setFilteredMarkers(List<Marker> markers) {
    _routeRevision++;
    _routeMarkers = null;
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
    if (clusterManager != null) {
      clusterManager!.setItems(_filteredPlaces);
      clusterManager!.updateMap();
    }

    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getUserLists() =>
      _markerRepository.getUserLists();

  Future<void> checkLocationPermissionAndFetch() async {
    debugPrint('📍 checkLocationPermissionAndFetch 호출됨');
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ 위치 권한이 거부되었습니다.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ 위치 권한이 영구적으로 거부되었습니다.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (_isDisposed) return;

      _currentLocation = LatLng(position.latitude, position.longitude);
      debugPrint('✅ 현재 위치: $_currentLocation');

      if (controller != null) {
        moveToCurrentLocation();
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed && controller != null && _currentLocation != null) {
            moveToCurrentLocation();
          }
        });
      }

      notifyListeners();
    } on TimeoutException {
      debugPrint('⚠️ 현재 위치 조회 시간이 초과되었습니다. 지도 화면에서 다시 시도합니다.');
    } catch (error) {
      debugPrint('⚠️ 현재 위치를 불러오지 못했습니다: $error');
    }
  }

  void moveToCurrentLocation() async {
    if (controller != null && _currentLocation != null) {
      LatLng currentLatLng = LatLng(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );

      await controller!.animateCamera(
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
      debugPrint('마커 정보 로딩 오류: $e');
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
    _searchRevision++;
    searchPlaceMetadata.clear();
    query = query.trim();

    if (query.isEmpty) {
      _searchResults.clear();
      temporaryMarker = null; // 🔹 임시 마커 제거
      debugPrint("ℹ️ 검색어 비움 → 임시 마커 제거 및 검색 결과 초기화");
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
    final revision = ++_searchRevision;
    searchPlaceMetadata.clear();
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

    _searchResults =
        {for (var m in filteredMarkers) m.markerId: m}.values.toList();

    try {
      // Places API 호출
      double centerLat = _currentCameraPosition.target.latitude;
      double centerLng = _currentCameraPosition.target.longitude;

      if (centerLat == 37.5665 &&
          centerLng == 126.9780 &&
          _currentLocation != null) {
        centerLat = _currentLocation!.latitude;
        centerLng = _currentLocation!.longitude;
      }

      final places =
          await _searchService.search(originalQuery, centerLat, centerLng);
      if (_isDisposed || revision != _searchRevision) return;
      if (places.isNotEmpty) {
        final searchPin = await _markerIconService.createSearchMarker();
        if (_isDisposed || revision != _searchRevision) return;
        final newSearchMarkers = <Marker>[];
        int addedCount = 0;

        for (var place in places) {
          if (addedCount >= 10) break;

          final lat = (place['location']?['latitude'] as num?)?.toDouble();
          final lng = (place['location']?['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          final latLng = LatLng(lat, lng);
          final placeId = place['id'] ?? 'result_$addedCount';
          searchPlaceMetadata['search_$placeId'] =
              Map<String, dynamic>.from(place);

          final marker = Marker(
            markerId: MarkerId('search_$placeId'),
            position: latLng,
            infoWindow: InfoWindow(
              title: place['displayName']?['text'] ?? originalQuery,
              snippet: place['formattedAddress'] ?? '',
            ),
            icon: searchPin,
            anchor: const Offset(.5, 44 / 48),
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
    } catch (e) {
      if (_isDisposed || revision != _searchRevision) return;
      debugPrint("Places 검색 오류: $e");
    }

    notifyListeners();
  }

  Future<void> onMarkerTapped(MarkerId markerId) async {
    // 1. 검색 결과에 없으면 기존 사용자 마커에서 확인
    Marker? marker = _searchResults.firstWhereOrNull(
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
    await controller?.animateCamera(
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
