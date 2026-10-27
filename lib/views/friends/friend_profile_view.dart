import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../navigation/app_page_route.dart';
import '../../viewmodels/friends/friend_management_viewmodel.dart';
import '../../widgets/common/app_overlays.dart';
import '../../widgets/common/reference_design.dart';
import '../../widgets/common/social_design.dart';
import '../lists/marker_info_view.dart';

class FriendProfileView extends StatefulWidget {
  const FriendProfileView({super.key, required this.friend});
  final Map<String, dynamic> friend;
  @override
  State<FriendProfileView> createState() => _FriendProfileViewState();
}

class _FriendProfileViewState extends State<FriendProfileView> {
  late Future<List<Map<String, dynamic>>> data;
  @override
  void initState() {
    super.initState();
    data = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final db = Supabase.instance.client;
    final me = db.auth.currentUser?.id;
    if (me == null) return [];
    final memberships =
        await db.from('list_members').select('list_id').eq('user_id', me);
    final owned = await db.from('lists').select('id').eq('user_id', me);
    final ids = {
      ...memberships.map((x) => x['list_id'].toString()),
      ...owned.map((x) => x['id'].toString())
    };
    if (ids.isEmpty) return [];
    final friendMemberships = await db
        .from('list_members')
        .select('list_id')
        .eq('user_id', widget.friend['id'])
        .inFilter('list_id', ids.toList());
    final sharedIds =
        friendMemberships.map((x) => x['list_id'].toString()).toSet();
    final lists = await db
        .from('lists')
        .select(
            'id, name, user_id, list_bookmarks(title), list_members(user_id)')
        .inFilter('id', ids.toList());
    return lists
        .where((x) =>
            sharedIds.contains(x['id']) || x['user_id'] == widget.friend['id'])
        .toList();
  }

  void _open(Map<String, dynamic> list) => Navigator.push(
      context,
      AppPageRoute(
          builder: (_) =>
              MarkerInfoPage(listId: list['id'], listName: list['name'])));
  Future<void> _remove() async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (_) => AppConfirmDialog(
            title: '친구를 삭제할까요?',
            message: '친구 및 내 리스트의 협업 관계가 해제됩니다.',
            confirmLabel: '삭제',
            destructive: true,
            icon: Icons.person_remove_outlined));
    if (yes != true || !mounted) return;
    final message = await context
        .read<FriendManagementViewModel>()
        .removeFriend(widget.friend['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    if (message.startsWith('친구 삭제 및')) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.friend['nickname']?.toString() ?? '친구';
    final online = context
        .watch<FriendManagementViewModel>()
        .onlineUserIds
        .contains(widget.friend['id']);
    return Scaffold(
        backgroundColor: Colors.white,
        body: FutureBuilder<List<Map<String, dynamic>>>(
            future: data,
            builder: (context, snapshot) {
              final lists = snapshot.data ?? [];
              final places = <Map<String, dynamic>>[
                for (final l in lists)
                  for (final p in (l['list_bookmarks'] as List? ?? []))
                    {'title': p['title'], 'list': l}
              ];
              return CustomScrollView(slivers: [
                SliverToBoxAdapter(
                    child: Stack(children: [
                  Container(
                      height: 215,
                      color: socialFill,
                      child: places.isEmpty
                          ? const Center(
                              child: Icon(Icons.landscape_outlined,
                                  size: 65, color: Color(0xFFBFC4CB)))
                          : ReferencePhoto(
                              title: places.first['title'] ?? '',
                              width: double.infinity,
                              height: 215)),
                  Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      left: 12,
                      child: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: .9),
                          child: IconButton(
                              tooltip: '뒤로가기',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new,
                                  size: 20)))),
                  Container(
                      margin: const EdgeInsets.only(top: 190),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(26))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.translate(
                                offset: const Offset(0, -25),
                                child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle),
                                          child: SocialAvatar(
                                              name: name,
                                              url: widget.friend['avatar_url'],
                                              size: 94,
                                              online: online)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                          child: Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 9),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(name,
                                                        style: const TextStyle(
                                                            fontSize: 23,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700)),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                        online
                                                            ? '지금 온라인'
                                                            : '함께 여행하는 친구',
                                                        style: const TextStyle(
                                                            color: socialMuted,
                                                            fontSize: 13))
                                                  ])))
                                    ])),
                            const Text('함께 만드는 여행의 순간들',
                                style: TextStyle(
                                    color: socialMuted, fontSize: 15)),
                            const SizedBox(height: 20),
                            Row(children: [
                              _stat('${lists.length}', '함께한 리스트'),
                              const SizedBox(width: 10),
                              _stat('${places.length}', '공유된 장소')
                            ]),
                            const SizedBox(height: 16),
                            SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                    onPressed: _remove,
                                    icon: const Icon(
                                        Icons.person_remove_outlined,
                                        size: 19),
                                    label: const Text('친구 관리'),
                                    style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                        foregroundColor: Colors.black,
                                        side: const BorderSide(
                                            color: Color(0xFFDDDEE4)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15))))),
                            const SizedBox(height: 28),
                          ])),
                ])),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('함께한 리스트  ${lists.length}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)))),
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: lists.isEmpty ? 90 : 200,
                        child: lists.isEmpty
                            ? const Center(
                                child: Text('함께하는 리스트가 아직 없어요.',
                                    style: TextStyle(color: socialMuted)))
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                scrollDirection: Axis.horizontal,
                                itemCount: lists.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (_, i) {
                                  final l = lists[i];
                                  final bookmarks =
                                      l['list_bookmarks'] as List? ?? [];
                                  return SizedBox(
                                      width: 155,
                                      child: ReferenceCard(
                                          padding: const EdgeInsets.all(8),
                                          child: InkWell(
                                              onTap: () => _open(l),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ReferencePhoto(
                                                        title: bookmarks.isEmpty
                                                            ? ''
                                                            : bookmarks.first[
                                                                    'title'] ??
                                                                '',
                                                        width: 139,
                                                        height: 95),
                                                    const SizedBox(height: 8),
                                                    Text(l['name'] ?? '',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 13)),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                        '저장한 장소 ${bookmarks.length}개',
                                                        style: const TextStyle(
                                                            color: socialMuted,
                                                            fontSize: 11))
                                                  ]))));
                                }))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                        child: Text('함께 저장한 장소  ${places.length}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)))),
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: 120,
                        child: places.isEmpty
                            ? const Center(
                                child: Text('리스트에 장소를 추가해보세요.',
                                    style: TextStyle(color: socialMuted)))
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                itemCount: places.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (_, i) => InkWell(
                                    onTap: () => _open(places[i]['list']),
                                    child: SizedBox(
                                        width: 98,
                                        child: Column(children: [
                                          ReferencePhoto(
                                              title: places[i]['title'] ?? '',
                                              width: 98,
                                              height: 88),
                                          const SizedBox(height: 6),
                                          Text(places[i]['title'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 11))
                                        ])))))),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator())),
                if (snapshot.hasError)
                  SliverToBoxAdapter(
                      child: TextButton(
                          onPressed: () => setState(() => data = _load()),
                          child: const Text('공유 정보를 불러오지 못했어요. 다시 시도'))),
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.paddingOf(context).bottom + 24)),
              ]);
            }));
  }

  Widget _stat(String value, String label) => Expanded(
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              border: Border.all(color: socialLine),
              borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(color: socialMuted, fontSize: 12))
          ])));
}
