import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        final keyword = json['keyword'] ?? 'default';
        final lat = (json['lat'] as num?)?.toDouble();
        final lng = (json['lng'] as num?)?.toDouble();

        if (lat == null || lng == null) return null;

        final marker = Marker(
          markerId: MarkerId(json['id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: json['title'] ?? 'No Title',
            snippet: json['snippet'] ?? 'No Snippet',
          ),
        );
        _markerKeywords[marker.markerId] = keyword;
        return marker;
      }).whereType<Marker>().toSet();

      _markers.clear();
      _markers.addAll(loadedMarkers);
      _error = null;
    } catch (e) {
      _error = 'Failed to load markers: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMarkerToList(Marker marker, String listId, BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final orderData = await supabase
          .from('list_bookmarks')
          .select('id')
          .eq('list_id', listId);

      final orderCount = (orderData as List).length;

      await supabase.from('list_bookmarks').insert({
        'id': marker.markerId.value,
        'list_id': listId,
        'lat': marker.position.latitude,
        'lng': marker.position.longitude,
        'title': marker.infoWindow.title,
        'snippet': marker.infoWindow.snippet,
        'keyword': _markerKeywords[marker.markerId] ?? '',
        'sort_order': orderCount,
      });

      _markersInLists.putIfAbsent(listId, () => <String>{});
      _markersInLists[listId]!.add(marker.markerId.value);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${marker.infoWindow.title} added to list')),
      );

      Navigator.pop(context, true);
      _error = null;
    } catch (e) {
      _error = 'Failed to add marker to list: $e';
      notifyListeners();
    }

    notifyListeners();
  }

  Future<void> loadMarkersInList(String listId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('list_bookmarks')
          .select('id')
          //.eq('user_id', user.id)
          .eq('list_id', listId)
          .order('sort_order');

      final markerIds = (data as List<dynamic>).map((e) => e['id'] as String).toSet();
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
