import '../viewmodels/friend_management_viewmodel.dart';
import 'package:flutter/material.dart';

class FriendManagementView extends StatefulWidget {
  const FriendManagementView({Key? key}) : super(key: key);

  @override
  State<FriendManagementView> createState() => _FriendManagementViewState();
}

class _FriendManagementViewState extends State<FriendManagementView> {
  final FriendManagementViewModel _viewModel = FriendManagementViewModel();
  final TextEditingController nicknameController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _receivedRequestsFuture;
  late Future<List<Map<String, dynamic>>> _friendsListFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _receivedRequestsFuture = _viewModel.getReceivedFriendRequests();
      _friendsListFuture = _viewModel.getFriendsList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("친구 관리")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 친구 닉네임 입력 및 요청 보내기
            TextField(
              controller: nicknameController,
              decoration: InputDecoration(labelText: "친구 닉네임 입력"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String nickname = nicknameController.text.trim();
                if (nickname.isNotEmpty) {
                  await _viewModel.sendFriendRequest(context, nickname);
                  nicknameController.clear();
                  _refreshData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('닉네임을 입력하세요.')));
                }
              },
              child: Text("친구 요청 보내기"),
            ),
            SizedBox(height: 20),
            Divider(),
            Text("받은 친구 요청",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        title: Text(request['requester']['nickname'] ?? '알 수 없는 사용자'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check),
                              onPressed: () async {
                                await _viewModel.acceptFriendRequest(context, request['requester_id']);
                                _refreshData();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () async {
                                await _viewModel.declineFriendRequest(context, request['requester_id']);
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
            Text("친구 목록",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      return ListTile(
                          title: Text(friend['nickname'] ?? '알 수 없는 친구'));
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
