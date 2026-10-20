import 'notification_service.dart';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'connectivity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarkerService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> loadMarkerDetail(String markerId) => supabase
      .from('user_markers')
      .select('title, address, keyword, snippet')
      .eq('id', markerId)
      .maybeSingle();

  Future<void> deleteUserMarker(String markerId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw StateError('로그인이 필요합니다.');
    await supabase
        .from('user_markers')
        .delete()
        .eq('user_id', user.id)
        .eq('id', markerId);
  }

  Future<bool> createUserMarker({
    required String id,
    required String? title,
    required String? snippet,
    required double latitude,
    required double longitude,
    required String keyword,
    required String imagePath,
    required String address,
    String? listId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;
    await supabase.from('user_markers').insert({
      'id': id,
      'user_id': user.id,
      'title': title,
      'snippet': snippet,
      'lat': latitude,
      'lng': longitude,
      'keyword': keyword,
      'marker_image_path': imagePath,
      'address': address,
    });
    if (listId != null) {
      try {
        await supabase.from('list_bookmarks').insert({
          'list_id': listId,
          'marker_id': id,
          'title': title,
          'keyword': keyword,
          'lat': latitude,
          'lng': longitude,
          'snippet': snippet,
          'created_at': DateTime.now().toIso8601String(),
        });
        await NotificationService(supabase: supabase).notifyMarkerAddedToList(
            listId: listId, markerId: id, markerTitle: title ?? '장소');
      } catch (error) {
        debugPrint('list_bookmarks Insert 실패: $error');
      }
    }
    return true;
  }

  Future<void> saveMarkerOfflineOrOnline(
      Map<String, dynamic> markerData) async {
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
        'created_at':
            markerData['created_at'] ?? DateTime.now().toIso8601String(),
      });

      if (response.error != null) {
        debugPrint('Supabase 저장 오류: ${response.error!.message}');
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
        debugPrint('Supabase 동기화 실패: ${response.error!.message}');
        continue;
      }

      // 동기화 상태 로컬 DB에 반영
      await _dbHelper.updateMarkerSyncStatus(marker['id']);
    }
  }

  Future<List<Map<String, dynamic>>> getRecentMarkers({int limit = 3}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final userId = user.id;

    try {
      final response = await supabase
          .from('user_markers')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      // response는 List<Map<String, dynamic>> 타입임
      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      debugPrint('Supabase 마커 조회 오류: $error');
      return [];
    }
  }
}
