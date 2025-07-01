import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendManagementViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  // 친구 요청 보내기
  Future<void> sendFriendRequest(BuildContext context, String nickname) async {
    try {
      final userRes = await supabase
          .from('profiles')
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();

      if (userRes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자를 찾을 수 없습니다.')),
        );
        return;
      }
      final toUserId = userRes['id'] as String;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미 친구 요청이 존재합니다.')),
        );
        return;
      }
      if (existingFriend != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미 친구입니다.')),
        );
        return;
      }

      // insert는 List<dynamic> 반환이므로 에러처리는 try/catch로!
      await supabase.from('friend_requests').insert({
        'requester_id': currentUserId,
        'requested_id': toUserId,
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('친구 요청이 전송되었습니다.')),
      );
    } catch (e) {
      print('오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  // 받은 친구 요청 리스트 조회 (requester 정보 포함)
  Future<List<Map<String, dynamic>>> getReceivedFriendRequests() async {
    final currentUserId = this.currentUserId;

    try {
      final res = await supabase
          .from('friend_requests')
          .select('requester_id, status, requester:profiles!friend_requests_requester_id_fkey(id, nickname)')
          .eq('requested_id', currentUserId)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('오류 발생: $e');
      return [];
    }
  }

  // 친구 요청 수락
  Future<void> acceptFriendRequest(BuildContext context, String requesterId) async {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('친구 요청을 수락했습니다.')),
      );
    } catch (e) {
      print('오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  // 친구 요청 거절
  Future<void> declineFriendRequest(BuildContext context, String requesterId) async {
    final currentUserId = this.currentUserId;

    try {
      await supabase
          .from('friend_requests')
          .update({'status': 'declined'})
          .eq('requester_id', requesterId)
          .eq('requested_id', currentUserId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('친구 요청을 거절했습니다.')),
      );
    } catch (e) {
      print('오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
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

    for (var f in friends1) {
      friendsList.add({
        'id': f['user2_id'],
        'nickname': f['profiles']['nickname'],
      });
    }

    for (var f in friends2) {
      friendsList.add({
        'id': f['user1_id'],
        'nickname': f['profiles']['nickname'],
      });
    }
    return friendsList;
  }
}
