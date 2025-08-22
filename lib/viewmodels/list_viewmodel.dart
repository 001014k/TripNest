import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';
import '../models/list_model.dart';

class ListViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  List<ListModel> lists = [];
  bool isLoading = false;  // 초기 false로 변경
  String? errorMessage;

  // 생성자에서 loadLists 호출 제거
  ListViewModel();

  Future<void> loadLists() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final tempLists = <String, ListModel>{};

      // 1️⃣ 내가 만든 리스트 조회 Future
      final myListsFuture = supabase
          .from('lists')
          .select(
          '''
          id, name, created_at,
          list_bookmarks(id, title, lat, lng),
          list_members(id, user_id)
          '''
      )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      // 2️⃣ 내가 멤버로 초대받은 리스트 list_id 조회 Future
      final invitedListMembersFuture = supabase
          .from('list_members')
          .select('list_id')
          .eq('user_id', user.id);

      // 두 Future 동시에 실행
      final results = await Future.wait([myListsFuture, invitedListMembersFuture]);

      final myListsResponse = results[0] as List;
      final invitedListMembers = results[1] as List;

      // 1️⃣ 내가 만든 리스트 처리
      for (final item in myListsResponse) {
        final bookmarks = item['list_bookmarks'] as List<dynamic>? ?? [];
        final members = item['list_members'] as List<dynamic>? ?? [];

        tempLists[item['id']] = ListModel(
          id: item['id'] as String,
          name: item['name'] as String,
          createdAt: DateTime.parse(item['created_at'] as String),
          markerCount: bookmarks.length,
          collaboratorCount: members.length,
        );
      }

      // 2️⃣ 초대받은 리스트 처리
      // list_id별 리스트 정보를 동시에 조회
      final invitedListsFutures = invitedListMembers.map((member) async {
        final listId = member['list_id'] as String?;
        if (listId == null) return null;

        final listResponse = await supabase
            .from('lists')
            .select(
            '''
            id, name, created_at,
            list_bookmarks(id, title, lat, lng),
            list_members(id, user_id)
            '''
        )
            .eq('id', listId)
            .single();

        if (listResponse == null) return null;

        final bookmarks = listResponse['list_bookmarks'] as List<dynamic>? ?? [];
        final members = listResponse['list_members'] as List<dynamic>? ?? [];

        return ListModel(
          id: listResponse['id'] as String,
          name: listResponse['name'] as String,
          createdAt: DateTime.parse(listResponse['created_at'] as String),
          markerCount: bookmarks.length,
          collaboratorCount: members.length,
        );
      }).toList();

      final invitedListsResults = await Future.wait(invitedListsFutures);

      for (final listModel in invitedListsResults) {
        if (listModel != null) {
          tempLists[listModel.id] = listModel; // 중복 자동 제거
        }
      }

      // 최종 리스트
      lists = tempLists.values.toList();
    } catch (e) {
      errorMessage = '리스트 불러오기 실패: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createList(String name) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      errorMessage = '로그인된 유저가 없습니다.';
      notifyListeners();
      return;
    }

    try {
      await supabase.from('lists').insert({
        'user_id': user.id,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });
      await loadLists();
    } catch (e) {
      errorMessage = '리스트 생성 중 오류: $e';
      notifyListeners();
    }
  }

  Future<void> deleteList(String listId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      errorMessage = '로그인된 유저가 없습니다.';
      notifyListeners();
      return;
    }

    try {
      await supabase.from('list_bookmarks').delete().eq('list_id', listId);
      await supabase.from('lists').delete().eq('id', listId).eq('user_id', user.id);
      lists.removeWhere((list) => list.id == listId);
      notifyListeners();
    } catch (e) {
      errorMessage = '리스트 삭제 중 오류: $e';
      notifyListeners();
    }
  }
}
