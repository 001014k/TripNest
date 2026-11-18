import '../notifications/notification_service.dart';
import 'package:flutter/foundation.dart';
import '../infrastructure/database_helper.dart';
import '../infrastructure/connectivity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarkerService {
  final DatabaseHelper _dbHelper;
  final ConnectivityService _connectivityService = ConnectivityService();
  MarkerService(
      {SupabaseClient? client,
      DatabaseHelper? database,
      Future<void> Function(String listId, String markerId, String title)?
          notifyAdded})
      : _dbHelper = database ?? DatabaseHelper(),
        supabase = client ?? Supabase.instance.client,
        _notifyAdded = notifyAdded;
  final SupabaseClient supabase;
  final Future<void> Function(String, String, String)? _notifyAdded;

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
    await supabase.rpc('create_user_marker_atomic', params: {
      'p_id': id,
      'p_title': title,
      'p_snippet': snippet,
      'p_lat': latitude,
      'p_lng': longitude,
      'p_keyword': keyword,
      'p_image_path': imagePath,
      'p_address': address,
      'p_list_id': listId,
    });
    // 데이터베이스 저장이 완료된 뒤 알림 전송을 시도합니다.
    if (listId != null) {
      try {
        if (_notifyAdded != null) {
          await _notifyAdded(listId, id, title ?? '장소');
        } else {
          await NotificationService(supabase: supabase).notifyMarkerAddedToList(
              listId: listId, markerId: id, markerTitle: title ?? '장소');
        }
      } catch (_) {
        debugPrint('장소 저장 완료, 알림 전송 실패');
      }
    }
    return true;
  }

  Future<void> saveMarkerOfflineOrOnline(
      Map<String, dynamic> markerData) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('로그인이 필요합니다.');
    final row = <String, dynamic>{
      'id': markerData['id'],
      'user_id': userId,
      'title': markerData['title'],
      'description': markerData['description'],
      'latitude': markerData['latitude'],
      'longitude': markerData['longitude'],
      'synced': 0,
    };
    await _dbHelper.insertMarker(row);
    if (await _connectivityService.isConnected()) await syncOfflineMarkers();
  }

  static final Map<String, Future<void>> _syncing = {};
  Future<void> syncOfflineMarkers() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return Future.value();
    final existing = _syncing[userId];
    if (existing != null) return existing;
    final request = _syncOfflineMarkers(userId);
    _syncing[userId] = request;
    return request.whenComplete(() {
      if (identical(_syncing[userId], request)) _syncing.remove(userId);
    });
  }

  Future<void> _syncOfflineMarkers(String userId) async {
    final rows = await _dbHelper.getUnsyncedMarkers(userId);
    for (final row in rows) {
      if (supabase.auth.currentUser?.id != userId) return;
      try {
        await supabase.rpc('create_user_marker_atomic', params: {
          'p_id': row['id'],
          'p_title': row['title'],
          'p_snippet': row['description'] ?? '',
          'p_lat': row['latitude'],
          'p_lng': row['longitude'],
          'p_keyword': '기타',
          'p_image_path': '',
          'p_address': '',
          'p_list_id': null,
        }).timeout(const Duration(seconds: 15));
        await _dbHelper.updateMarkerSyncStatus(row['id'] as String, userId);
      } catch (_) {
        // 재시도해도 중복 처리되지 않도록 원본 행을 유지하며, 저장 실패를 동기화 완료로 표시하지 않습니다.
        debugPrint('오프라인 장소 동기화 보류');
      }
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
