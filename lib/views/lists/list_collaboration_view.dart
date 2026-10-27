import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/lists/collaborator_viewmodel.dart';
import '../../viewmodels/lists/list_viewmodel.dart';
import '../../widgets/common/app_overlays.dart';
import '../../widgets/common/reference_design.dart';
import '../../widgets/common/social_design.dart';

class ListCollaborationView extends StatefulWidget {
  const ListCollaborationView({super.key, required this.listId});
  final String listId;
  @override
  State<ListCollaborationView> createState() => _ListCollaborationViewState();
}

class _ListCollaborationViewState extends State<ListCollaborationView> {
  late CollaboratorViewModel vm;
  bool loading = true, busy = false;
  int tab = 0;
  @override
  void initState() {
    super.initState();
    vm = context.read<CollaboratorViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    await vm.loadListOwner(widget.listId);
    await vm.getCollaborators(widget.listId);
    await vm.getFriends(widget.listId);
    if (mounted) setState(() => loading = false);
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _invite(Map<String, String> friend) async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AppConfirmDialog(
            title: '${friend['nickname']}님을 초대할까요?',
            message: '읽기 전용 게스트로 초대합니다. 초대 후 역할을 변경할 수 있습니다.',
            confirmLabel: '초대',
            icon: Icons.person_add_outlined));
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    final ok = await vm.addCollaborator(widget.listId, friend['nickname']!);
    if (!mounted) return;
    setState(() => busy = false);
    _message(ok ? '친구를 리스트에 초대했습니다.' : vm.errorMessage ?? '초대하지 못했어요.');
  }

  Future<void> _changeRole(String userId, String role) async {
    if (busy || !vm.isCurrentUserOwner) return;
    setState(() => busy = true);
    final ok = await vm.changeRole(widget.listId, userId, role);
    if (!mounted) return;
    setState(() => busy = false);
    _message(ok ? '역할을 변경했습니다.' : '역할을 변경하지 못했습니다.');
  }

  Future<void> _remove(String id, String name) async {
    if (busy) return;
    final yes = await showDialog<bool>(
        context: context,
        builder: (_) => AppConfirmDialog(
            title: '$name님을 내보낼까요?',
            message: '이 리스트의 협업 권한이 해제됩니다.',
            confirmLabel: '내보내기',
            destructive: true,
            icon: Icons.person_remove_outlined));
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    final ok = await vm.removeCollaborator(widget.listId, id);
    if (!mounted) return;
    setState(() => busy = false);
    _message(ok ? '협업자를 내보냈습니다.' : '변경하지 못했어요. 다시 시도해주세요.');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CollaboratorViewModel>();
    final lists = context
        .watch<ListViewModel>()
        .lists
        .where((l) => l.id == widget.listId);
    final list = lists.isEmpty ? null : lists.first;
    final members =
        vm.collaborators.where((m) => m.userId != vm.listOwnerId).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: socialAppBar('리스트 협업 관리'),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: FilledButton.icon(
                onPressed: loading || busy || !vm.isCurrentUserOwner
                    ? null
                    : () => setState(() => tab = 1),
                icon: const Icon(Icons.person_add_alt_outlined, size: 20),
                label: const Text('친구 초대하기'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF202020),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18))))),
      ),
      body: SafeArea(
          top: false,
          child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                Row(children: [
                  ReferencePhoto(
                      title: list?.coverTitle ?? '', width: 78, height: 78),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(list?.name ?? '여행 리스트',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 17)),
                        const SizedBox(height: 8),
                        Text(
                            '${list?.markerCount ?? 0}개의 장소 · ${members.length + (vm.listOwnerId == null ? 0 : 1)}명의 멤버',
                            style: const TextStyle(
                                color: socialMuted, fontSize: 12))
                      ]))
                ]),
                const SizedBox(height: 26),
                SocialTabs(labels: [
                  '멤버 ${members.length + (vm.listOwnerId == null ? 0 : 1)}',
                  '친구 초대'
                ], selected: tab, onChanged: (v) => setState(() => tab = v)),
                const SizedBox(height: 18),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else if (tab == 0) ...[
                  SocialNotice(
                      title: '친구를 초대해보세요',
                      subtitle: '여행 리스트를 함께 만들 수 있어요.',
                      icon: Icons.person_add_alt_outlined,
                      onTap: () => setState(() => tab = 1)),
                  const SizedBox(height: 14),
                  _member(vm.listOwnerNickname ?? '리스트 소유자', '리스트 소유자',
                      owner: true),
                  ...members.map((m) => _member(
                      m.nickname, m.role == 'editor' ? '장소 추가·삭제 가능' : '읽기 전용',
                      role: m.role == 'editor' ? '편집자' : '게스트',
                      changeRole: vm.isCurrentUserOwner
                          ? (role) => _changeRole(m.userId, role)
                          : null,
                      remove:
                          vm.isCurrentUserOwner && m.userId != vm.currentUserId
                              ? () => _remove(m.userId, m.nickname)
                              : null)),
                ] else ...[
                  const SocialNotice(
                      title: '함께 여행할 친구 선택',
                      subtitle: '이미 참여 중인 친구는 목록에 표시되지 않아요.',
                      icon: Icons.people_outline),
                  const SizedBox(height: 16),
                  if (vm.friends.isEmpty)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 25),
                        child: Text('초대할 수 있는 친구가 없어요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: socialMuted))),
                  ...vm.friends.map((f) => Column(children: [
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: SocialAvatar(name: f['nickname'] ?? ''),
                            title: Text(f['nickname'] ?? '',
                                style: const TextStyle(fontSize: 15)),
                            trailing: FilledButton(
                                onPressed: busy || !vm.isCurrentUserOwner
                                    ? null
                                    : () => _invite(f),
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF202020)),
                                child: const Text('초대'))),
                        const Divider(height: 1, color: socialLine)
                      ])),
                ],
                if (vm.hasError)
                  TextButton(
                      onPressed: _load,
                      child: const Text('정보를 불러오지 못했어요. 다시 시도')),
              ]))),
    );
  }

  Widget _member(String name, String subtitle,
          {bool owner = false,
          String? role,
          VoidCallback? remove,
          ValueChanged<String>? changeRole}) =>
      Column(children: [
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(children: [
              SocialAvatar(name: name),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('$name${owner ? '  ♛' : ''}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text(subtitle,
                        style:
                            const TextStyle(color: socialMuted, fontSize: 12))
                  ])),
              if (role != null)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        border: Border.all(color: socialLine),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(role, style: const TextStyle(fontSize: 12))),
              if (remove != null)
                PopupMenuButton<String>(
                    enabled: !busy,
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (value) {
                      if (value == 'remove') {
                        remove();
                      } else {
                        changeRole?.call(value);
                      }
                    },
                    itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'guest', child: Text('게스트 · 읽기 전용')),
                          PopupMenuItem(
                              value: 'editor', child: Text('편집자 · 장소 추가·삭제')),
                          PopupMenuItem(value: 'remove', child: Text('내보내기'))
                        ])
            ])),
        const Divider(height: 1, color: socialLine)
      ]);
}
