import 'package:supabase_flutter/supabase_flutter.dart';

class SharedPlaceLookupService {
  const SharedPlaceLookupService();

  Future<List<Map<String, dynamic>>> loadSavedMarkers() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('로그인이 필요합니다.');

    final markers = <Map<String, dynamic>>[];
    const pageSize = 500;
    for (var offset = 0;; offset += pageSize) {
      final page = await client
          .from('user_markers')
          .select('id, title, address, lat, lng')
          .eq('user_id', user.id)
          .isFilter('deleted_at', null)
          .range(offset, offset + pageSize - 1);
      markers.addAll(page);
      if (page.length < pageSize) break;
    }
    return markers;
  }
}
