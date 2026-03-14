import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/list_model.dart';
import '../models/Collaborator_model.dart';

class CollaboratorViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Collaborator> _collaborators = [];
  List<Collaborator> get collaborators => _collaborators;

  List<Map<String, String>> _friends = [];
  List<Map<String, String>> get friends => _friends;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  String? get error => _errorMessage;

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? get currentUserId => supabase.auth.currentUser?.id;

  String? _listOwnerId;
  String? _listOwnerNickname;
  bool _isCurrentUserOwner = false;

  String? get listOwnerId => _listOwnerId;
  String? get listOwnerNickname => _listOwnerNickname;
  bool get isCurrentUserOwner => _isCurrentUserOwner;

  Future<void> loadListOwner(String listId) async {
    try{
      final res = await supabase
          .from('lists')
          .select('user_id, profiles!lists_user_id_fkey(nickname)')
          .eq('id', listId)
          .single();

      _listOwnerId = res['user_id'] as String?;
      final profile = res['profiles'] as Map?;
      _listOwnerNickname = profile?['nickname'] as String?;

      final currentUid = supabase.auth.currentUser?.id;
      _isCurrentUserOwner = currentUid != null && currentUid == _listOwnerId;

      notifyListeners();
    } catch (e) {
      // 에러 처리 (필요 시)
    }
  }

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

  /// 협업자 목록 조회 - nickname, role, user_id 포함
  Future<void> getCollaborators(String listId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await supabase
          .from('list_members')
          .select('''
          user_id,
          role,
          profiles!list_members_user_id_fkey (nickname)
        ''')
          .eq('list_id', listId)
          .order('created_at', ascending: true);  // 초대 순서대로 정렬 (선택)

      final List data = response;

      _collaborators = data.map((row) {
        final profile = row['profiles'] as Map?;
        return Collaborator(
          userId: row['user_id'] as String,
          nickname: profile?['nickname'] as String? ?? '알 수 없음',
          role: row['role'] as String? ?? 'editor',
        );
      }).toList();

      _setLoading(false);
    } catch (e) {
      _setError('협업자 목록 조회 실패: $e');
      _collaborators = [];
      _setLoading(false);
    }
  }

  /// 친구 목록 조회 (초대 가능한 친구만)
  Future<void> getFriends(String listId) async {
    _setLoading(true);
    _setError(null);

    final currentUserId = this.currentUserId;
    if (currentUserId == null) {
      _setError('로그인이 필요합니다.');
      _setLoading(false);
      return;
    }

    try {
      // 1. 내 친구 전체 ID + 닉네임 가져오기
      final friends1 = await supabase
          .from('friends')
          .select('user2_id, profiles!friends_user2_id_fkey(id, nickname)')
          .eq('user1_id', currentUserId);

      final friends2 = await supabase
          .from('friends')
          .select('user1_id, profiles!friends_user1_id_fkey(id, nickname)')
          .eq('user2_id', currentUserId);

      final allFriendMap = <String, String>{}; // id → nickname

      for (var f in friends1) {
        final id = f['user2_id'] as String;
        final nickname = (f['profiles'] as Map)['nickname'] as String?;
        if (nickname != null) allFriendMap[id] = nickname;
      }

      for (var f in friends2) {
        final id = f['user1_id'] as String;
        final nickname = (f['profiles'] as Map)['nickname'] as String?;
        if (nickname != null) allFriendMap[id] = nickname;
      }

      // 2. 이미 이 리스트에 속한 멤버 ID들
      final membersRes = await supabase
          .from('list_members')
          .select('user_id')
          .eq('list_id', listId);

      final memberIds = membersRes.map((e) => e['user_id'] as String).toSet();

      // 3. 리스트 owner ID
      final listRes = await supabase
          .from('lists')
          .select('user_id')
          .eq('id', listId)
          .single();

      final ownerId = listRes['user_id'] as String;

      // 4. 제외 대상 집합
      final excludeIds = <String>{...memberIds, ownerId, currentUserId};

      // 5. 최종 초대 가능 친구만 필터링
      final available = <Map<String, String>>[];

      allFriendMap.forEach((id, nickname) {
        if (!excludeIds.contains(id)) {
          available.add({'id': id, 'nickname': nickname});
        }
      });

      _friends = available;
      _setLoading(false);
    } catch (e) {
      _setError('친구 목록 조회 실패: $e');
      _friends = [];
      _setLoading(false);
    }
  }
}
