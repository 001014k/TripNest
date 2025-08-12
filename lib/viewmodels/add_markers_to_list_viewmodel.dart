import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AddMarkersToListViewModel extends ChangeNotifier {
  final Set<Marker> _markers = {};
  final Map<MarkerId, String> _markerKeywords = {};
  bool _isLoading = true;
  String? _error;

  Set<Marker> get markers => _markers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, Set<String>> _markersInLists = {};

  final Map<String, String> keywordMarkerImages = {
    '카페': 'assets/cafe_marker.png',
    '호텔': 'assets/hotel_marker.png',
    '사진': 'assets/photo_marker.png',
    '음식점': 'assets/restaurant_marker.png',
    '전시회': 'assets/exhibition_marker.png',
  };

  final supabase = Supabase.instance.client;

  // 해당 리스트에 이미 추가된 마커인지 여부
  bool isMarkerInList(Marker marker, String listId) {
    if (!_markersInLists.containsKey(listId)) return false;
    return _markersInLists[listId]!.contains(marker.markerId.value);
  }

  Future<void> loadMarkers() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await supabase
          .from('user_markers')
          .select()
          .eq('user_id', user.id);

      final loadedMarkers = (data as List<dynamic>).map((json) {
        final keyword = (json['keyword'] as String?)?.trim().isNotEmpty == true
            ? json['keyword'] as String
            : '키워드 없음';

        final lat = (json['lat'] as num?)?.toDouble();
        final lng = (json['lng'] as num?)?.toDouble();

        if (lat == null || lng == null) return null;

        final title = (json['title'] as String?)?.trim().isNotEmpty == true
            ? json['title'] as String
            : '제목 없음';

        final snippet = (json['address'] as String?)?.trim().isNotEmpty == true
            ? json['address'] as String
            : '주소 없음';

        final marker = Marker(
          markerId: MarkerId(json['id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: title,
            snippet: snippet,
          ),
        );

        _markerKeywords[marker.markerId] = keyword;
        return marker;
      }).whereType<Marker>().toSet();

      _markers
        ..clear()
        ..addAll(loadedMarkers);

      _error = null;
    } catch (e) {
      _error = 'Failed to load markers: $e';
    }

    _isLoading = false;
    notifyListeners();
  }


  Future<void> addMarkerToList(
      Marker marker, String listId, BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. 현재 리스트에 같은 marker_id가 있는지 확인
      final existing = await supabase
          .from('list_bookmarks')
          .select('id')
          .eq('list_id', listId)
          .eq('marker_id', marker.markerId.value) // marker_id 컬럼 사용
          .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${marker.infoWindow.title ?? "이 장소"}는 이미 리스트에 있습니다.',
            ),
          ),
        );
        return;
      }

      // 2. 현재 리스트 내 순서(sort_order) 계산
      final orderData = await supabase
          .from('list_bookmarks')
          .select('id')
          .eq('list_id', listId);

      final orderCount = (orderData as List).length;

      // 3. 새 마커 추가 (UUID PK + marker_id 저장)
      await supabase.from('list_bookmarks').insert({
        'id': const Uuid().v4(), // PK
        'list_id': listId,
        'marker_id': marker.markerId.value, // DB에서 unique(list_id, marker_id) 제약
        'lat': marker.position.latitude,
        'lng': marker.position.longitude,
        'title': marker.infoWindow.title,
        'snippet': marker.infoWindow.snippet,
        'keyword': _markerKeywords[marker.markerId] ?? '',
        'sort_order': orderCount,
      });

      // 4. 로컬 상태 업데이트
      _markersInLists.putIfAbsent(listId, () => <String>{});
      _markersInLists[listId]!.add(marker.markerId.value);

      // 5. 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${marker.infoWindow.title}이(가) 리스트에 추가되었습니다.')),
      );

      Navigator.pop(context, true);
      _error = null;
    } catch (e) {
      _error = 'Failed to add marker to list: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('마커 추가 실패: $e')),
      );
    }

    notifyListeners();
  }

  Future<void> loadMarkersInList(String listId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('list_bookmarks')
          .select('marker_id')
          .eq('list_id', listId)
          .order('sort_order');

      final markerIds = (data as List<dynamic>)
          .map((e) => e['marker_id'] as String?)
          .whereType<String>()
          .toSet();

      _markersInLists[listId] = markerIds;
      _error = null;
    } catch (e) {
      _error = 'Failed to load markers in list: $e';
    }

    notifyListeners();
  }

  Future<void> updateMarkerOrders(String listId, List<Marker> orderedMarkers) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Flutter 쪽에서 JSON 형식으로 변환
    final List<Map<String, dynamic>> markerOrders = orderedMarkers.asMap().entries.map((entry) {
      final index = entry.key;
      final markerId = entry.value.markerId.value;
      return {
        'id': markerId,
        'sort_order': index,
      };
    }).toList();

    try {
      // Supabase RPC 호출
      final result = await supabase.rpc(
        'update_marker_orders',
        params: {
          'p_list_id': listId,
          'p_orders': markerOrders,  // 함수 파라미터 이름에 맞게 'p_orders'로
        },
      );
      print('✅ RPC 호출 성공 결과: $result');
    } catch (e) {
      print('❌ Marker order update error: $e');
    }
  }
}
