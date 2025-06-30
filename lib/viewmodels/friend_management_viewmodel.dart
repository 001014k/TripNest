import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendManagementViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  // 친구 요청 보내기
  Future<void> sendFriendRequest(BuildContext context, String nickname) async {
    try {
      // 1. 닉네임으로 사용자 찾기
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

      // 2. 이미 친구 요청 또는 친구인지 확인
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

      // 3. 친구 요청 생성
      final insertRes = await supabase.from('friend_requests').insert({
        'requester_id': currentUserId,
        'requested_id': toUserId,
        'status': 'pending',
      });

      if (insertRes.error != null) {
        throw Exception(insertRes.error!.message);
      }

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
          .select('requester_id, status, requester:profiles(id, nickname)')
          .eq('requested_id', currentUserId)
          .eq('status', 'pending');

      // res는 List<dynamic> 타입으로 반환됨
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      // 에러가 발생하면 예외로 처리하거나 빈 리스트 반환
      print('오류 발생: $e');
      return [];
    }
  }

  // 친구 요청 수락
  Future<void> acceptFriendRequest(BuildContext context, String requesterId) async {
    final currentUserId = this.currentUserId;

    try {
      // 1. friend_requests 상태 변경
      final updateReq = await supabase
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('requester_id', requesterId)
          .eq('requested_id', currentUserId);

      if (updateReq.error != null) throw Exception(updateReq.error!.message);

      // 2. friends 테이블에 친구 추가 (중복 체크 포함)
      final existingFriend = await supabase
          .from('friends')
          .select()
          .or('and(user1_id.eq.$currentUserId,user2_id.eq.$requesterId),and(user1_id.eq.$requesterId,user2_id.eq.$currentUserId)')
          .maybeSingle();

      if (existingFriend == null) {
        final insertFriend = await supabase.from('friends').insert({
          'user1_id': currentUserId,
          'user2_id': requesterId,
        });

        if (insertFriend.error != null) throw Exception(insertFriend.error!.message);
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
      final updateReq = await supabase
          .from('friend_requests')
          .update({'status': 'declined'})
          .eq('requester_id', requesterId)
          .eq('requested_id', currentUserId);

      if (updateReq.error != null) throw Exception(updateReq.error!.message);

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