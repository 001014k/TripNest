import 'package:fluttertrip/services/user_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// BookmarkService: 리스트에 저장된 마커 조회
class BookmarkService {
  /// 리스트에 속한 마커 반환
  Future<List<Marker>> getMarkersForList(String userId, String listId, Function(MarkerId) onTap) async {
    final response = await supabase
        .from('list_bookmarks')
        .select()
        .eq('list_id', listId);

    return (response as List).map((data) {
      return Marker(
        markerId: MarkerId(data['id']),
        position: LatLng(data['lat'], data['lng']),
        infoWindow: InfoWindow(
          title: data['title'] ?? '제목 없음',
          snippet: data['snippet'] ?? '설명 없음',
        ),
        onTap: () => onTap(MarkerId(data['id'])),
      );
    }).toList();
  }
}