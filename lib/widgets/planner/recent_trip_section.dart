import 'dart:async';
import '../common/reference_design.dart' show ReferenceCalendar;
import '../common/app_overlays.dart';
import '../places/address_photo_preview.dart';
import 'package:flutter/material.dart';
import '../../models/planner/trip_history_controller.dart';
export '../../models/planner/trip_history_controller.dart';

import '../../design/app_design.dart';
import '../navigation/tripnest_navigation.dart' show TripNestHeader;

class RecentTripSection extends StatefulWidget {
  const RecentTripSection(
      {super.key,
      required this.latest,
      required this.history,
      required this.loadRecord,
      required this.onSelect,
      this.onNew});
  final VoidCallback? onNew;
  final TripRecord latest;
  final TripHistoryController history;
  final Future<TripRecord> Function(Object id) loadRecord;
  final ValueChanged<TripRecord> onSelect;
  @override
  State<RecentTripSection> createState() => _RecentTripSectionState();
}

class _RecentTripSectionState extends State<RecentTripSection> {
  bool _opening = false;
  Future<void> _openLatest() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final record = await widget.loadRecord(widget.latest['id']);
      if (mounted) widget.onSelect(record);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('기록을 열지 못했어요. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(
                child: Text('최근 여행 계획', style: AppDesign.headingSmall)),
            TextButton(
                onPressed: _opening
                    ? null
                    : () async {
                        final record =
                            await Navigator.of(context, rootNavigator: true)
                                .push<TripRecord>(MaterialPageRoute(
                                    builder: (_) => _TripHistoryScreen(
                                        history: widget.history,
                                        loadRecord: widget.loadRecord,
                                        onNew: widget.onNew)));
                        if (mounted && record != null) widget.onSelect(record);
                      },
                child: const Text('전체 보기')),
          ]),
          if (_opening) const LinearProgressIndicator(),
          _TripRecordCard(record: widget.latest, onTap: _openLatest),
        ],
      );
}

class _TripRecordCard extends StatelessWidget {
  const _TripRecordCard({required this.record, required this.onTap});

  final TripRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = record['title']?.toString().trim();
    final date =
        DateTime.tryParse(record['created_at']?.toString() ?? '')?.toLocal();
    return Card(
      color: AppDesign.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        side: const BorderSide(color: AppDesign.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title == null || title.isEmpty ? '여행 계획' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppDesign.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppDesign.spacing8),
              Row(children: [
                Expanded(
                  child: Text(
                    date == null
                        ? '저장된 추천'
                        : '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} 저장',
                    style: AppDesign.caption,
                  ),
                ),
                const Text('이어보기', style: AppDesign.bodyMedium),
                const SizedBox(width: AppDesign.spacing4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 18, color: AppDesign.primary),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripHistoryScreen extends StatefulWidget {
  const _TripHistoryScreen(
      {required this.history, required this.loadRecord, this.onNew});
  final VoidCallback? onNew;
  final TripHistoryController history;
  final Future<TripRecord> Function(Object id) loadRecord;
  @override
  State<_TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<_TripHistoryScreen> {
  TripHistoryController get history => widget.history;
  List<TripRecord> get _records => history.records;
  bool get _loading => history.loading;
  bool get _failed => history.failed;
  bool get _hasMore => history.hasMore;
  late final ScrollController _scroll;
  late final TextEditingController _search;
  Timer? _debounce;
  bool _opening = false;
  final _deleting = <Object>{};
  bool _oldest = false;
  String _category = '전체';
  List<TripRecord> get _visible {
    final rows = _records
        .where((r) =>
            _category == '전체' || _TripHistoryEntry(r).category == _category)
        .toList();
    rows.sort((a, b) {
      final comparison = (b['created_at']?.toString() ?? '')
          .compareTo(a['created_at']?.toString() ?? '');
      return comparison;
    });
    if (_oldest && rows.length > 1) {
      return [rows.first, ...rows.skip(1).toList().reversed];
    }
    return rows;
  }

  Future<void> _completePages() async {
    while (mounted && history.hasMore && !history.loading) {
      await history.loadMore();
      if (history.failed) break;
    }
  }

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(initialScrollOffset: history.scrollOffset);
    _search = TextEditingController(text: history.search);
    history.addListener(_changed);
    _scroll.addListener(_rememberScroll);
    if (!history.initialized) history.loadMore();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _rememberScroll() {
    history.scrollOffset = _scroll.offset;
  }

  Future<void> _loadMore() => history.loadMore();

  Future<void> _filter({DateTime? since}) async {
    _debounce?.cancel();
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await history.refresh(search: _search.text.trim(), since: since);
    if (_category != '전체' || _oldest) await _completePages();
  }

  Future<void> _select(TripRecord record) async {
    if (_opening || _deleting.contains(record['id'])) return;
    setState(() => _opening = true);
    try {
      final detail = await widget.loadRecord(record['id']);
      if (mounted) Navigator.of(context).pop(detail);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('기록을 열지 못했어요. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _delete(TripRecord record) async {
    final id = record['id'];
    if (_opening || _deleting.contains(id)) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('여행 계획 기록을 삭제할까요?'),
                content: const Text('이 기록은 복구할 수 없어요. 지도에 저장한 장소는 유지됩니다.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('취소')),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppDesign.travelStamp),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('삭제')),
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _deleting.add(id));
    try {
      await history.remove(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    history.removeListener(_changed);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = _visible;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 14),
              child: TripNestHeader(
                onBack: () => Navigator.pop(context),
                trailing: const SizedBox.shrink(),
              ),
            ),
            Expanded(
                child: RefreshIndicator(
              onRefresh: () => _filter(since: history.since),
              child: ListView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _header(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    decoration: const BoxDecoration(
                        color: Color(0xFFF7F7FB),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(28))),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _filters(),
                          if (_search.text.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: TextField(
                                    controller: _search,
                                    decoration: const InputDecoration(
                                        hintText: '지역·제목·테마 검색',
                                        prefixIcon: Icon(Icons.search)),
                                    onChanged: (_) {
                                      _debounce?.cancel();
                                      _debounce = Timer(
                                          const Duration(milliseconds: 350),
                                          () => _filter(since: history.since));
                                    },
                                    onSubmitted: (_) =>
                                        _filter(since: history.since))),
                          if (_opening) const LinearProgressIndicator(),
                          const SizedBox(height: 14),
                          if (records.isNotEmpty)
                            _historyCard(records.first, featured: true),
                          if (records.length > 1) ...[
                            const SizedBox(height: 22),
                            Row(children: [
                              const Text('이전 기록',
                                  style: AppDesign.headingSmall),
                              const SizedBox(width: 6),
                              Text('${records.length - 1}',
                                  style: AppDesign.bodySmall),
                              const Spacer(),
                              PopupMenuButton<bool>(
                                  tooltip: '기록 정렬',
                                  onSelected: (value) async {
                                    setState(() => _oldest = value);
                                    if (value) await _completePages();
                                  },
                                  itemBuilder: (_) => const [
                                        PopupMenuItem(
                                            value: false, child: Text('최신순')),
                                        PopupMenuItem(
                                            value: true, child: Text('오래된순'))
                                      ],
                                  child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(children: [
                                        const Icon(Icons.swap_vert, size: 17),
                                        Text(_oldest ? '오래된순' : '최신순'),
                                        const Icon(Icons.expand_more, size: 17)
                                      ]))),
                            ]),
                            const SizedBox(height: 10),
                            for (final record in records.skip(1))
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _historyCard(record)),
                          ],
                          _buildFooter(),
                          if (records.isEmpty &&
                              _records.isNotEmpty &&
                              !_loading)
                            const Text('선택한 분류의 기록이 없어요.',
                                textAlign: TextAlign.center),
                        ]),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Flexible(
                    child: Text('나의 여행 추천', style: AppDesign.headingLarge)),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: '보관 정책',
                  onPressed: _showRetentionPolicy,
                  icon: const Icon(Icons.info_outline_rounded,
                      size: 20, color: AppDesign.label2),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('저장한 여행 계획을 다시 이어보세요.', style: AppDesign.bodyMedium),
            const SizedBox(height: 16),
            _retentionNotice(),
          ],
        ),
      );

  Widget _retentionNotice() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppDesign.secondaryBg,
          border: Border.all(color: AppDesign.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.history_rounded,
                  size: 20, color: AppDesign.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '최근 여행 계획 '),
                        TextSpan(
                            text: '11개 보관',
                            style: TextStyle(color: AppDesign.primary)),
                      ]),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppDesign.label1)),
                  const SizedBox(height: 5),
                  const Text('새 계획을 저장하면 가장 오래된 기록이 자동 삭제돼요.',
                      style: TextStyle(
                          fontSize: 12, height: 1.5, color: AppDesign.label2)),
                ],
              ),
            ),
          ],
        ),
      );

  void _showRetentionPolicy() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('여행 계획 보관 정책', style: AppDesign.headingSmall),
              const SizedBox(height: 20),
              for (final item in [
                (Icons.history_rounded, '최근 계획 1개와 이전 기록 10개를 보관해요.'),
                (Icons.auto_delete_outlined, '새 계획 저장이 완료되면 오래된 기록부터 자동 삭제돼요.'),
                (Icons.info_outline_rounded, '삭제된 AI 기록은 복구할 수 없어요.'),
                (Icons.map_outlined, '지도에 따로 저장한 장소는 그대로 유지돼요.'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$1, size: 20, color: AppDesign.primary),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(item.$2, style: AppDesign.bodyMedium)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickHistoryDate() {
    final today = DateUtils.dateOnly(DateTime.now());
    var selected = history.since ?? today;
    var month = DateTime(selected.year, selected.month);
    return showAppSheet<DateTime>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => AppSheet(
          title: '기록 조회 시작일',
          subtitle: '선택한 날짜 이후에 저장한 추천을 보여드려요.',
          footer: FilledButton(
            onPressed: () => Navigator.pop(sheetContext, selected),
            child: const Text('적용'),
          ),
          children: [
            ReferenceCalendar(
              month: month,
              selected: selected,
              firstDate: DateTime(2000),
              lastDate: today,
              eventDays: const {},
              onSelected: (date) => setSheetState(() {
                selected = date;
                month = DateTime(date.year, date.month);
              }),
              onMonthChanged: (date) => setSheetState(() => month = date),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        ActionChip(
            avatar: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(history.since == null
                ? '전체 기간 ⌄'
                : '${history.since!.month}/${history.since!.day} 이후'),
            onPressed: () async {
              final date = await _pickHistoryDate();
              if (date != null && mounted) await _filter(since: date);
            }),
        if (history.since != null)
          TextButton(onPressed: () => _filter(), child: const Text('기간 해제')),
        const SizedBox(width: 10),
        for (final item in [
          ('전체', Icons.grid_view),
          ('여행', Icons.flight_outlined),
          ('스테이', Icons.bed_outlined),
          ('맛집', Icons.restaurant_outlined),
          ('기타', Icons.chat_bubble_outline)
        ])
          Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                  showCheckmark: false,
                  selectedColor: AppDesign.primary,
                  avatar: Icon(item.$2,
                      size: 17,
                      color: _category == item.$1
                          ? Colors.white
                          : AppDesign.primary),
                  label: Text(item.$1,
                      style: TextStyle(
                          color: _category == item.$1
                              ? Colors.white
                              : AppDesign.primary)),
                  selected: _category == item.$1,
                  onSelected: (_) async {
                    setState(() => _category = item.$1);
                    if (_category != '전체') await _completePages();
                  })),
      ]));

  Widget _historyCard(TripRecord record, {bool featured = false}) {
    final entry = _TripHistoryEntry(record);
    final busy = _opening || _deleting.contains(record['id']);
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppDesign.borderColor),
          boxShadow: AppDesign.softShadow),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: busy ? null : () => _select(record),
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: IntrinsicHeight(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                              width: featured ? 104 : 62,
                              height: featured ? 140 : 68,
                              child: _HistoryPhoto(
                                  key: ValueKey(record['id']),
                                  record: record,
                                  scroll: _scroll,
                                  height: featured ? 140 : 68))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Row(children: [
                              if (featured)
                                const Expanded(
                                    child: Text('◷ 최근 여행 계획',
                                        style: AppDesign.caption))
                              else
                                Expanded(
                                    child: Text(entry.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppDesign.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600))),
                              SizedBox(
                                  width: 30,
                                  height: 28,
                                  child: PopupMenuButton<String>(
                                      tooltip: '기록 관리',
                                      enabled: !busy,
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.more_horiz,
                                          size: 20),
                                      onSelected: (_) => _delete(record),
                                      itemBuilder: (_) => const [
                                            PopupMenuItem(
                                                value: 'delete',
                                                child: Text('기록 삭제'))
                                          ])),
                            ]),
                            if (featured)
                              Text(entry.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppDesign.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(entry.metadata,
                                style: _TripHistoryEntry.metadataStyle),
                            const SizedBox(height: 8),
                            if (featured) const Spacer(),
                            if (featured)
                              FilledButton(
                                  onPressed:
                                      busy ? null : () => _select(record),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppDesign.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 36)),
                                  child: const Text('이어보기  →'))
                            else
                              Row(children: [
                                Icon(entry.icon, size: 14),
                                const SizedBox(width: 4),
                                Text(entry.category, style: AppDesign.caption)
                              ]),
                          ])),
                    ]))),
          )),
    );
  }

  Widget _buildFooter() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDesign.spacing24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_failed) {
      return Column(
        children: [
          const Text('여행 계획을 불러오지 못했어요.', style: AppDesign.bodySmall),
          TextButton(onPressed: _loadMore, child: const Text('다시 시도')),
        ],
      );
    }
    if (_records.isEmpty) {
      return Center(
          child: Text(
              history.search.isNotEmpty || history.since != null
                  ? '조건에 맞는 여행 계획이 없어요.'
                  : '저장된 여행 계획이 없어요.',
              style: AppDesign.bodyMedium));
    }
    if (_hasMore) {
      return OutlinedButton(
        onPressed: _loadMore,
        child: const Text('이전 기록 더 보기'),
      );
    }
    return const SizedBox.shrink();
  }
}

class _TripHistoryEntry {
  _TripHistoryEntry(TripRecord record)
      : storedCategory = record['category']?.toString(),
        rawTitle = record['title']?.toString().trim() ?? '',
        date = DateTime.tryParse(record['created_at']?.toString() ?? '')
            ?.toLocal();

  static final _menuTitle = RegExp(r'^메뉴: *([^\r\n]+)');
  static final _region = RegExp(r'^지역: *([^\r\n]+)', multiLine: true);
  static final metadataStyle =
      AppDesign.caption.copyWith(color: AppDesign.label2);

  final String? storedCategory;
  final String rawTitle;
  final DateTime? date;

  String get title {
    final menu = _menuTitle.firstMatch(rawTitle)?.group(1)?.trim();
    if (menu == null) return rawTitle.isEmpty ? '여행 계획' : rawTitle;
    final details = rawTitle
        .split('\n')
        .where((line) => RegExp(r'^(지역|테마|동행|숙소|분위기):').hasMatch(line))
        .map((line) => line.substring(line.indexOf(':') + 1).trim())
        .where((value) => value.isNotEmpty);
    return [menu, ...details].join(' · ');
  }

  String get category {
    if (storedCategory != null) return storedCategory!;
    if (title.contains('스테이') || title.contains('숙소')) return '스테이';
    if (title.contains('맛집')) return '맛집';
    if (title.contains('여행') || title.contains('명소')) return '여행';
    return '기타';
  }

  IconData get icon =>
      switch (_menuTitle.firstMatch(rawTitle)?.group(1)?.trim() ?? title) {
        '테마 여행' => Icons.explore_outlined,
        '스테이 & 무드' => Icons.bed_outlined,
        '근처 명소' => Icons.place_outlined,
        '함께하는 여행' => Icons.people_outline_rounded,
        _ => Icons.chat_bubble_outline_rounded,
      };

  String get metadata {
    final region = rawTitle.startsWith('메뉴:')
        ? _region.firstMatch(rawTitle)?.group(1)?.trim()
        : null;
    final savedAt = date;
    final saved = savedAt == null
        ? '저장된 추천'
        : '${savedAt.year}.${savedAt.month.toString().padLeft(2, '0')}.${savedAt.day.toString().padLeft(2, '0')} ${savedAt.hour.toString().padLeft(2, '0')}:${savedAt.minute.toString().padLeft(2, '0')} 저장';
    return region == null
        ? saved
        : '${region == 'Seoul' ? '서울' : region} · $saved';
  }
}

/// 화면에 보이는 기록만 기존 장소 사진 조회 경로로 불러옵니다.
class _HistoryPhoto extends StatefulWidget {
  const _HistoryPhoto(
      {super.key,
      required this.record,
      required this.scroll,
      required this.height});
  final TripRecord record;
  final ScrollController scroll;
  final double height;
  @override
  State<_HistoryPhoto> createState() => _HistoryPhotoState();
}

class _HistoryPhotoState extends State<_HistoryPhoto> {
  bool _visible = false;
  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_checkVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisible());
  }

  void _checkVisible() {
    if (!mounted || _visible) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height && top + box.size.height > 0) {
      setState(() => _visible = true);
    }
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_checkVisible);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisible());
    final saved = widget.record['recommendation_data'];
    final first = saved is List && saved.isNotEmpty && saved.first is Map
        ? saved.first as Map
        : const {};
    final title =
        (widget.record['preview_title'] ?? first['title'] ?? '').toString();
    final address =
        (widget.record['preview_address'] ?? first['address'] ?? '').toString();
    if (!_visible || (title.isEmpty && address.isEmpty)) {
      return const ColoredBox(
          color: AppDesign.lightGray,
          child: Center(
              child: Icon(Icons.photo_outlined, color: AppDesign.subtleText)));
    }
    return AddressPhotoPreview(
        address: address, title: title, size: widget.height);
  }
}
