import '../../services/markers/marker_service.dart';
import '../../widgets/places/address_photo_preview.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/navigation/tripnest_navigation.dart';
import '../../navigation/app_page_route.dart';
import 'notification_detail_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key, this.client});
  final SupabaseClient? client;
  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final _client = widget.client ?? Supabase.instance.client;
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true, _marking = false;
  String? _error;
  int _filter = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _hasMore = true, _loadingMore = false;
  int _loadRevision = 0;
  Future<void> _load({bool more = false}) async {
    if (more && (_loading || _loadingMore || !_hasMore)) return;
    final revision = ++_loadRevision;
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
      }
    });
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw StateError('로그인 후 알림을 확인해주세요.');
      var query = _client.from('notifications').select().eq('user_id', user.id);
      if (_filter == 1) query = query.eq('type', 'list_marker_added');
      if (_filter == 2) query = query.eq('type', 'list_update');
      if (_filter == 3) query = query.like('type', 'friend%');
      if (more && _items.isNotEmpty) {
        final last = _items.last;
        query = query.or(
            'created_at.lt.${last['created_at']},and(created_at.eq.${last['created_at']},id.lt.${last['id']})');
      }
      final data = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(30);
      if (!mounted ||
          revision != _loadRevision ||
          _client.auth.currentUser?.id != user.id) {
        return;
      }
      if (mounted) {
        setState(() {
          if (!more) _items.clear();
          final ids = _items.map((n) => n['id']).toSet();
          _items.addAll(data.where((n) => ids.add(n['id'])));
          _hasMore = data.length == 30;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && revision == _loadRevision) {
        setState(() => _error = _client.auth.currentUser == null
            ? '로그인 후 알림을 확인해주세요.'
            : '알림을 불러오지 못했어요. 다시 시도해주세요.');
      }
    } finally {
      if (mounted && revision == _loadRevision) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _read(List<Map<String, dynamic>> items,
      {bool all = false}) async {
    final user = _client.auth.currentUser;
    if (user == null || (!all && items.isEmpty) || _marking) return;
    setState(() => _marking = true);
    final ids = items.map((n) => n['id'].toString()).toList();
    try {
      var query = _client
          .from('notifications')
          .update({'is_read': true}).eq('user_id', user.id);
      if (!all) query = query.inFilter('id', ids);
      await query;
      if (mounted) {
        setState(() {
          for (final n in _items) {
            if (all || ids.contains(n['id'])) n['is_read'] = true;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('읽음 상태를 저장하지 못했어요.')));
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  int _kind(Map<String, dynamic> n) => n['type'] == 'list_marker_added'
      ? 1
      : n['type'] == 'list_update'
          ? 2
          : n['type'].toString().startsWith('friend')
              ? 3
              : 0;
  IconData _icon(Map<String, dynamic> n) => [
        Icons.notifications_none,
        Icons.location_on_outlined,
        Icons.format_list_bulleted,
        Icons.person_add_alt
      ][_kind(n)];
  DateTime _date(Map<String, dynamic> n) =>
      DateTime.tryParse(n['created_at'].toString())?.toLocal() ??
      DateTime(2000);
  String _group(Map<String, dynamic> n) {
    final date = DateUtils.dateOnly(_date(n));
    final today = DateUtils.dateOnly(DateTime.now());
    return date == today
        ? '오늘'
        : date == today.subtract(const Duration(days: 1))
            ? '어제'
            : '이전 알림';
  }

  String _time(Map<String, dynamic> n) {
    final date = _date(n);
    final delta = DateTime.now().difference(date);
    if (delta.inSeconds >= 0 && delta.inMinutes < 1) return '방금 전';
    if (delta.inMinutes >= 0 && delta.inMinutes < 60) {
      return '${delta.inMinutes}분 전';
    }
    if (_group(n) == '오늘') return '${delta.inHours}시간 전';
    return DateFormat('M월 d일 HH:mm').format(date);
  }

  Future<void> _open(Map<String, dynamic> item) async {
    await _read([item]);
    if (!mounted) return;
    await Navigator.push(context,
        AppPageRoute(builder: (_) => NotificationDetailView(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _items.where((n) => _filter == 0 || _kind(n) == _filter).toList();
    return Scaffold(
        backgroundColor: const Color(0xfffafafa),
        appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xfffafafa),
            surfaceTintColor: Colors.transparent,
            title: TripNestHeader(
                onBack: () => Navigator.pop(context),
                trailing: IconButton(
                    tooltip: '알림 설정',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/notification_settings'),
                    icon: const Icon(Icons.settings_outlined)))),
        bottomNavigationBar: _hasMore && !_loading
            ? SafeArea(
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: OutlinedButton(
                        onPressed:
                            _loadingMore ? null : () => _load(more: true),
                        child: Text(_loadingMore ? '불러오는 중…' : '이전 알림 더 보기'))))
            : null,
        body: SafeArea(
            top: false,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Expanded(
                              child: Text('알림',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800))),
                          TextButton(
                              onPressed: _marking
                                  ? null
                                  : () => _read(_items, all: true),
                              child: Text(_marking ? '처리 중' : '모두 읽음',
                                  style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Color(0xff55555d))))
                        ]),
                        const SizedBox(height: 6),
                        const Text('함께하는 여행 소식을 확인해보세요.',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xff77777d))),
                        const SizedBox(height: 20),
                        Row(
                            children: List.generate(
                                4,
                                (i) => Expanded(
                                    child: Padding(
                                        padding: EdgeInsets.only(
                                            right: i == 3 ? 0 : 7),
                                        child: ChoiceChip(
                                            label: SizedBox(
                                                width: double.infinity,
                                                child: Text(
                                                    [
                                                      '전체',
                                                      '장소',
                                                      '리스트',
                                                      '친구'
                                                    ][i],
                                                    textAlign:
                                                        TextAlign.center)),
                                            selected: _filter == i,
                                            onSelected: (_) {
                                              setState(() {
                                                _filter = i;
                                                _items.clear();
                                                _hasMore = true;
                                              });
                                              _load();
                                            },
                                            showCheckmark: false,
                                            selectedColor:
                                                const Color(0xff222222),
                                            backgroundColor:
                                                const Color(0xfff0f0f2),
                                            side: BorderSide.none,
                                            shape: const StadiumBorder(),
                                            labelStyle: TextStyle(
                                                fontSize: 13,
                                                color: _filter == i
                                                    ? Colors.white
                                                    : const Color(
                                                        0xff77777d)))))))
                      ])),
              Expanded(
                  child: RefreshIndicator(
                      onRefresh: _load,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                  if (_error != null)
                                    Padding(
                                        padding: const EdgeInsets.all(30),
                                        child: Column(children: [
                                          Text(_error!,
                                              textAlign: TextAlign.center),
                                          TextButton(
                                              onPressed: _load,
                                              child: const Text('다시 시도'))
                                        ]))
                                  else if (visible.isEmpty)
                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 70),
                                        child: Column(children: [
                                          Icon(Icons.notifications_none,
                                              size: 42, color: Colors.grey),
                                          SizedBox(height: 14),
                                          Text('아직 받은 알림이 없어요.',
                                              style:
                                                  TextStyle(color: Colors.grey))
                                        ]))
                                  else
                                    for (final group in [
                                      '오늘',
                                      '어제',
                                      '이전 알림'
                                    ]) ...[
                                      if (visible
                                          .any((n) => _group(n) == group))
                                        Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                4, 12, 4, 12),
                                            child: Text(
                                                '$group  ${visible.where((n) => _group(n) == group).length}',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w700))),
                                      for (final item in visible
                                          .where((n) => _group(n) == group))
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Material(
                                                color: item['is_read'] == true
                                                    ? Colors.white
                                                    : const Color(0xfff5f5f7),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                    side: const BorderSide(
                                                        color:
                                                            Color(0xffe8e8eb))),
                                                clipBehavior: Clip.antiAlias,
                                                child: InkWell(
                                                    onTap: () => _open(item),
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(13),
                                                        child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                  width: 40,
                                                                  height: 44,
                                                                  decoration: BoxDecoration(
                                                                      color: const Color(
                                                                          0xffededf0),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12)),
                                                                  child: Icon(
                                                                      _icon(
                                                                          item),
                                                                      size:
                                                                          24)),
                                                              const SizedBox(
                                                                  width: 11),
                                                              Expanded(
                                                                  child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                    Row(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          if (item['is_read'] !=
                                                                              true)
                                                                            const Padding(
                                                                                padding: EdgeInsets.only(top: 6, right: 6),
                                                                                child: Icon(Icons.circle, size: 6)),
                                                                          Expanded(
                                                                              child: Text(item['title']?.toString() ?? '알림', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis))
                                                                        ]),
                                                                    const SizedBox(
                                                                        height:
                                                                            5),
                                                                    Text(
                                                                        item['body']?.toString() ??
                                                                            '',
                                                                        maxLines:
                                                                            2,
                                                                        overflow:
                                                                            TextOverflow
                                                                                .ellipsis,
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            height:
                                                                                1.5,
                                                                            color:
                                                                                Color(0xff77777d))),
                                                                    const SizedBox(
                                                                        height:
                                                                            8),
                                                                    Text(
                                                                        '${[
                                                                          '알림',
                                                                          '새 장소',
                                                                          '리스트 업데이트',
                                                                          '친구'
                                                                        ][_kind(item)]} · ${_time(item)}',
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                11,
                                                                            color:
                                                                                Color(0xff929298)))
                                                                  ])),
                                                              const SizedBox(
                                                                  width: 5),
                                                              _NotificationThumbnail(
                                                                  key: ValueKey(
                                                                      item[
                                                                          'id']),
                                                                  item: item),
                                                              const Icon(
                                                                  Icons
                                                                      .chevron_right,
                                                                  size: 20,
                                                                  color: Color(
                                                                      0xff9999a0))
                                                            ])))))
                                    ],
                                ]))),
            ])));
  }
}

class _NotificationThumbnail extends StatefulWidget {
  const _NotificationThumbnail({super.key, required this.item});
  final Map<String, dynamic> item;
  @override
  State<_NotificationThumbnail> createState() => _NotificationThumbnailState();
}

class _NotificationThumbnailState extends State<_NotificationThumbnail> {
  late final Future<Map<String, dynamic>?> _place;
  @override
  void initState() {
    super.initState();
    final data = widget.item['data'];
    final id =
        widget.item['marker_id'] ?? (data is Map ? data['marker_id'] : null);
    _place = id == null
        ? Future.value(null)
        : MarkerService()
            .loadMarkerDetail(id.toString())
            .then<Map<String, dynamic>?>((value) =>
                value == null ? null : Map<String, dynamic>.from(value))
            .catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
      future: _place,
      builder: (context, snapshot) {
        final place = snapshot.data;
        if (place == null) return const SizedBox.shrink();
        return Padding(
            padding: const EdgeInsets.only(left: 8, right: 5),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                    width: 44,
                    height: 48,
                    child: AddressPhotoPreview(
                        address: place['address']?.toString() ?? '',
                        title: place['title']?.toString(),
                        size: 48))));
      });
}
