import 'package:flutter/material.dart';
import '../viewmodels/friend_management_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendManagementView extends StatefulWidget {
  const FriendManagementView({Key? key}) : super(key: key);

  @override
  State<FriendManagementView> createState() => _FriendManagementViewState();
}

class _FriendManagementViewState extends State<FriendManagementView> {
  final FriendManagementViewModel _viewModel = FriendManagementViewModel();
  final TextEditingController emailController = TextEditingController();

  // 상태 관리용 친구 요청 리스트, 친구 리스트를 Future로 관리
  late Future<List<Map<String, dynamic>>> _receivedRequestsFuture;
  late Future<List<Map<String, dynamic>>> _friendsListFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _receivedRequestsFuture = _fetchReceivedFriendRequests();
      _friendsListFuture = _viewModel.getFriendsList();
    });
  }

  // 현재 유저의 friend_requests 배열에서 ID 목록을 가져와서 이메일로 변환
  Future<List<Map<String, dynamic>>> _fetchReceivedFriendRequests() async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    final userData = await supabase
        .from('users')
        .select('friend_requests')
        .eq('id', currentUserId)
        .maybeSingle();

    if (userData == null) return [];

    List<dynamic> requestUserIds = userData['friend_requests'] ?? [];

    List<Map<String, dynamic>> requestUsers = [];

    for (String userId in requestUserIds) {
      final user = await supabase
          .from('users')
          .select('id, email')
          .eq('id', userId)
          .maybeSingle();

      if (user != null) {
        requestUsers.add(user);
      }
    }
    return requestUsers;
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
              controller: emailController,
              decoration: InputDecoration(labelText: "친구 이메일 입력"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text.trim();
                if (email.isNotEmpty) {
                  await _viewModel.sendFriendRequest(context, email);
                  emailController.clear();
                  _refreshData(); // 요청 보낸 후 리스트 갱신
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('이메일을 입력하세요.')));
                }
              },
              child: Text("친구 요청 보내기"),
            ),
            SizedBox(height: 20),
            Divider(),
            Text("받은 친구 요청", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

// 받은 친구 요청 리스트
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _receivedRequestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());

                  if (snapshot.hasError)
                    return Center(child: Text("오류 발생: ${snapshot.error}"));

                  final requests = snapshot.data ?? [];
                  if (requests.isEmpty)
                    return Center(child: Text("받은 친구 요청이 없습니다."));

                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return ListTile(
                        title: Text(request['email']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check),
                              onPressed: () async {
                                await _viewModel.acceptFriendRequest(context, request['id']);
                                _refreshData();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () async {
                                await _viewModel.declineFriendRequest(context, request['id']);
                                _refreshData();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Divider(),
            Text("친구 목록", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

// 친구 목록 리스트
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _friendsListFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());

                  if (snapshot.hasError)
                    return Center(child: Text("오류 발생: ${snapshot.error}"));

                  final friends = snapshot.data ?? [];
                  if (friends.isEmpty)
                    return Center(child: Text("친구가 없습니다."));

                  return ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      return ListTile(title: Text(friend['email']));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
