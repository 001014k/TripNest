import 'package:fluttertrip/views/profile_view.dart';
import 'package:provider/provider.dart';
import '../viewmodels/friend_management_viewmodel.dart';
import 'package:flutter/material.dart';
import '../viewmodels/mapsample_viewmodel.dart';
import '../widgets/menu_item.dart';
import 'BookmarkListTab_view.dart';
import 'mapsample_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class FriendManagementView extends StatefulWidget {
  const FriendManagementView({Key? key}) : super(key: key);

  @override
  State<FriendManagementView> createState() => _FriendManagementViewState();
}

class _FriendManagementViewState extends State<FriendManagementView> {
  final FriendManagementViewModel _viewModel = FriendManagementViewModel();

  late Future<List<Map<String, dynamic>>> _receivedRequestsFuture;
  late Future<List<Map<String, dynamic>>> _friendsListFuture;

  final zoomDrawerController = ZoomDrawerController();
  int selectedIndex = 3;

  void onItemSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: zoomDrawerController,
      menuBackgroundColor: const Color(0xFF242629), // 어두운 배경
      shadowLayer1Color: const Color(0xFF47454E),       // 어두운 그림자
      shadowLayer2Color: const Color(0xFFE6E6E6).withOpacity(0.3), // 어두운 그림자 (반투명)
      borderRadius: 32.0,
      showShadow: true,
      style: DrawerStyle.defaultStyle,
      angle: -12.0,
      drawerShadowsBackgroundColor: Colors.black38, // 어두운 그림자 배경
      slideWidth: MediaQuery.of(context).size.width * 0.7,
      menuScreen: _buildMenuScreen(context),
      mainScreen: _buildMainScreen(context),
    );
  }

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
  Widget _buildMainScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '친구 관리',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            zoomDrawerController.toggle?.call();
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _buildSectionTitle('친구 요청'),
            Expanded(child: _buildFriendRequests()),
            const SizedBox(height: 16),
            _buildSectionTitle('친구 목록'),
            Expanded(child: _buildFriendsList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFriendRequestDialog(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFriendRequests() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _receivedRequestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Text(
              '받은 친구 요청이 없습니다.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final request = requests[index];
            final nickname = request['requester']['nickname'] ?? '알 수 없음';
            final requesterId = request['requester_id'];

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              title: Text(
                nickname,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: SizedBox(
                width: 110,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await _viewModel.acceptFriendRequest(context, requesterId);
                        _refreshData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        '수락',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        await _viewModel.declineFriendRequest(context, requesterId);
                        _refreshData();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        '거절',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _friendsListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        }

        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return const Center(
            child: Text(
              '친구가 없습니다.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: friends.length,
          padding: const EdgeInsets.only(bottom: 12),
          itemBuilder: (context, index) {
            final friend = friends[index];
            final nickname = friend['nickname'] ?? '알 수 없음';

            final isOnline = friend['is_online'] ?? false;
            final friendStatusText = isOnline ? '온라인' : '오프라인';
            final friendStatusColor = isOnline ? Colors.greenAccent : Colors.grey;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Card(
                color: Colors.black, // 카드 배경 검정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: Colors.black54,
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade800,
                    child: Text(
                      nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  title: Text(
                    nickname,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white), // 흰색 텍스트
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: friendStatusColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          friendStatusText,
                          style: TextStyle(
                            color: friendStatusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        color: Colors.grey[900], // 메뉴 배경 어둡게
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          // 메뉴 선택 처리
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: '삭제',
                            child: Text('친구 삭제',
                                style: TextStyle(color: Colors.white)),
                          ),
                          PopupMenuItem(
                            value: '차단',
                            child: Text('친구 차단',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFriendRequestDialog(BuildContext context) {
    final TextEditingController dialogController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey.shade100, // 연한 회색 배경으로 미니멀하게
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '친구 요청 보내기',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: dialogController,
                autofocus: true,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: '닉네임 입력',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      String nickname = dialogController.text.trim();
                      if (nickname.isNotEmpty) {
                        await _viewModel.sendFriendRequest(context, nickname);
                        Navigator.of(context).pop();
                        _refreshData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('닉네임을 입력하세요.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Colors.blueAccent),
                    ),
                    child: const Text(
                      '요청 보내기',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuScreen(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: const Color(0xFF242629),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Profile Picture and Email
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF242629), // 다크모드 조건 제거하고 무조건 흰색
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primary,
                      backgroundImage: AssetImage('assets/cad.png'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "kim",
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            user != null
                                ? user.email ?? 'No email'
                                : 'Not logged in',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 메뉴 항목들
              MenuItem(
                title: '지도',
                icon: Icons.map,
                iconColor: Colors.white,
                textColor: Colors.white,
                isSelected: selectedIndex == 0,
                onTap: () {
                  zoomDrawerController.toggle?.call();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapSampleView(), // <- 원하는 지도 화면 위젯으로 수정
                    ),
                  );
                },
              ),
              MenuItem(
                title: '프로필',
                icon: Icons.account_circle,
                iconColor: Colors.white,
                textColor: Colors.white,
                isSelected: selectedIndex == 1,
                onTap: () async {
                  zoomDrawerController.toggle?.call();
                  onItemSelected(1);
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    String userId = user.id;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(userId: userId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그인 후 사용해 주세요.')),
                    );
                  }
                },
              ),
              MenuItem(
                title: '북마크/리스트',
                icon: Icons.list,
                iconColor: Colors.white,
                textColor: Colors.white,
                isSelected: selectedIndex == 2,
                onTap: () {
                  zoomDrawerController.toggle?.call();
                  onItemSelected(2);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookmarklisttabView(initialIndex: 0),
                    ),
                  );
                },
              ),
              MenuItem(
                title: '친구',
                icon: Icons.person_add,
                iconColor: Colors.white,
                textColor: Colors.white,
                isSelected: selectedIndex == 3,
                onTap: () {
                  zoomDrawerController.toggle?.call();
                  onItemSelected(3);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendManagementView(),
                    ),
                  );
                },
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('로그아웃',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          content: Text('로그아웃하시겠습니까?'),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('예',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('아니오',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirm == true) {
                      await Supabase.instance.client.auth.signOut();
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .pushReplacementNamed('/login_option');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    "로그아웃",
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
