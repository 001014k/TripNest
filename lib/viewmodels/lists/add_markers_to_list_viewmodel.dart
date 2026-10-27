import '../../services/lists/list_access_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../services/notifications/notification_service.dart';

class AddMarkersToListViewModel extends ChangeNotifier {
  final Set<Marker> _markers = {};
  final Map<MarkerId, String> _markerKeywords = {};
  bool _isLoading = true;
  String? _error;

  Set<Marker> get markers => _markers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final Map<String, Set<String>> _markersInLists = {};

  final Map<String, String> keywordMarkerImages = {
    '카페': 'assets/cafe_marker.png',
    '호텔': 'assets/hotel_marker.png',
    '사진': 'assets/photo_marker.png',
    '음식점': 'assets/restaurant_marker.png',
    '전시회': 'assets/exhibition_marker.png',
    '자연': 'nature',
    '관광명소': 'landmark',
    '쇼핑': 'shopping',
    '체험': 'activity',
  };

  final supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

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
      final data =
          await supabase.from('user_markers').select().eq('user_id', user.id);

      final loadedMarkers = (data as List<dynamic>)
          .map((json) {
            final keyword =
                (json['keyword'] as String?)?.trim().isNotEmpty == true
                    ? json['keyword'] as String
                    : '키워드 없음';

            final lat = (json['lat'] as num?)?.toDouble();
            final lng = (json['lng'] as num?)?.toDouble();

            if (lat == null || lng == null) return null;

            final title = (json['title'] as String?)?.trim().isNotEmpty == true
                ? json['title'] as String
                : '제목 없음';

            final snippet =
                (json['address'] as String?)?.trim().isNotEmpty == true
                    ? json['address'] as String
                    : '주소 없음';

            final id = json['id']?.toString() ?? const Uuid().v4();

            final marker = Marker(
              markerId: MarkerId(id),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: title,
                snippet: snippet,
              ),
            );

            _markerKeywords[marker.markerId] = keyword;
            return marker;
          })
          .whereType<Marker>()
          .toSet();

      _markers
        ..clear()
        ..addAll(loadedMarkers);

      _error = null;
    } catch (e) {
      _error = 'Failed to load markers: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String> addMarkerToList(Marker marker, String listId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return '로그인이 필요합니다.';

    // UI 상태가 갱신되기 전의 연속 탭도 중복 추가로 이어지지 않게 막습니다.
    if (isMarkerInList(marker, listId)) {
      return '${marker.infoWindow.title ?? "이 장소"}는 이미 리스트에 있습니다.';
    }

    try {
      if (!await ListAccessService.canEditPlaces(listId)) {
        return '게스트는 읽기 전용입니다.';
      }
      await supabase.rpc('add_marker_to_list', params: {
        'p_list_id': listId,
        'p_marker_id':
            marker.markerId.value, // markerId.value 는 UUID 문자열이어야 합니다.
        'p_lat': marker.position.latitude,
        'p_lng': marker.position.longitude,
        'p_title': marker.infoWindow.title ?? '',
        'p_snippet': marker.infoWindow.snippet ?? '',
        'p_keyword': _markerKeywords[marker.markerId] ?? '',
      });

      unawaited(
        _notificationService.notifyMarkerAddedToList(
          listId: listId,
          markerId: marker.markerId.value,
          markerTitle: marker.infoWindow.title ?? '장소',
        ),
      );

      _markersInLists.putIfAbsent(listId, () => <String>{});
      _markersInLists[listId]!.add(marker.markerId.value);

      _error = null;
      notifyListeners();
      return '';
    } on PostgrestException catch (e) {
      _error = 'Failed to add marker to list: ${e.message}';
      notifyListeners();
      return e.message.contains('Marker already exists')
          ? '${marker.infoWindow.title ?? "이 장소"}는 이미 리스트에 있습니다.'
          : '마커 추가 실패: ${e.message}';
    } catch (e) {
      _error = 'Failed to add marker to list: $e';
      notifyListeners();
      return '마커 추가 실패: $e';
    }
  }

  Future<void> loadMarkersInList(String listId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('list_bookmarks')
          .select('marker_id')
          .eq('list_id', listId)
          .order('sort_order');

      final markerIds = (data as List<dynamic>)
          .map((e) => e['marker_id'] as String?)
          .whereType<String>()
          .toSet();

      _markersInLists[listId] = markerIds;
      _error = null;
    } catch (e) {
      _error = 'Failed to load markers in list: $e';
    }

    notifyListeners();
  }

  Future<void> updateMarkerOrders(
      String listId, List<Marker> orderedMarkers) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Flutter 쪽에서 JSON 형식으로 변환
    final List<Map<String, dynamic>> markerOrders =
        orderedMarkers.asMap().entries.map((entry) {
      final index = entry.key;
      final markerId = entry.value.markerId.value;
      return {
        // 서버 함수에서 보통 'marker_id'로 기대하므로 키를 명확히 지정
        'marker_id': markerId,
        'sort_order': index,
      };
    }).toList();
    try {
      // Supabase RPC 호출
      final result = await supabase.rpc(
        'update_marker_orders',
        params: {
          'p_list_id': listId,
          'p_orders': markerOrders, // 함수 파라미터 이름에 맞게 'p_orders'로
        },
      );
      debugPrint('✅ RPC 호출 성공 결과: $result');
      await _notificationService.notifyListUpdated(listId, 'reordered');
    } on PostgrestException catch (e) {
      // RPC 스키마 불일치/RLS 등 상세 로그 확인
      debugPrint('❌ RPC PostgrestException: ${e.message}, code=${e.code}');
      debugPrint('➡️ 개별 업데이트 폴백을 시도합니다.');
      await _fallbackUpdateOrders(listId, markerOrders);
      await _notificationService.notifyListUpdated(listId, 'reordered');
    } catch (e) {
      debugPrint('❌ Marker order update error: $e');
      debugPrint('➡️ 개별 업데이트 폴백을 시도합니다.');
      await _fallbackUpdateOrders(listId, markerOrders);
      await _notificationService.notifyListUpdated(listId, 'reordered');
    }
  }

  Future<void> _fallbackUpdateOrders(
      String listId, List<Map<String, dynamic>> markerOrders) async {
    for (final order in markerOrders) {
      final String markerId = order['marker_id'] as String;
      final int sortOrder = order['sort_order'] as int;
      try {
        await supabase
            .from('list_bookmarks')
            .update({'sort_order': sortOrder})
            .eq('list_id', listId)
            .eq('marker_id', markerId);
      } on PostgrestException catch (e) {
        debugPrint('❌ 개별 정렬 업데이트 실패 (marker_id=$markerId): ${e.message}');
        rethrow;
      } catch (e) {
        debugPrint('❌ 개별 정렬 업데이트 예외 (marker_id=$markerId): $e');
        rethrow;
      }
    }

    debugPrint('✅ 폴백 개별 업데이트 완료');
  }
}
