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
    if (user == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      // lists와 list_bookmarks, list_members 배열을 같이 가져옴
      final response = await supabase
          .from('lists')
          .select('id, name, created_at, list_bookmarks(id), list_members(id)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      lists = (response as List).map((item) {
        final bookmarks = item['list_bookmarks'] as List<dynamic>? ?? [];
        final members = item['list_members'] as List<dynamic>? ?? [];

        return ListModel(
          id: item['id'] as String,
          name: item['name'] as String,
          createdAt: DateTime.parse(item['created_at'] as String),
          markerCount: bookmarks.length,
          collaboratorCount: members.length,
        );
      }).toList();
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
