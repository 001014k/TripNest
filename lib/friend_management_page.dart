import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendManagementPage extends StatefulWidget {
  @override
  _FriendManagementPageState createState() => _FriendManagementPageState();
}

class _FriendManagementPageState extends State<FriendManagementPage> {
  final TextEditingController _emailController = TextEditingController();
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // 친구 요청 보내기 함수
  Future<void> sendFriendRequest(String email) async {
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
          if (!toUserDoc.exists || !toUserDoc.data()!.containsKey('friend_requests')) {
            await FirebaseFirestore.instance.collection('users').doc(toUserId).update({
              'friend_requests': [],
            });
          }

          // 수신자의 `friend_requests` 필드에 현재 사용자 ID 추가
          await FirebaseFirestore.instance.collection('users').doc(toUserId).update({
            'friend_requests': FieldValue.arrayUnion([currentUserId]),
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('친구 요청이 전송되었습니다.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('사용자를 찾을 수 없습니다.')));
      }
    } catch (e) {
      print('오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  // 친구 요청 수락 함수
  Future<void> acceptFriendRequest(String friendUserId) async {
    try {
      // 친구 추가 (현재 사용자와 요청 보낸 사용자 모두 업데이트)
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayUnion([friendUserId]),
      });
      await FirebaseFirestore.instance.collection('users').doc(friendUserId).update({
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      // 친구 요청 목록에서 요청 보낸 사용자 제거
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'friend_requests': FieldValue.arrayRemove([friendUserId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('친구 요청을 수락했습니다.')));
    } catch (e) {
      print('오류 발생: $e');
    }
  }

  // 친구 요청 거절 함수
  Future<void> declineFriendRequest(String friendUserId) async {
    try {
      // 친구 요청 목록에서 요청 보낸 사용자 제거
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'friend_requests': FieldValue.arrayRemove([friendUserId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('친구 요청을 거절했습니다.')));
    } catch (e) {
      print('오류 발생: $e');
    }
  }

  // 친구 목록 가져오기
  Future<List<Map<String, dynamic>>> getFriendsList() async {
    List<Map<String, dynamic>> friendsList = [];

    // 현재 사용자 문서 조회
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    // friends 필드에서 친구 UID 목록 가져오기
    List<String> friends = List<String>. from(userDoc.data()?['friends'] ?? []);

    // 각 친구 UID에 대해 친구 문서 조회
    for (String friendId in friends) {
      var friendDoc = await FirebaseFirestore.instance.collection('users').doc(friendId).get();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("친구 관리")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 친구 이메일 입력 및 요청 보내기
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "친구 이메일 입력"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String email = _emailController.text.trim();
                if (email.isNotEmpty) {
                  sendFriendRequest(email);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이메일을 입력하세요.')));
                }
              },
              child: Text("친구 요청 보내기"),
            ),
            SizedBox(height: 20),
            Divider(),
            Text(
              "받은 친구 요청",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // 친구 요청 목록 표시
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  try {
                    // DocumentSnapshot에서 데이터를 가져오고, Map<String, dynamic>으로 캐스팅
                    Map<String, dynamic>? userData = snapshot.data!.data() as Map<String, dynamic>?;

                    // `friend_requests` 필드가 없으면 빈 배열 사용
                    List<String> friendRequests = userData?.containsKey('friend_requests') == true
                        ? (userData!['friend_requests'] as List<dynamic>).map((item) => item.toString()).toList()
                        : [];

                    if (friendRequests.isEmpty) {
                      return Center(child: Text("받은 친구 요청이 없습니다."));
                    }

                    return ListView.builder(
                      itemCount: friendRequests.length,
                      itemBuilder: (context, index) {
                        String friendUserId = friendRequests[index];

                        // 친구 이메일 가져오기
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(friendUserId).get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return ListTile(title: Text('Loading...'));
                            }
                            String friendEmail = userSnapshot.data!['email'];

                            return ListTile(
                              title: Text(friendEmail),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.check),
                                    onPressed: () => acceptFriendRequest(friendUserId),  // 수락 함수 호출
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () => declineFriendRequest(friendUserId),  // 거절 함수 호출
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  } catch (e, stackTrace) {
                    // 오류 로그 출력
                    print("Error processing friend requests: $e");
                    print("Stack trace: $stackTrace");
                    return Center(child: Text("친구 요청을 불러오는 중 오류가 발생했습니다."));
                  }
                },
              ),
            ),
            Divider(), // 친구 목록 구분선 추가
            Text(
              "친구 목록",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // 친구 목록 표시
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: getFriendsList(), // 친구 목록 가져오기
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("오류 발생: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("친구가 없습니다."));
                  }

                  try {
                    // 친구 목록을 ListView로 표시
                    List<Map<String, dynamic>> friendsList = snapshot.data!;
                    return ListView.builder(
                      itemCount: friendsList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(friendsList[index]['email']), // 친구 이메일 표시
                        );
                      },
                    );
                  } catch (e, stackTrace) {
                    // 오류 로그 출력
                    print("Error processing friends list: $e");
                    print("Stack trace: $stackTrace");
                    return Center(child: Text("친구 목록을 불러오는 중 오류가 발생했습니다."));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
