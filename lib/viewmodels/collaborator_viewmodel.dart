import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/list_model.dart';

class CollaboratorViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  List<String> _collaborators = [];
  List<String> get collaborators => _collaborators;

  List<Map<String, String>> _friends = [];
  List<Map<String, String>> get friends => _friends;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? get currentUserId => supabase.auth.currentUser?.id;

  Future<void> fetchCollaboratorCounts(List<ListModel> lists) async {
    for (var list in lists) {
      try {
        final rawResponse = await supabase
            .from('list_members')
            .select('id')
            .eq('list_id', list.id);

        final List data = rawResponse as List? ?? [];
        list.collaboratorCount = data.length;
      } catch (e) {
        list.collaboratorCount = 0;
      }
    }
    notifyListeners();
  }



  /// 협업자 닉네임으로 추가 (친구 목록에서 초대 시 사용)
  Future<bool> addCollaborator(String listId, String nickname) async {
    _setLoading(true);
    _setError(null);

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _setError('로그인이 필요합니다.');
      _setLoading(false);
      return false;
    }

    try {
      final profileResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();

      if (profileResponse == null || profileResponse['id'] == null) {
        _setError('존재하지 않는 닉네임입니다.');
        _setLoading(false);
        return false;
      }

      final collaboratorId = profileResponse['id'] as String;

      final exists = await supabase
          .from('list_members')
          .select('id')
          .eq('list_id', listId)
          .eq('user_id', collaboratorId)
          .limit(1);

      if (exists.isNotEmpty) {
        _setError('이미 협업자 목록에 있습니다.');
        _setLoading(false);
        return false;
      }

      await supabase.from('list_members').insert({
        'list_id': listId,
        'user_id': collaboratorId,
        'invited_by': currentUser.id,
        'role': 'editor',
      });

      await getCollaborators(listId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('협업자 추가 실패: $e');
      _setLoading(false);
      return false;
    }
  }

  /// 협업자 목록 조회 (초대 후 최신 상태 갱신용)
  Future<void> getCollaborators(String listId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await supabase
          .from('list_members')
          .select('profiles!list_members_user_id_fkey(nickname)')
          .eq('list_id', listId);

      final List data = response as List;
      _collaborators = data
          .map((e) => e['profiles']?['nickname'] as String? ?? '알 수 없음')
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('협업자 목록 조회 실패: $e');
      _collaborators = [];
      _setLoading(false);
    }
  }

  /// 친구 목록 조회 (닉네임, id 포함)
  Future<void> getFriends() async {
    _setLoading(true);
    _setError(null);

    final currentUserId = this.currentUserId;
    if (currentUserId == null) {
      _setError('로그인이 필요합니다.');
      _setLoading(false);
      return;
    }

    try {
      final friends1 = await supabase
          .from('friends')
          .select('user2_id, profiles!friends_user2_id_fkey(id, nickname)')
          .eq('user1_id', currentUserId);

      final friends2 = await supabase
          .from('friends')
          .select('user1_id, profiles!friends_user1_id_fkey(id, nickname)')
          .eq('user2_id', currentUserId);

      List<Map<String, String>> result = [];

      for (var f in friends1) {
        result.add({
          'id': f['user2_id'] as String,
          'nickname': f['profiles']['nickname'] as String,
        });
      }

      for (var f in friends2) {
        result.add({
          'id': f['user1_id'] as String,
          'nickname': f['profiles']['nickname'] as String,
        });
      }

      _friends = result;
      _setLoading(false);
    } catch (e) {
      _setError('친구 목록 조회 실패: $e');
      _friends = [];
      _setLoading(false);
    }
  }

  // 상태 세터들
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}
