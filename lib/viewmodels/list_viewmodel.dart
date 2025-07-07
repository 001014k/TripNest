import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 이미 있음
import 'package:supabase/supabase.dart'; // 이게 있어야 CountOption 사용 가능
import '../models/list_model.dart';

class ListViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  List<ListModel> lists = [];
  bool isLoading = true;
  String? errorMessage;

  ListViewModel() {
    loadLists();
  }

  Future<void> loadLists() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      isLoading = false;
      notifyListeners(); // 유저 없을 때도 반드시 호출
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await supabase
          .from('lists')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;

      lists = [];

      for (var item in data) {
        final listId = item['id'];

        final bookmarkCountResp = await supabase
            .from('list_bookmarks')
            .select('id')
            .eq('list_id', listId)
            .count(CountOption.exact);

        final markerCount = bookmarkCountResp.count ?? 0;

        lists.add(ListModel(
          id: listId,
          name: item['name'],
          createdAt: DateTime.parse(item['created_at']),
          markerCount: markerCount,
        ));
      }

      errorMessage = null;
    } catch (e) {
      errorMessage = '리스트 불러오기 실패: $e';
    } finally {
      isLoading = false;
      notifyListeners(); // 반드시 호출되도록 finally에서 처리
    }
  }

  Future<void> createList(String name) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('lists').insert({
        'user_id': user.id,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });

      await loadLists();

      print('리스트 생성 및 로드 완료');
      notifyListeners(); // 확실히 호출되는지 확인
    } catch (e) {
      print('Error creating list: $e');
      errorMessage = '리스트 생성 중 오류: $e';
      notifyListeners();
    }
  }

  Future<void> deleteList(String listId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 먼저 bookmarks 삭제
      await supabase
          .from('list_bookmarks')
          .delete()
          .eq('list_id', listId);

      // 이후 lists 삭제
      await supabase
          .from('lists')
          .delete()
          .eq('id', listId)
          .eq('user_id', user.id);

      lists.removeWhere((list) => list.id == listId);
      notifyListeners();
    } catch (e) {
      errorMessage = '리스트 삭제 중 오류: $e';
      notifyListeners();
    }
  }
}
