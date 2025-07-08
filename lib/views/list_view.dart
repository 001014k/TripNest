import 'package:flutter/material.dart';
import 'package:fluttertrip/views/widgets/zoom_drawer_container.dart';
import 'package:provider/provider.dart';
import '../viewmodels/list_viewmodel.dart';
import 'marker_info_view.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../viewmodels/collaborator_viewmodel.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final zoomDrawerController = ZoomDrawerController();
  int selectedIndex = 2; // 북마크/리스트 탭을 의미하는 인덱스

  @override
  Widget build(BuildContext context) {
    return ZoomDrawerContainer(
      selectedIndex: selectedIndex,
      onItemSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
      mainScreenBuilder: (context) => _buildMainScreen(context),
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              ZoomDrawer.of(context)?.toggle();
            },
          ),
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '마커 갯수: ${list.markerCount}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '초대된 사람 수: ${list.collaboratorCount}',  // collaboratorCount가 없으면 0으로 표시
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
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

  void _showCollaborationDialog(BuildContext context, String listId) {
    final collaboratorVM = Provider.of<CollaboratorViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        // 다이얼로그 빌드 시점에 데이터 로드
        collaboratorVM.getCollaborators(listId);
        collaboratorVM.getFriends();

        return ChangeNotifierProvider.value(
          value: collaboratorVM,
          child: Consumer<CollaboratorViewModel>(
            builder: (context, vm, child) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('친구 목록에서 초대', style: TextStyle(fontWeight: FontWeight.bold)),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : vm.friends.isEmpty
                      ? const Center(child: Text('친구가 없습니다.'))
                      : ListView.builder(
                    itemCount: vm.friends.length,
                    itemBuilder: (context, index) {
                      final friend = vm.friends[index];
                      final nickname = friend['nickname'] as String;
                      final isAlreadyCollaborator = vm.collaborators.contains(nickname);

                      // 친구 상태 텍스트 및 색상 설정 (원하는 대로 변경 가능)
                      final friendStatusText = isAlreadyCollaborator ? '이미 초대됨' : '초대 가능';
                      final friendStatusColor = isAlreadyCollaborator ? Colors.grey : Colors.blueAccent;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Card(
                          color: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: Colors.black54,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                color: Colors.white,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                if (!isAlreadyCollaborator)
                                  IconButton(
                                    icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                                    onPressed: () async {
                                      final success = await vm.addCollaborator(listId, nickname);
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('초대 성공')),
                                        );
                                        await vm.getCollaborators(listId);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(vm.errorMessage ?? '초대 실패')),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('닫기'),
                  ),
                ],
              );
            },
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
              const SizedBox(height: 12),

              // 리스트 협업 관리 카드
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pop(context);
                    _showCollaborationDialog(context, listId);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.group, color: Colors.deepPurple),
                        SizedBox(width: 16),
                        Text(
                          '협업 관리',
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
            ],
          ),
        );
      },
    );
  }
}
