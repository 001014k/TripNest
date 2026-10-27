import '../../services/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class FriendManagementViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  FriendManagementViewModel() {
    _watchRequests();
    _authSubscription = supabase.auth.onAuthStateChange.listen((_) => _watchRequests());
  }

  int pendingRequestCount = 0;
  String? _requestUserId;
  RealtimeChannel? _requestChannel;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _requestPoll;
  bool _disposed = false;
  int _requestRevision = 0;

  void _watchRequests() {
    final userId = supabase.auth.currentUser?.id;
    if (_requestUserId == userId) return;
    _requestUserId = userId;
    _requestRevision++;
    _requestChannel?.unsubscribe();
    _requestChannel = null;
    _requestPoll?.cancel();
    pendingRequestCount = 0;
    if (!_disposed) notifyListeners();
    if (userId == null) return;
    _requestChannel = supabase.channel('friend-request-badge-$userId')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public',
          table: 'friend_requests',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq,
              column: 'requested_id', value: userId),
          callback: (_) => refreshPendingRequestCount())
        .subscribe();
    unawaited(refreshPendingRequestCount());
    // Also refresh when realtime is unavailable for this table.
    _requestPoll = Timer.periodic(const Duration(seconds: 30),
        (_) => refreshPendingRequestCount());
  }

  Future<void> refreshPendingRequestCount() async {
    final userId = _requestUserId;
    if (userId == null || _disposed) return;
    final revision = ++_requestRevision;
    try {
      final count = await supabase.from('friend_requests').count()
          .eq('requested_id', userId).eq('status', 'pending');
      if (_disposed || revision != _requestRevision || userId != _requestUserId) return;
      if (pendingRequestCount != count) {
        pendingRequestCount = count;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('친구 요청 배지 조회 실패: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    _requestPoll?.cancel();
    _requestChannel?.unsubscribe();
    unsubscribePresence();
    super.dispose();
  }

  Set<String> onlineUserIds = {};
  RealtimeChannel? _presenceChannel;
  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  void subscribeToPresence() {
    if (_presenceChannel != null) return;

    _presenceChannel = supabase.channel('online-users');

    // 1. onPresenceSync를 사용하여 상태 변경 감지
    _presenceChannel!.onPresenceSync((payload) {
      final states = _presenceChannel!.presenceState();
      final onlineIds = <String>{};

      // 2. List<RealtimePresenceState>를 순회하며 user_id 추출
      for (var state in states) {
        for (var presence in state.presences) {
          final userId = presence.payload['user_id']?.toString();
          if (userId != null) onlineIds.add(userId);
        }
      }

      onlineUserIds = onlineIds;
      notifyListeners();
    }).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // 3. 본인 상태 추적 시작
        await _presenceChannel!.track({'user_id': currentUserId});
      }
    });
  }

  void unsubscribePresence() {
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
  }

  // 친구 요청 보내기
  Future<String> sendFriendRequest(String nickname) async {
    if (currentUserId.isEmpty) return '로그인이 필요합니다.';
    try {
      final userRes = await supabase
          .from('profiles')
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();

      if (userRes == null) {
        return '사용자를 찾을 수 없습니다.';
      }
      final toUserId = userRes['id'] as String;
      if (toUserId == currentUserId) return '나에게는 친구 요청을 보낼 수 없어요.';

      final existingReq = await supabase
          .from('friend_requests')
          .select()
          .or('and(requester_id.eq.$currentUserId,requested_id.eq.$toUserId),and(requester_id.eq.$toUserId,requested_id.eq.$currentUserId)')
          .maybeSingle();

      final existingFriend = await supabase
          .from('friends')
          .select()
          .or('and(user1_id.eq.$currentUserId,user2_id.eq.$toUserId),and(user1_id.eq.$toUserId,user2_id.eq.$currentUserId)')
          .maybeSingle();

      if (existingReq != null) {
        return '이미 친구 요청이 존재합니다.';
      }
      if (existingFriend != null) {
        return '이미 친구입니다.';
      }

      // insert는 List<dynamic> 반환이므로 에러처리는 try/catch로!
      final request = await supabase
          .from('friend_requests')
          .insert({
            'requester_id': currentUserId,
            'requested_id': toUserId,
            'status': 'pending',
          })
          .select('id')
          .single();
      await NotificationService(supabase: supabase)
          .notifyFriendRequest(request['id'].toString());

      return '친구 요청이 전송되었습니다.';
    } catch (e) {
      debugPrint('오류 발생: $e');
      return '오류 발생: $e';
    }
  }

  // 받은 친구 요청 리스트 조회 (requester 정보 포함)
  Future<List<Map<String, dynamic>>> getReceivedFriendRequests() async {
    final currentUserId = this.currentUserId;

    try {
      final res = await supabase
          .from('friend_requests')
          .select(
              'requester_id, status, requester:profiles!friend_requests_requester_id_fkey(id, nickname)')
          .eq('requested_id', currentUserId)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('오류 발생: $e');
      return [];
    }
  }

  // 친구 요청 수락
  Future<String> acceptFriendRequest(String requesterId) async {
    final currentUserId = this.currentUserId;

    try {
      await supabase
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('requester_id', requesterId)
          .eq('requested_id', currentUserId);

      final existingFriend = await supabase
          .from('friends')
          .select()
          .or('and(user1_id.eq.$currentUserId,user2_id.eq.$requesterId),and(user1_id.eq.$requesterId,user2_id.eq.$currentUserId)')
          .maybeSingle();

      if (existingFriend == null) {
        await supabase.from('friends').insert({
          'user1_id': currentUserId,
          'user2_id': requesterId,
        });
      }

      await refreshPendingRequestCount();
      return '친구 요청을 수락했습니다.';
    } catch (e) {
      debugPrint('오류 발생: $e');
      return '오류 발생: $e';
    }
  }

  // 친구 요청 거절
  Future<String> declineFriendRequest(String requesterId) async {
    final currentUserId = this.currentUserId;

    try {
      await supabase
          .from('friend_requests')
          .update({'status': 'declined'})
          .eq('requester_id', requesterId)
          .eq('requested_id', currentUserId);

      await refreshPendingRequestCount();
      return '친구 요청을 거절했습니다.';
    } catch (e) {
      debugPrint('오류 발생: $e');
      return '오류 발생: $e';
    }
  }

  // 친구 목록 조회
  Future<List<Map<String, dynamic>>> getFriendsList() async {
    final currentUserId = this.currentUserId;

    final friends1 = await supabase
        .from('friends')
        .select('user2_id, profiles!friends_user2_id_fkey(id, nickname)')
        .eq('user1_id', currentUserId);

    final friends2 = await supabase
        .from('friends')
        .select('user1_id, profiles!friends_user1_id_fkey(id, nickname)')
        .eq('user2_id', currentUserId);

    List<Map<String, dynamic>> friendsList = [];

    void addFriend(String id, String nickname) {
      friendsList.add({
        'id': id,
        'nickname': nickname,
        'is_online': onlineUserIds.contains(id), // 실시간 상태 확인
      });
    }

    for (var f in friends1) {
      addFriend(f['user2_id'], f['profiles']['nickname']);
    }
    for (var f in friends2) {
      addFriend(f['user1_id'], f['profiles']['nickname']);
    }

    return friendsList;
  }

  // 친구 삭제 메서드
  Future<String> removeFriend(String friendId) async {
    try {
      final currentUserId = this.currentUserId;

      // 1. 친구 관계 삭제 (friends 테이블)
      await supabase.from('friends').delete().or(
          'and(user1_id.eq.$currentUserId,user2_id.eq.$friendId),and(user1_id.eq.$friendId,user2_id.eq.$currentUserId)');

      // 2. 여행 리스트 멤버 삭제 (list_members 테이블)
      // 내가 생성한 리스트들(lists 테이블의 owner) 중에서
      // 삭제할 친구(friendId)가 멤버로(list_members 테이블) 등록된 경우 삭제

      // 2-1. 내가 생성한 리스트들의 ID 가져오기
      final myListRes = await supabase
          .from('lists')
          .select('id')
          .eq('user_id', currentUserId);

      final myListIds =
          (myListRes as List).map((e) => e['id'] as String).toList();

      // 2-2. 해당 리스트들 중에서 삭제할 친구가 멤버인 행 삭제
      if (myListIds.isNotEmpty) {
        await supabase
            .from('list_members')
            .delete()
            .eq('user_id', friendId)
            .inFilter('list_id', myListIds);
      }

      // 3. 알림 및 UI 업데이트
      notifyListeners();
      return '친구 삭제 및 관련 여행 협업 관계가 해제되었습니다.';
    } catch (e) {
      debugPrint('친구 삭제 오류: $e');
      return '오류가 발생했습니다: $e';
    }
  }
}
