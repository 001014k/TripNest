import 'database_helper.dart';
import 'connectivity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarkerService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> saveMarkerOfflineOrOnline(Map<String, dynamic> markerData) async {
    final isConnected = await _connectivityService.isConnected();

    final user = supabase.auth.currentUser;
    if (user == null) return; // 로그인 안 된 상태 예외 처리

    final userId = user.id;

    if (!isConnected) {
      // 오프라인일 때 SQLite에 저장
      await _dbHelper.insertMarker(markerData);
    } else {
      // 온라인일 때 Supabase에 저장
      final response = await supabase.from('user_markers').upsert({
        'id': markerData['id'], // UUID
        'user_id': userId,
        'title': markerData['title'],
        'description': markerData['description'],
        'lat': markerData['latitude'],
        'lng': markerData['longitude'],
        'created_at': markerData['created_at'] ?? DateTime.now().toIso8601String(),
      });

      if (response.error != null) {
        print('Supabase 저장 오류: ${response.error!.message}');
        return;
      }

      // 동기화된 마커를 로컬 DB에 표시
      await _dbHelper.insertMarker({...markerData, 'synced': 1});
    }
  }

  Future<void> syncOfflineMarkers() async {
    final unsyncedMarkers = await _dbHelper.getUnsyncedMarkers();
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final userId = user.id;

    for (final marker in unsyncedMarkers) {
      final response = await supabase.from('user_markers').upsert({
        'id': marker['id'],
        'user_id': userId,
        'title': marker['title'],
        'description': marker['description'],
        'lat': marker['latitude'],
        'lng': marker['longitude'],
        'created_at': marker['created_at'] ?? DateTime.now().toIso8601String(),
      });

      if (response.error != null) {
        print('Supabase 동기화 실패: ${response.error!.message}');
        continue;
      }

      // 동기화 상태 로컬 DB에 반영
      await _dbHelper.updateMarkerSyncStatus(marker['id']);
    }
  }
}
