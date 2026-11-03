import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapRouteRepository {
  MapRouteRepository(
      this._client, List<Marker> markers, Map<String, String> rowIds)
      : _markerIds = markers.map((m) => m.markerId.value).toList();
  final SupabaseClient _client;
  final List<String> _markerIds;

  Future<void> updateMarkerOrdersForList(String listId) async {
    if (_client.auth.currentUser == null) throw StateError('로그인이 필요합니다.');
    await _client.rpc('reorder_list_markers_atomic', params: {
      'p_list_id': listId,
      'p_marker_ids': _markerIds,
    });
  }
}
