import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/marker_model.dart';

class MarkerInfoViewModel extends ChangeNotifier {
  final String listId;
  List<MarkerModel> markers = [];
  bool isLoading = true;
  String? error;

  final supabase = Supabase.instance.client;

  MarkerInfoViewModel({required this.listId}) {
    loadMarkers();
  }

  Future<void> loadMarkers() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      // 리스트 내 마커 목록 조회
      final listBookmarksData = await supabase
          .from('list_bookmarks')
          .select('id, marker_id, sort_order')
          .eq('list_id', listId)
          .order('sort_order', ascending: true);

      final markerIds = (listBookmarksData as List)
          .map<String>((e) => e['marker_id'] as String)
          .toList();

      if (markerIds.isEmpty) {
        markers = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      final orFilter = markerIds.map((id) => "id.eq.$id").join(',');

      final userMarkersData = await supabase
          .from('user_markers')
          .select('id, title, address, keyword, lat, lng, marker_image_path')
          .or(orFilter);



      // 마커 id 기준으로 맵 생성
      final Map<String, Map<String, dynamic>> userMarkersMap = {
        for (var item in (userMarkersData as List))
          item['id'] as String: item as Map<String, dynamic>
      };

      // MarkerModel 리스트 생성
      markers = listBookmarksData.map<MarkerModel>((bookmark) {
        final markerId = bookmark['marker_id'] as String;
        final userMarker = userMarkersMap[markerId];

        return MarkerModel(
          id: markerId,  // bookmark['id']가 아니라 marker_id 써야 맞음
          title: userMarker?['title']?.toString() ?? '제목 없음',
          keyword: userMarker?['keyword']?.toString() ?? '키워드 없음',
          address: userMarker?['address']?.toString() ?? '주소 없음',
          lat: userMarker != null && userMarker['lat'] != null
              ? (userMarker['lat'] is num
              ? (userMarker['lat'] as num).toDouble()
              : 0.0)
              : 0.0,
          lng: userMarker != null && userMarker['lng'] != null
              ? (userMarker['lng'] is num
              ? (userMarker['lng'] as num).toDouble()
              : 0.0)
              : 0.0,
          markerImagePath: userMarker?['marker_image_path']?.toString() ?? '',
        );
      }).toList();

      error = null;
    } catch (e) {
      error = 'Failed to load markers: $e';
    }

    isLoading = false;
    notifyListeners();
  }


  Future<void> deleteMarker(String markerId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('list_bookmarks')
          .delete()
          .eq('id', markerId);

      markers.removeWhere((marker) => marker.id == markerId);
      notifyListeners();
    } catch (e) {
      error = 'Failed to delete marker: $e';
      notifyListeners();
    }
  }

  Future<Map<String, String>> fetchMarkerDetail(String markerId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {
      'title': '제목 없음',
      'address': '주소 없음',
      'keyword': '키워드 없음',
    };

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
}
