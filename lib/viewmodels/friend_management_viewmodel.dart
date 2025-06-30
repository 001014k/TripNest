import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendManagementViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  // 친구 요청 보내기 함수
  Future<void> sendFriendRequest(BuildContext context, String nickname) async {
    try {
      // 1. 닉네임으로 사용자 찾기
      final userResponse = await supabase
          .from('users')
          .select('id, friend_requests')
          .eq('nickname', nickname)
          .maybeSingle();

      if (userResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자를 찾을 수 없습니다.')),
        );
        return;
      }

      final toUserId = userResponse['id'] as String;
      List<dynamic> friendRequests = userResponse['friend_requests'] ?? [];

      // 중복 친구 요청 방지
      if (friendRequests.contains(currentUserId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미 친구 요청을 보냈습니다.')),
        );
        return;
      }

      // 2. friend_requests 배열에 현재 사용자 ID 추가
      friendRequests.add(currentUserId);

      final updateResponse = await supabase
          .from('users')
          .update({'friend_requests': friendRequests})
          .eq('id', toUserId);

      if (updateResponse.error != null) {
        throw Exception(updateResponse.error!.message);
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

  // 친구 요청 수락 함수
  Future<void> acceptFriendRequest(BuildContext context, String friendUserId) async {
    try {
      // 1. 현재 사용자 데이터 조회
      final currentUserResponse = await supabase
          .from('users')
          .select('friends, friend_requests')
          .eq('id', currentUserId)
          .maybeSingle();

      // 2. 친구 데이터 조회
      final friendUserResponse = await supabase
          .from('users')
          .select('friends')
          .eq('id', friendUserId)
          .maybeSingle();

      if (currentUserResponse == null || friendUserResponse == null) {
        throw Exception('사용자 정보를 불러오지 못했습니다.');
      }

      List<dynamic> currentUserFriends = currentUserResponse['friends'] ?? [];
      List<dynamic> currentUserFriendRequests = currentUserResponse['friend_requests'] ?? [];
      List<dynamic> friendUserFriends = friendUserResponse['friends'] ?? [];

      // 3. 친구 목록에 서로 추가
      if (!currentUserFriends.contains(friendUserId)) {
        currentUserFriends.add(friendUserId);
      }
      if (!friendUserFriends.contains(currentUserId)) {
        friendUserFriends.add(currentUserId);
      }

      // 4. friend_requests에서 친구 요청자 제거
      currentUserFriendRequests.remove(friendUserId);

      // 5. 업데이트 수행 (트랜잭션이 아니므로 순서대로)
      await supabase
          .from('users')
          .update({
        'friends': currentUserFriends,
        'friend_requests': currentUserFriendRequests,
      })
          .eq('id', currentUserId);

      await supabase
          .from('users')
          .update({'friends': friendUserFriends})
          .eq('id', friendUserId);

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

  // 친구 요청 거절 함수
  Future<void> declineFriendRequest(BuildContext context, String friendUserId) async {
    try {
      // 현재 사용자 데이터 조회
      final currentUserResponse = await supabase
          .from('users')
          .select('friend_requests')
          .eq('id', currentUserId)
          .maybeSingle();

      if (currentUserResponse == null) {
        throw Exception('사용자 정보를 불러오지 못했습니다.');
      }

      List<dynamic> currentUserFriendRequests = currentUserResponse['friend_requests'] ?? [];

      // 친구 요청 목록에서 제거
      currentUserFriendRequests.remove(friendUserId);

      // 업데이트 수행
      await supabase
          .from('users')
          .update({'friend_requests': currentUserFriendRequests})
          .eq('id', currentUserId);

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

  // 친구 목록 가져오기
  Future<List<Map<String, dynamic>>> getFriendsList() async {
    List<Map<String, dynamic>> friendsList = [];

    try {
      final currentUserResponse = await supabase
          .from('users')
          .select('friends')
          .eq('id', currentUserId)
          .maybeSingle();

      if (currentUserResponse == null) {
        return friendsList;
      }

      List<dynamic> friendIds = currentUserResponse['friends'] ?? [];

      for (var friendId in friendIds) {
        final friendResponse = await supabase
            .from('users')
            .select('id, email')
            .eq('id', friendId)
            .maybeSingle();

        if (friendResponse != null) {
          friendsList.add(friendResponse);
        }
      }
    } catch (e) {
      print('오류 발생: $e');
    }

    return friendsList;
  }
}