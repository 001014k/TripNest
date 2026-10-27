import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../navigation/app_page_route.dart';
import '../../viewmodels/friends/friend_management_viewmodel.dart';
import '../../widgets/common/reference_design.dart';
import '../../widgets/common/social_design.dart';
import '../friends/friend_profile_view.dart';
import '../lists/marker_info_view.dart';
import '../markers/markerdetail_view.dart';

class NotificationDetailView extends StatefulWidget {
  const NotificationDetailView({super.key, required this.item});
  final Map<String, dynamic> item;
  @override
  State<NotificationDetailView> createState() => _NotificationDetailViewState();
}

class _NotificationDetailViewState extends State<NotificationDetailView> {
  final db = Supabase.instance.client;
  Map<String, dynamic>? actor, place, list, request, cover;
  bool loading = true, busy = false;
  String? error;
  Map<String, dynamic> get data => widget.item['data'] is Map
      ? Map<String, dynamic>.from(widget.item['data'])
      : {};
  String? id(String key) => (widget.item[key] ?? data[key])?.toString();
  String get type => widget.item['type']?.toString() ?? '';
  bool get friend => type.startsWith('friend');
  bool get newPlace => type == 'list_marker_added';
  String get name =>
      actor?['nickname']?.toString() ??
      data['actor_nickname']?.toString() ??
      '여행 친구';
  String get listName =>
      list?['name']?.toString() ?? data['list_name']?.toString() ?? '여행 리스트';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    Future<void> attempt(Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {
        error = '일부 정보를 불러오지 못했어요. 다시 시도해주세요.';
      }
    }

    await Future.wait([
      attempt(() async {
        if (id('actor_id') != null) {
          actor = await db
              .from('profiles')
              .select()
              .eq('id', id('actor_id')!)
              .maybeSingle();
        }
      }),
      attempt(() async {
        if (id('marker_id') != null) {
          place = await db
              .from('user_markers')
              .select()
              .eq('id', id('marker_id')!)
              .maybeSingle();
        }
      }),
      attempt(() async {
        if (id('list_id') == null) return;
        list = await db
            .from('lists')
            .select()
            .eq('id', id('list_id')!)
            .maybeSingle();
        final rows = await db
            .from('list_bookmarks')
            .select()
            .eq('list_id', id('list_id')!)
            .order('created_at')
            .limit(1);
        if (rows.isNotEmpty) cover = rows.first;
      }),
      attempt(() async {
        if (!friend ||
            data['request_id'] == null ||
            db.auth.currentUser == null) {
          return;
        }
        request = await db
            .from('friend_requests')
            .select()
            .eq('id', data['request_id'])
            .eq('requested_id', db.auth.currentUser!.id)
            .maybeSingle();
      }),
    ]);
    if (mounted) setState(() => loading = false);
  }

  void _push(Widget page) =>
      Navigator.push(context, AppPageRoute(builder: (_) => page));
  void _openList() =>
      _push(MarkerInfoPage(listId: id('list_id')!, listName: listName));
  void _openPlace() {
    final lat = place?['lat'], lng = place?['lng'];
    if (lat is! num || lng is! num) return;
    _push(MarkerDetailView(
        marker: Marker(
            markerId: MarkerId(id('marker_id')!),
            position: LatLng(lat.toDouble(), lng.toDouble()),
            infoWindow: InfoWindow(title: place?['title']?.toString())),
        keyword: place?['keyword']?.toString() ?? '기타'));
  }

  Future<void> _respond(bool accept) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final current = await db
          .from('friend_requests')
          .select()
          .eq('id', data['request_id'])
          .eq('requested_id', db.auth.currentUser!.id)
          .maybeSingle();
      if (!mounted) return;
      if (current == null ||
          current['status'] != 'pending' ||
          current['requester_id'] != id('actor_id')) {
        await _load();
        return;
      }
      final vm = context.read<FriendManagementViewModel>();
      final message = accept
          ? await vm.acceptFriendRequest(current['requester_id'])
          : await vm.declineFriendRequest(current['requester_id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message.startsWith('오류')
              ? '요청을 처리하지 못했어요. 다시 시도해주세요.'
              : message)));
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('요청을 처리하지 못했어요. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _text(String text,
          {double size = 15, bool bold = false, bool muted = false}) =>
      Text(text,
          style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: muted ? const Color(0xff77777d) : const Color(0xff202023),
              height: 1.5));
  Widget _card(Widget child, {bool pale = false}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: pale ? const Color(0xfff1f1f3) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffeeeeF1))),
      child: child);
  Widget _pill(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: friend ? const Color(0xffe6f0f8) : const Color(0xffeeeef0),
          borderRadius: BorderRadius.circular(30)),
      child: _text(text, size: 13));
  Widget _photo(Map<String, dynamic> value, double height) => ReferencePhoto(
      title: value['title']?.toString() ?? '',
      address: value['address']?.toString() ?? '',
      width: double.infinity,
      height: height);
  Widget _button(String label, VoidCallback? action,
          {bool outlined = false, IconData? icon}) =>
      SizedBox(
          height: 54,
          child: FilledButton(
              onPressed: action,
              style: FilledButton.styleFrom(
                  backgroundColor:
                      outlined ? Colors.white : const Color(0xff222222),
                  foregroundColor:
                      outlined ? const Color(0xff222222) : Colors.white,
                  disabledBackgroundColor: const Color(0xffe8e8eb),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: outlined
                          ? const BorderSide(color: Color(0xff88888e))
                          : BorderSide.none)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[
                  Icon(icon, size: 21),
                  const SizedBox(width: 10)
                ],
                Flexible(
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)))
              ])));

  List<Widget> _content() {
    if (friend) {
      return [
        _card(Column(children: [
          const SizedBox(height: 8),
          SocialAvatar(name: name, url: actor?['avatar_url'], size: 130),
          const SizedBox(height: 14),
          _text(name, size: 21, bold: true),
          if (actor?['username'] != null)
            _text('@${actor!['username']}', muted: true),
          if (actor?['bio'] != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _text(actor!['bio'].toString(), muted: true)),
          const SizedBox(height: 16),
          OutlinedButton(
              onPressed: actor == null
                  ? null
                  : () => _push(FriendProfileView(friend: actor!)),
              child: const Text('프로필 보기')),
          const SizedBox(height: 4)
        ])),
        const SizedBox(height: 16),
        _card(
            Row(children: [
              const Icon(Icons.people_outline, size: 28),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _text('함께 여행을 계획해보세요', bold: true),
                    _text('친구와 장소를 공유하고 리스트를 함께 편집할 수 있어요.',
                        size: 13, muted: true)
                  ]))
            ]),
            pale: true),
      ];
    }
    if (newPlace) {
      return [
        Row(children: [
          SocialAvatar(name: name, url: actor?['avatar_url']),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _text(name, bold: true),
                _text('함께 여행하는 친구', size: 13, muted: true)
              ]))
        ]),
        const SizedBox(height: 16),
        if (place != null) ...[
          _photo(place!, 230),
          const SizedBox(height: 12),
          _text(place!['title']?.toString() ?? '장소', size: 21, bold: true),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on, size: 18, color: Color(0xff77777d)),
            const SizedBox(width: 5),
            Expanded(
                child: _text(place!['address']?.toString() ?? '주소 정보가 없어요',
                    size: 14, muted: true))
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 6, children: [
            if ((place!['keyword']?.toString() ?? '').isNotEmpty)
              _pill(place!['keyword'].toString())
          ])
        ] else
          _card(_text('장소가 삭제되었거나 접근할 수 없어요.', muted: true)),
        const SizedBox(height: 18),
        if (list != null)
          InkWell(
              onTap: _openList,
              child: _card(
                  Row(children: [
                    const Icon(Icons.list_alt_outlined),
                    const SizedBox(width: 12),
                    Expanded(child: _text(listName)),
                    const Icon(Icons.chevron_right)
                  ]),
                  pale: true)),
      ];
    }
    if (type == 'list_update') {
      return [
        if (list != null)
          InkWell(
              onTap: _openList,
              child: _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cover != null) ...[
                      _photo(cover!, 180),
                      const SizedBox(height: 12)
                    ],
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _text(listName, size: 18, bold: true),
                            _text('함께 계획하는 여행', size: 14, muted: true)
                          ])),
                      const Icon(Icons.chevron_right, color: Colors.grey)
                    ])
                  ])))
        else
          _card(_text('리스트가 삭제되었거나 접근할 수 없어요.', muted: true)),
        const SizedBox(height: 26),
        _text('변경 내용', size: 18, bold: true),
        const SizedBox(height: 12),
        _card(Row(children: [
          Icon(
              data['change'] == 'members'
                  ? Icons.people_outline
                  : Icons.format_list_bulleted,
              size: 28),
          const SizedBox(width: 14),
          Expanded(
              child: _text(widget.item['body']?.toString() ?? '리스트가 변경되었어요.'))
        ])),
        const SizedBox(height: 12),
        _card(
            Row(children: [
              const Icon(Icons.info_outline, color: Colors.grey, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      _text('최신 내용은 리스트에서 확인할 수 있어요.', size: 13, muted: true))
            ]),
            pale: true),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(widget.item['created_at']?.toString() ?? '')
        ?.toLocal();
    final pending = request?['status'] == 'pending' &&
        request?['requester_id'] == id('actor_id');
    return Scaffold(
        backgroundColor: const Color(0xfffafafa),
        appBar: AppBar(
            backgroundColor: const Color(0xfffafafa),
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            leading: IconButton(
                tooltip: '뒤로가기',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, size: 21)),
            title: const Row(mainAxisSize: MainAxisSize.min, children: [
              ReferenceLogo(),
              SizedBox(width: 6),
              Text('TripNest',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))
            ]),
            actions: [
              PopupMenuButton<String>(
                  tooltip: '더 보기',
                  onSelected: (_) =>
                      Navigator.pushNamed(context, '/notification_settings'),
                  itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'settings', child: Text('알림 설정'))
                      ])
            ]),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      _text('알림 상세', size: 23, bold: true),
                      const SizedBox(height: 24),
                      Wrap(
                          spacing: 14,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _pill(friend
                                ? '친구 요청'
                                : newPlace
                                    ? '새 장소'
                                    : type == 'list_update'
                                        ? '리스트 업데이트'
                                        : '알림'),
                            if (date != null)
                              _text(
                                  DateFormat('M월 d일 a h:mm', 'ko').format(date),
                                  size: 13,
                                  muted: true)
                          ]),
                      const SizedBox(height: 16),
                      _text(widget.item['title']?.toString() ?? '알림',
                          size: 23, bold: true),
                      const SizedBox(height: 10),
                      _text(widget.item['body']?.toString() ?? '', muted: true),
                      const SizedBox(height: 22),
                      if (error != null) ...[
                        TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: Text(error!)),
                        const SizedBox(height: 12)
                      ],
                      ..._content(),
                    ])),
        bottomNavigationBar: loading
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: friend
                        ? (pending
                            ? Row(children: [
                                Expanded(
                                    child: _button('거절',
                                        busy ? null : () => _respond(false),
                                        outlined: true)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _button(busy ? '처리 중…' : '수락하기',
                                        busy ? null : () => _respond(true)))
                              ])
                            : _button(
                                request?['status'] == 'accepted'
                                    ? '수락한 요청이에요'
                                    : request?['status'] == 'declined'
                                        ? '거절한 요청이에요'
                                        : '현재 처리할 수 없는 요청이에요',
                                null))
                        : newPlace
                            ? _button(
                                '장소 자세히 보기',
                                place?['lat'] is num && place?['lng'] is num
                                    ? _openPlace
                                    : null,
                                icon: Icons.location_on)
                            : type == 'list_update'
                                ? _button(
                                    '리스트 확인하기', list != null ? _openList : null,
                                    icon: Icons.format_list_bulleted)
                                : const SizedBox.shrink())));
  }
}
