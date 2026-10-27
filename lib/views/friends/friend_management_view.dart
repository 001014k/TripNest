import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../navigation/app_page_route.dart';
import '../../viewmodels/friends/friend_management_viewmodel.dart';
import '../../widgets/common/app_overlays.dart';
import '../../widgets/common/social_design.dart';
import 'friend_profile_view.dart';

class FriendManagementView extends StatefulWidget {
  const FriendManagementView({super.key});
  @override
  State<FriendManagementView> createState() => _FriendManagementViewState();
}

class _FriendManagementViewState extends State<FriendManagementView> {
  late FriendManagementViewModel vm;
  List<Map<String, dynamic>> friends = [], requests = [];
  Set<String> favorites = {};
  bool loading = true, alphabetical = false;
  String query = '';
  String? error;
  int tab = 0;
  int revision = 0;
  @override
  void initState() {
    super.initState();
    vm = context.read<FriendManagementViewModel>();
    _load();
  }

  Future<void> _load() async {
    final current = ++revision;
    try {
      final result = await Future.wait(
          [vm.getFriendsList(), vm.getReceivedFriendRequests()]);
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || current != revision) return;
      setState(() {
        friends = result[0];
        requests = result[1];
        favorites =
            (prefs.getStringList('favorite_friends_${vm.currentUserId}') ?? [])
                .toSet();
        loading = false;
        error = null;
      });
    } catch (_) {
      if (mounted && current == revision) {
        setState(() {
          loading = false;
          error = '친구 목록을 불러오지 못했어요.';
        });
      }
    }
  }

  Future<void> _favorite(String id) async {
    final next = {...favorites};
    if (!next.add(id)) next.remove(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'favorite_friends_${vm.currentUserId}', next.toList());
    if (mounted) setState(() => favorites = next);
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _add() async {
    await Navigator.push(
        context, AppPageRoute(builder: (_) => const FriendAddView()));
    if (mounted) await _load();
  }

  Future<void> _profile(Map<String, dynamic> friend) async {
    await Navigator.push(context,
        AppPageRoute(builder: (_) => FriendProfileView(friend: friend)));
    if (mounted) await _load();
  }

  Future<void> _remove(Map<String, dynamic> friend) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (_) => AppConfirmDialog(
            title: '친구를 삭제할까요?',
            message: '${friend['nickname']} 님과의 친구 및 내 리스트 협업 관계가 해제됩니다.',
            confirmLabel: '삭제',
            destructive: true,
            icon: Icons.person_remove_outlined));
    if (yes != true || !mounted) return;
    _message(await vm.removeFriend(friend['id']));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FriendManagementViewModel>();
    final visible = friends
        .where((f) => (f['nickname'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    if (alphabetical) {
      visible.sort((a, b) =>
          a['nickname'].toString().compareTo(b['nickname'].toString()));
    }
    final starred = friends.where((f) => favorites.contains(f['id'])).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: socialAppBar('친구 관리', actions: [
        IconButton(
            tooltip: '친구 추가',
            onPressed: _add,
            icon: const Icon(Icons.person_add_alt_outlined)),
        const SizedBox(width: 8)
      ]),
      body: SafeArea(
          top: false,
          child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  children: [
                    SocialTabs(
                        labels: [
                          '친구 목록',
                          '받은 요청${requests.isEmpty ? '' : '  ${requests.length}'}'
                        ],
                        selected: tab,
                        onChanged: (v) => setState(() => tab = v)),
                    const SizedBox(height: 18),
                    if (tab == 0) ...[
                      SocialSearch(
                          hint: '친구 이름을 검색하세요',
                          onChanged: (v) => setState(() => query = v)),
                      const SizedBox(height: 16),
                      SocialNotice(
                          title: '함께하는 여행이 더 특별해요',
                          subtitle: '친구와 리스트를 공유하고\n여행을 함께 계획해보세요.',
                          onTap: () => Navigator.pushNamed(context, '/list')),
                      const SizedBox(height: 22),
                      Row(children: [
                        Text('즐겨찾는 친구  ${starred.length}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const Spacer(),
                        const Tooltip(
                            message: '친구의 더보기 메뉴에서 즐겨찾기를 설정할 수 있어요.',
                            child: Icon(Icons.info_outline,
                                size: 17, color: socialMuted))
                      ]),
                      const SizedBox(height: 16),
                      if (starred.isEmpty)
                        const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Text('자주 함께하는 친구를 즐겨찾기에 추가해보세요.',
                                style: TextStyle(
                                    color: socialMuted, fontSize: 12)))
                      else
                        SizedBox(
                            height: 95,
                            child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: starred.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 20),
                                itemBuilder: (_, i) {
                                  final f = starred[i];
                                  return InkWell(
                                      onTap: () => _profile(f),
                                      child: SizedBox(
                                          width: 64,
                                          child: Column(children: [
                                            SocialAvatar(
                                                name: f['nickname'] ?? '',
                                                size: 62,
                                                url: f['avatar_url'],
                                                online: vm.onlineUserIds
                                                    .contains(f['id'])),
                                            const SizedBox(height: 8),
                                            Text(f['nickname'] ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 12))
                                          ])));
                                })),
                      const SizedBox(height: 14),
                      Row(children: [
                        Text('전체 친구  ${friends.length}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const Spacer(),
                        PopupMenuButton<bool>(
                            initialValue: alphabetical,
                            onSelected: (v) => setState(() => alphabetical = v),
                            itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: false, child: Text('기본순')),
                                  PopupMenuItem(value: true, child: Text('이름순'))
                                ],
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Row(children: [
                                  Text(alphabetical ? '이름순' : '기본순',
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.keyboard_arrow_down,
                                      size: 18)
                                ])))
                      ]),
                      if (!loading && error == null && visible.isEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                                query.isEmpty
                                    ? '아직 친구가 없어요. 오른쪽 위에서 친구를 추가해보세요.'
                                    : '검색 결과가 없어요.',
                                style: const TextStyle(color: socialMuted))),
                      ...visible.map((f) => Column(children: [
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                onTap: () => _profile(f),
                                leading: SocialAvatar(
                                    name: f['nickname'] ?? '',
                                    url: f['avatar_url'],
                                    online: vm.onlineUserIds.contains(f['id'])),
                                title: Text(f['nickname'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    vm.onlineUserIds.contains(f['id'])
                                        ? '온라인'
                                        : '함께 여행하는 친구',
                                    style: const TextStyle(
                                        fontSize: 12, color: socialMuted)),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (favorites.contains(f['id']))
                                        const Icon(Icons.star_rounded,
                                            color: Color(0xFFF5B342), size: 20),
                                      PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_horiz),
                                          onSelected: (v) => v == 'favorite'
                                              ? _favorite(f['id'])
                                              : _remove(f),
                                          itemBuilder: (_) => [
                                                PopupMenuItem(
                                                    value: 'favorite',
                                                    child: Text(favorites
                                                            .contains(f['id'])
                                                        ? '즐겨찾기 해제'
                                                        : '즐겨찾기 추가')),
                                                const PopupMenuItem(
                                                    value: 'remove',
                                                    child: Text('친구 삭제'))
                                              ]),
                                    ])),
                            const Divider(height: 1, color: socialLine)
                          ])),
                    ] else ...[
                      if (!loading && requests.isEmpty)
                        const SocialNotice(
                            title: '받은 친구 요청이 없어요',
                            subtitle: '새로운 요청이 오면 이곳에서 확인할 수 있어요.',
                            icon: Icons.mail_outline),
                      ...requests.map((r) {
                        final p = r['requester'] as Map? ?? {};
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(children: [
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading:
                                      SocialAvatar(name: p['nickname'] ?? ''),
                                  title: Text(p['nickname'] ?? '친구'),
                                  subtitle: const Text('함께 여행하고 싶어요',
                                      style: TextStyle(
                                          fontSize: 12, color: socialMuted))),
                              Row(children: [
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed: () => _request(r, false),
                                        child: const Text('거절'))),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: FilledButton(
                                        onPressed: () => _request(r, true),
                                        child: const Text('수락')))
                              ])
                            ]));
                      }),
                    ],
                    if (loading)
                      const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(child: CircularProgressIndicator())),
                    if (error != null)
                      TextButton(onPressed: _load, child: Text('$error 다시 시도')),
                  ]))),
    );
  }

  final Set<String> pending = {};
  Future<void> _request(Map<String, dynamic> r, bool accept) async {
    final id = r['requester_id'] as String;
    if (!pending.add(id)) return;
    try {
      _message(await (accept
          ? vm.acceptFriendRequest(id)
          : vm.declineFriendRequest(id)));
      if (mounted) await _load();
    } finally {
      pending.remove(id);
    }
  }
}

class FriendAddView extends StatefulWidget {
  const FriendAddView({super.key});
  @override
  State<FriendAddView> createState() => _FriendAddViewState();
}

class _FriendAddViewState extends State<FriendAddView> {
  final input = TextEditingController();
  bool sending = false;
  String? result;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (sending || input.text.trim().isEmpty) return;
    setState(() {
      sending = true;
      result = null;
    });
    final message = await context
        .read<FriendManagementViewModel>()
        .sendFriendRequest(input.text.trim());
    if (mounted) {
      setState(() {
        result = message;
        sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.white,
      appBar: socialAppBar('친구 추가하기'),
      body: SafeArea(
          top: false,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const SocialTabs(
                labels: ['닉네임으로 추가'], selected: 0, onChanged: _ignore),
            const SizedBox(height: 18),
            SocialSearch(
                controller: input,
                hint: '친구의 정확한 닉네임을 입력하세요',
                onChanged: (_) => setState(() => result = null),
                onSubmitted: (_) => _send()),
            const SizedBox(height: 18),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
                decoration: BoxDecoration(
                    color: socialFill, borderRadius: BorderRadius.circular(18)),
                child: Column(children: [
                  const CircleAvatar(
                      radius: 29,
                      backgroundColor: Color(0xFFE5E5E9),
                      child: Icon(Icons.person_add_alt_outlined,
                          size: 29, color: Colors.black)),
                  const SizedBox(height: 18),
                  const Text('친구와 여행을 시작해보세요',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  const Text('닉네임으로 친구 요청을 보내고\n함께 여행 리스트를 공유할 수 있어요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: socialMuted, height: 1.7, fontSize: 13)),
                ])),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: sending || input.text.trim().isEmpty ? null : _send,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFF202020),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: Text(sending ? '요청 보내는 중…' : '친구 요청 보내기')),
            if (result != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(result!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13))),
          ])));
  static void _ignore(int _) {}
}
