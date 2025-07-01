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
      appBar: AppBar(title: const Text("친구 관리")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSectionTitle("📥 받은 친구 요청"),
            _buildRequestList(),
            const SizedBox(height: 20),
            _buildSectionTitle("👥 친구 목록"),
            _buildFriendList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFriendRequestDialog(context),
        backgroundColor: Colors.white,
        child: const Icon(Icons.person_add, color: Colors.black),
      ),
    );
  }

  void _showFriendRequestDialog(BuildContext context) {
    final TextEditingController dialogController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("친구 요청", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: dialogController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "닉네임 입력",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                String nickname = dialogController.text.trim();
                if (nickname.isNotEmpty) {
                  await _viewModel.sendFriendRequest(context, nickname);
                  Navigator.of(context).pop();
                  _refreshData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("닉네임을 입력하세요.")),
                  );
                }
              },
              child: const Text("요청 보내기"),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text("취소"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRequestList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _receivedRequestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        if (snapshot.hasError)
          return Center(child: Text("오류 발생: ${snapshot.error}"));

        final requests = snapshot.data ?? [];
        if (requests.isEmpty)
          return const Center(child: Text("받은 친구 요청이 없습니다."));

        return Column(
          children: requests.map((request) {
            final nickname = request['requester']['nickname'] ?? '알 수 없음';
            final id = request['requester_id'];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(nickname),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await _viewModel.acceptFriendRequest(context, id);
                        _refreshData();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () async {
                        await _viewModel.declineFriendRequest(context, id);
                        _refreshData();
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFriendList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _friendsListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        if (snapshot.hasError)
          return Center(child: Text("오류 발생: ${snapshot.error}"));

        final friends = snapshot.data ?? [];
        if (friends.isEmpty)
          return const Center(child: Text("친구가 없습니다."));

        return Column(
          children: friends.map((friend) {
            final nickname = friend['nickname'] ?? '알 수 없음';
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(nickname),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
