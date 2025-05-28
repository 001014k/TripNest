import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendManagementViewModel extends ChangeNotifier {
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;


  // 친구 요청 보내기 함수
  Future<void> sendFriendRequest(BuildContext context,String email) async {
    try {
      // 이메일로 사용자 문서 찾기
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        // 요청받는 사용자 UID 가져오기
        String toUserId = userDoc.docs.first.id;

        // 현재 사용자 ID가 있는지 확인
        if (currentUserId.isNotEmpty) {
          // 수신자의 사용자 문서 가져오기
          var toUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(toUserId)
              .get();

          // `friend_requests` 필드가 없다면 필드를 생성
          if (!toUserDoc.exists ||
              !toUserDoc.data()!.containsKey('friend_requests')) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(toUserId)
                .update({
              'friend_requests': [],
            });
          }

          // 수신자의 `friend_requests` 필드에 현재 사용자 ID 추가
          await FirebaseFirestore.instance
              .collection('users')
              .doc(toUserId)
              .update({
            'friend_requests': FieldValue.arrayUnion([currentUserId]),
          });

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('친구 요청이 전송되었습니다.')));
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('사용자를 찾을 수 없습니다.')));
      }
    } catch (e) {
      print('오류 발생: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  // 친구 요청 수락 함수
  Future<void> acceptFriendRequest(BuildContext context,String friendUserId) async {
    try {
      // 친구 추가 (현재 사용자와 요청 보낸 사용자 모두 업데이트)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'friends': FieldValue.arrayUnion([friendUserId]),
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUserId)
          .update({
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      // 친구 요청 목록에서 요청 보낸 사용자 제거
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'friend_requests': FieldValue.arrayRemove([friendUserId]),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('친구 요청을 수락했습니다.')));
    } catch (e) {
      print('오류 발생: $e');
    }
  }

  // 친구 요청 거절 함수
  Future<void> declineFriendRequest(BuildContext context,String friendUserId) async {
    try {
      // 친구 요청 목록에서 요청 보낸 사용자 제거
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'friend_requests': FieldValue.arrayRemove([friendUserId]),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('친구 요청을 거절했습니다.')));
    } catch (e) {
      print('오류 발생: $e');
    }
  }

  // 친구 목록 가져오기
  Future<List<Map<String, dynamic>>> getFriendsList() async {
    List<Map<String, dynamic>> friendsList = [];

    // 현재 사용자 문서 조회
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    // friends 필드에서 친구 UID 목록 가져오기
    List<String> friends = List<String>.from(userDoc.data()?['friends'] ?? []);

    // 각 친구 UID에 대해 친구 문서 조회
    for (String friendId in friends) {
      var friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .get();
      if (friendDoc.exists) {
        // 친구의 이메일과 UID를 포함한 정보를 추가
        friendsList.add({
          'id': friendDoc.id,
          'email': friendDoc.data()?['email'],
        });
      }
    }
    return friendsList; // 친구 목록 반환
  }
}