import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/markers/marker_model.dart';

class MapMarkerRepository {
  MapMarkerRepository(this._client);
  final SupabaseClient _client;
  Future<List<MarkerModel>> loadAccessible() async {
    final currentUserId = _client.auth.currentUser?.id;

    if (currentUserId == null) return [];
    // 1. 참여 중인 리스트 ID 가져오기
    final memberResponse = await _client
        .from('list_members')
        .select('list_id')
        .eq('user_id', currentUserId);

    final listIds = (memberResponse as List<dynamic>)
        .map((e) => e['list_id'] as String)
        .toList();

    // 2. 접근 가능한 marker_id 추출
    final bookmarkedMarkerIds = await _client
        .from('list_bookmarks')
        .select('marker_id')
        .inFilter('list_id', listIds);

    final List<String> accessibleMarkerIds =
        (bookmarkedMarkerIds as List<dynamic>)
            .map((e) => e['marker_id'] as String)
            .toList();

    final String idList = accessibleMarkerIds.isEmpty
        ? '00000000-0000-0000-0000-000000000000'
        : accessibleMarkerIds.join(',');

    final response = await _client
        .from('user_markers')
        .select('*, list_bookmarks(*)')
        .or('user_id.eq.$currentUserId,id.in.($idList)')
        .isFilter('deleted_at', null);

    final List<dynamic> data = response as List<dynamic>;
    final List<MarkerModel> markerModels = data
        .map((item) => MarkerModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return markerModels;
  }

  Future<List<Map<String, dynamic>>> loadOwn() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    return await _client
        .from('user_markers')
        .select()
        .eq('user_id', user.id)
        .isFilter('deleted_at', null);
  }

  Future<List<Map<String, dynamic>>> getUserLists() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      // 1️⃣ 내가 생성한 리스트
      final List<dynamic> myLists = await _client
          .from('lists')
          .select('*, list_bookmarks(title), list_members(user_id)')
          .eq('user_id', user.id);

      // 2️⃣ 내가 멤버로 속한 리스트
      final List<dynamic> invitedLists = await _client
          .from('list_members')
          .select(
              'lists(*, list_bookmarks(title), list_members(user_id))') // list_members에 연결된 리스트를 가져오기
          .eq('user_id', user.id);

      // invitedLists에서 lists 필드만 추출
      final List<Map<String, dynamic>> invitedListsData = invitedLists
          .map<Map<String, dynamic>>(
              (item) => item['lists'] as Map<String, dynamic>)
          .toList();

      // 3️⃣ 합치고 중복 제거
      final Map<String, Map<String, dynamic>> tempLists = {};

      for (var list in myLists.cast<Map<String, dynamic>>()) {
        tempLists[list['id']] = list;
      }
      for (var list in invitedListsData) {
        tempLists[list['id']] = list;
      }

      return tempLists.values.toList();
    } catch (e) {
      debugPrint('Error fetching user lists: $e');
      return [];
    }
  }
}
