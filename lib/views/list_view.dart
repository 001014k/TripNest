import 'package:flutter/material.dart';
import 'package:fluttertrip/views/profile_view.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/list_viewmodel.dart';
import 'marker_info_view.dart';
import '../widgets/menu_item.dart';
import 'BookmarkListTab_view.dart';
import 'friend_management_view.dart';
import 'mapsample_view.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final zoomDrawerController = ZoomDrawerController();
  int selectedIndex = 2;

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
    // ChangeNotifierProvider 제거!!
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '여행 리스트',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            zoomDrawerController.toggle?.call();
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<ListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: viewModel.lists.length,
            itemBuilder: (context, index) {
              final list = viewModel.lists[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  key: ValueKey(list.id),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.list_alt_rounded, color: Colors.black87),
                  title: Text(
                    list.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    '마커 갯수: ${list.markerCount}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: const Icon(Icons.more_vert, color: Colors.black54),
                  onTap: () => _showListOptions(context, list.id, viewModel),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateListDialog(context),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add),
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  void _showCreateListDialog(BuildContext context) {
    final TextEditingController _listNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '새 리스트',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _listNameController,
                  decoration: const InputDecoration(
                    hintText: '리스트 이름',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final name = _listNameController.text.trim();
                        if (name.isNotEmpty) {
                          await Provider.of<ListViewModel>(context, listen: false).createList(name);
                          Navigator.of(context).pop(); // createList 완료 후에 닫기
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('생성'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showListOptions(BuildContext context, String listId, ListViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 리스트 열기 카드
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarkerInfoPage(listId: listId),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new, color: Colors.blueAccent),
                        SizedBox(width: 16),
                        Text(
                          '리스트 열기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 리스트 삭제 카드
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text(
                            '리스트 삭제',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: const Text('정말로 리스트를 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('취소'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('삭제'),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirm == true) {
                      await viewModel.deleteList(listId);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.redAccent),
                        SizedBox(width: 16),
                        Text(
                          '리스트 삭제',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
