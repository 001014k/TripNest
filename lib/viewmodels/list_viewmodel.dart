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
    if (user == null) return;

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

        // 마커 개수 구하기
        // 수정 후 (list_bookmarks 테이블로 변경)
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
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> createList(String name) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase.from('lists').insert({
        'user_id': user.id,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      final inserted = (response as List).first;

      lists.insert(
        0,
        ListModel(
          id: inserted['id'],
          name: inserted['name'],
          createdAt: DateTime.parse(inserted['created_at']),
          markerCount: 0,
        ),
      );
      notifyListeners();
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
          .eq('user_id', user.id)
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
