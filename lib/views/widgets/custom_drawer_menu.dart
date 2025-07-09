import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../views/bookmarklisttab_view.dart';
import '../../views/friend_management_view.dart';
import '../../views/mapsample_view.dart';
import '../../views/profile_view.dart';
import '../widgets/menu_item.dart'; // 당신의 MenuItem 위젯

class CustomDrawerMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int index) onItemSelected;

  const CustomDrawerMenu({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final zoomDrawerController = ZoomDrawer.of(context);

    return Material(
      color: const Color(0xFF242629),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF242629),
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
                          Text("kim", style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(user?.email ?? 'Not logged in',
                              style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              MenuItem(
                title: '지도',
                icon: Icons.map,
                iconColor: Colors.white,
                textColor: Colors.white,
                isSelected: selectedIndex == 0,
                onTap: () {
                  zoomDrawerController?.toggle?.call();
                  onItemSelected(0);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MapSampleView()));
                },
              ),
              MenuItem(
                title: '프로필',
                icon: Icons.account_circle,
                iconColor: Colors.white,
                textColor: Colors.white,
                isSelected: selectedIndex == 1,
                onTap: () {
                  zoomDrawerController?.toggle?.call();
                  onItemSelected(1);
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfilePage(userId: user.id)),
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
                  zoomDrawerController?.toggle?.call();
                  onItemSelected(2);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BookmarklisttabView(initialIndex: 0)),
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
                  zoomDrawerController?.toggle?.call();
                  onItemSelected(3);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FriendManagementView()),
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
                      builder: (context) => AlertDialog(
                        title: Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Text('로그아웃하시겠습니까?'),
                        actions: [
                          ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('예')),
                          ElevatedButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('아니오')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await Supabase.instance.client.auth.signOut();
                      // 화면 이동 시 뒤로가기 못 하도록 전부 제거
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login_option',
                            (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text("로그아웃", style: textTheme.titleSmall),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
