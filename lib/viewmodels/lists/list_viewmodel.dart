import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lists/list_model.dart';

class ListViewModel extends ChangeNotifier {
  bool _accountDisposed = false;
  @override
  void notifyListeners() {
    if (!_accountDisposed) super.notifyListeners();
  }

  final SupabaseClient supabase;
  int _loadRevision = 0;
  final _deletedIds = <String>{};
  final _deletingIds = <String>{};

  List<ListModel> lists = [];
  bool isLoading = false; // 초기 false로 변경
  String? errorMessage;

  // 생성자에서 loadLists 호출 제거
  ListViewModel({SupabaseClient? client})
      : supabase = client ?? Supabase.instance.client;

  Future<void> loadLists() async {
    final user = supabase.auth.currentUser;
    if (user == null || _accountDisposed) return;
    final revision = ++_loadRevision;

    try {
      isLoading = true;
      notifyListeners();

      errorMessage = null;
      final response = await supabase.rpc('list_summaries');
      if (_accountDisposed ||
          revision != _loadRevision ||
          supabase.auth.currentUser?.id != user.id) {
        return;
      }
      lists = [
        for (final row in response as List)
          if (!_deletedIds.contains(row['id']) &&
              !_deletingIds.contains(row['id']))
            ListModel(
              id: row['id'],
              name: row['name'],
              createdAt: DateTime.parse(row['created_at']),
              markerCount: (row['marker_count'] as num).toInt(),
              collaboratorCount: (row['collaborator_count'] as num).toInt(),
              keywords: List<String>.from(row['keywords'] ?? []),
              isOwner: row['user_id'] == user.id,
              coverTitle: row['cover_title'],
            )
      ];
    } catch (e) {
      if (!_accountDisposed &&
          revision == _loadRevision &&
          supabase.auth.currentUser?.id == user.id) {
        errorMessage = '리스트를 불러오지 못했어요. 다시 시도해주세요.';
      }
    } finally {
      if (!_accountDisposed &&
          revision == _loadRevision &&
          supabase.auth.currentUser?.id == user.id) {
        isLoading = false;
        notifyListeners();
      }
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

    if (_accountDisposed || !_deletingIds.add(listId)) return;
    _loadRevision++;
    isLoading = false;
    errorMessage = null;
    notifyListeners();
    try {
      final deleted = await supabase
          .from('lists')
          .delete()
          .eq('id', listId)
          .eq('user_id', user.id)
          .select('id');
      if (deleted.isEmpty) throw StateError('리스트를 삭제하지 못했습니다.');
      if (_accountDisposed || supabase.auth.currentUser?.id != user.id) return;
      _loadRevision++;
      _deletedIds.add(listId);
      lists.removeWhere((list) => list.id == listId);
      isLoading = false;
    } catch (_) {
      if (_accountDisposed || supabase.auth.currentUser?.id != user.id) return;
      _deletingIds.remove(listId);
      await loadLists();
      if (!_accountDisposed && supabase.auth.currentUser?.id == user.id) {
        errorMessage = '리스트를 삭제하지 못했어요. 다시 시도해주세요.';
      }
    } finally {
      _deletingIds.remove(listId);
      if (!_accountDisposed && supabase.auth.currentUser?.id == user.id) {
        notifyListeners();
      }
    }
  }

  Future<void> decrementCollaboratorCount(String listId) async {
    // lists에서 해당 리스트 찾아 collaboratorCount 감소
    final index = lists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      final currentList = lists[index];

      lists[index] = currentList.copyWith(
        collaboratorCount: currentList.collaboratorCount > 0
            ? currentList.collaboratorCount - 1
            : 0,
      );

      notifyListeners();
    }
  }

  @override
  void dispose() {
    _accountDisposed = true;
    _loadRevision++;
    super.dispose();
  }
}
