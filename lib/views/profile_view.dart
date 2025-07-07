import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/mapsample_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/menu_item.dart';
import 'BookmarkListTab_view.dart';
import 'friend_management_view.dart';
import 'mapsample_view.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final zoomDrawerController = ZoomDrawerController();
  int selectedIndex = 1;

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
  Widget _buildMainScreen(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..fetchUserStats(widget.userId),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text('프로필',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  zoomDrawerController.toggle?.call();
                },
              ),
            ),
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: viewModel.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : viewModel.errorMessage != null
                  ? Center(
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (viewModel.nickname != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueGrey.shade200.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.account_circle, size: 40, color: Colors.blueGrey.shade700),
                            const SizedBox(width: 16),
                            Text(
                              viewModel.nickname!,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      '사용자 통계',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatCard('마커', viewModel.stats?['markers'] ?? 0, Icons.location_on),
                    const SizedBox(height: 12),
                    _buildStatCard('리스트', viewModel.stats?['lists'] ?? 0, Icons.list),
                    const SizedBox(height: 12),
                    _buildStatCard('북마크', viewModel.stats?['bookmarks'] ?? 0, Icons.bookmark),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.shade100.withOpacity(0.5),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueGrey.shade700),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade600,
            ),
          ),
        ],
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
