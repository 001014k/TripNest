import '../../services/infrastructure/paged_rows.dart';
import '../../services/lists/list_access_service.dart';
import '../../services/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/markers/marker_model.dart';

class MarkerInfoViewModel extends ChangeNotifier {
  bool _disposed = false;
  int _revision = 0;
  final Set<String> _deleted = {}, _deleting = {};
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }

  final String listId;
  List<MarkerModel> markers = [];
  bool isLoading = true;
  String? role;
  bool get isOwner => role == 'owner';
  bool get canEditPlaces => isOwner || role == 'editor';
  String? error;

  final SupabaseClient supabase;
  final Future<String?> Function(String) _loadRole;
  final Future<void> Function(String, String) _notifyUpdate;
  MarkerInfoViewModel(
      {required this.listId,
      SupabaseClient? client,
      Future<String?> Function(String)? loadRole,
      Future<void> Function(String, String)? notifyUpdate,
      bool autoLoad = true})
      : supabase = client ?? Supabase.instance.client,
        _loadRole = loadRole ?? ListAccessService.role,
        _notifyUpdate = notifyUpdate ??
            ((id, change) =>
                NotificationService().notifyListUpdated(id, change)) {
    if (autoLoad) loadMarkers();
  }

  Future<void> loadMarkers() async {
    if (_disposed) return;
    final revision = ++_revision;
    _deleted.clear();
    isLoading = true;
    notifyListeners();

    try {
      final nextRole = await _loadRole(listId);
      if (_disposed || revision != _revision) return;
      role = nextRole;
      // 1️⃣ 리스트 내 마커 목록 조회
      final listBookmarksData = await loadRowsById(
          () => supabase
              .from('list_bookmarks')
              .select('id, marker_id, sort_order')
              .eq('list_id', listId),
          isCancelled: () => _disposed || revision != _revision);
      if (_disposed || revision != _revision) return;
      listBookmarksData.sort((a, b) => ((a['sort_order'] as num?) ?? 0)
          .compareTo((b['sort_order'] as num?) ?? 0));

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
      final userMarkersData = <Map<String, dynamic>>[];
      for (var offset = 0; offset < markerIds.length; offset += 100) {
        if (_disposed || revision != _revision) return;
        userMarkersData.addAll(await supabase
            .from('user_markers')
            .select('id, title, address, keyword, lat, lng, marker_image_path')
            .inFilter('id', markerIds.skip(offset).take(100).toList()));
      }
      if (_disposed || revision != _revision) return;
      // 3️⃣ 마커 id 기준으로 맵 생성
      final Map<String, Map<String, dynamic>> userMarkersMap = {
        for (var item in (userMarkersData as List))
          item['id'] as String: item as Map<String, dynamic>
      };

      // 4️⃣ MarkerModel 리스트 생성
      markers = listBookmarksData
          .where((b) =>
              userMarkersMap.containsKey(b['marker_id']) &&
              !_deleted.contains(b['marker_id']) &&
              !_deleting.contains(b['marker_id']))
          .map<MarkerModel>((bookmark) {
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
      if (_disposed || revision != _revision) return;
      error = '장소를 불러오지 못했어요. 다시 시도해주세요.';
    }

    if (_disposed || revision != _revision) return;
    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteMarker(String markerId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    if (!const ['owner', 'editor'].contains(await _loadRole(listId))) {
      error = '게스트는 장소를 추가하거나 삭제할 수 없습니다.';
      notifyListeners();
      return;
    }

    if (_disposed || !_deleting.add(markerId)) return;
    ++_revision;
    isLoading = false;
    try {
      final response = await supabase
          .from('list_bookmarks')
          .delete()
          .eq('marker_id', markerId)
          .eq('list_id', listId)
          .select(); // 삭제된 레코드 반환 요청

      debugPrint('삭제 결과: $response');

      // 삭제가 제대로 됐는지 체크
      if (response.isEmpty) throw StateError('장소가 삭제되지 않았습니다.');

      ++_revision;
      _deleted.add(markerId);
      await _notifyUpdate(listId, 'removed');

      // markers 리스트에서 제거
      markers.removeWhere((marker) => marker.id == markerId);

      // 서버에서 다시 마커 리스트 갱신 (필요하다면)
      await loadMarkers();

      notifyListeners();
    } catch (e) {
      debugPrint('삭제 중 예외 발생: $e');
      _deleting.remove(markerId);
      if (!_disposed) await loadMarkers();
      error = '장소를 삭제하지 못했어요. 다시 시도해주세요.';
      notifyListeners();
    } finally {
      _deleting.remove(markerId);
    }
  }

  Future<Map<String, String>> fetchMarkerDetail(String markerId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return {
        'title': '제목 없음',
        'address': '주소 없음',
        'keyword': '키워드 없음',
      };
    }

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
      debugPrint('마커 정보 로딩 오류: $e');
      return {
        'title': '오류 발생',
        'address': '',
        'keyword': '',
      };
    }
  }
}
