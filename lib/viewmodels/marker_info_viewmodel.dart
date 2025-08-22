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
    if (listId == null) return; // 리스트 아이디가 없으면 종료
    isLoading = true;
    notifyListeners();

    try {
      // 1️⃣ 리스트 내 마커 목록 조회
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

      // 2️⃣ marker_id 기준으로 모든 마커 정보 조회 (user_id 조건 제거)
      final orFilter = markerIds.map((id) => "id.eq.$id").join(',');

      final userMarkersData = await supabase
          .from('user_markers')
          .select('id, title, address, keyword, lat, lng, marker_image_path')
          .or(orFilter); // 모든 마커 가져오기

      // 3️⃣ 마커 id 기준으로 맵 생성
      final Map<String, Map<String, dynamic>> userMarkersMap = {
        for (var item in (userMarkersData as List))
          item['id'] as String: item as Map<String, dynamic>
      };

      // 4️⃣ MarkerModel 리스트 생성
      markers = listBookmarksData.map<MarkerModel>((bookmark) {
        final markerId = bookmark['marker_id'] as String;
        final userMarker = userMarkersMap[markerId];

        return MarkerModel(
          id: markerId,
          title: userMarker?['title']?.toString() ?? '제목 없음',
          keyword: userMarker?['keyword']?.toString() ?? '키워드 없음',
          address: userMarker?['address']?.toString() ?? '주소 없음',
          lat: userMarker != null && userMarker['lat'] != null
              ? (userMarker['lat'] as num).toDouble()
              : 0.0,
          lng: userMarker != null && userMarker['lng'] != null
              ? (userMarker['lng'] as num).toDouble()
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
      final response = await supabase
          .from('list_bookmarks')
          .delete()
          .eq('marker_id', markerId)
          .select();  // 삭제된 레코드 반환 요청

      print('삭제 결과: $response');

      // 삭제가 제대로 됐는지 체크
      if (response == null || (response is List && response.isEmpty)) {
        print('삭제 실패: 해당 ID의 레코드가 없습니다.');
        error = '삭제 실패: 해당 마커를 찾을 수 없습니다.';
        notifyListeners();
        return;
      }

      // markers 리스트에서 제거
      markers.removeWhere((marker) => marker.id == markerId);

      // 서버에서 다시 마커 리스트 갱신 (필요하다면)
      await loadMarkers();

      notifyListeners();
    } catch (e) {
      print('삭제 중 예외 발생: $e');
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
