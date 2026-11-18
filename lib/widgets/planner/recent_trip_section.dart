import 'package:flutter/material.dart';

import '../../design/app_design.dart';

typedef TripRecord = Map<String, dynamic>;
typedef TripPageLoader = Future<List<TripRecord>> Function(int offset);

class RecentTripSection extends StatelessWidget {
  const RecentTripSection({
    super.key,
    required this.latest,
    required this.loadPage,
    required this.onSelect,
  });

  final TripRecord latest;
  final TripPageLoader loadPage;
  final ValueChanged<TripRecord> onSelect;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(
              child: Text('최근 여행 계획', style: AppDesign.headingSmall),
            ),
            TextButton(
              onPressed: () async {
                final record = await Navigator.of(context).push<TripRecord>(
                  MaterialPageRoute(
                    builder: (_) => _TripHistoryScreen(loadPage: loadPage),
                  ),
                );
                if (context.mounted && record != null) onSelect(record);
              },
              child: const Text('전체 보기'),
            ),
          ]),
          _TripRecordCard(record: latest, onTap: () => onSelect(latest)),
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
  const _TripHistoryScreen({required this.loadPage});
  final TripPageLoader loadPage;

  @override
  State<_TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<_TripHistoryScreen> {
  final _records = <TripRecord>[];
  bool _loading = false;
  bool _hasMore = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await widget.loadPage(_records.length);
      if (!mounted) return;
      setState(() {
        _records.addAll(page);
        _hasMore = page.length == 20;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(TripRecord record) => Navigator.of(context).pop(record);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.primaryBg,
        body: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: _records.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: AppDesign.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('여행 계획 기록', style: AppDesign.headingLarge),
                      SizedBox(height: AppDesign.spacing8),
                      Text('저장한 여행 계획을 다시 이어보세요.', style: AppDesign.bodySmall),
                    ],
                  ),
                );
              }
              if (index <= _records.length) {
                final record = _records[index - 1];
                final entry = _TripHistoryEntry(record);
                if (index == 1) {
                  return _buildLatest(entry, () => _select(record));
                }
                return _buildHistoryRow(
                  entry,
                  first: index == 2,
                  last: index == _records.length,
                  onTap: () => _select(record),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppDesign.spacing16),
                child: _buildFooter(),
              );
            },
          ),
        ),
      );

  Widget _buildLatest(_TripHistoryEntry entry, VoidCallback onTap) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Material(
        color: AppDesign.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          side: const BorderSide(color: AppDesign.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppDesign.secondaryBg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 14),
                      SizedBox(width: AppDesign.spacing6),
                      Flexible(
                        child: Text('최근 여행 계획', style: AppDesign.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDesign.spacing12),
              Text(entry.title, style: AppDesign.headingMedium),
              const SizedBox(height: AppDesign.spacing4),
              Text(entry.metadata, style: _TripHistoryEntry.metadataStyle),
              const SizedBox(height: AppDesign.spacing16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppDesign.primary,
                  foregroundColor: AppDesign.whiteText,
                  minimumSize: const Size(48, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                  ),
                ),
                onPressed: onTap,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text('이어보기')),
                    SizedBox(width: AppDesign.spacing6),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(
    _TripHistoryEntry entry, {
    required bool first,
    required bool last,
    required VoidCallback onTap,
  }) {
    const radius = Radius.circular(AppDesign.radiusMedium);
    final row = Material(
      color: AppDesign.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: first ? radius : Radius.zero,
          bottom: last ? radius : Radius.zero,
        ),
        side: const BorderSide(color: AppDesign.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppDesign.secondaryBg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
                child: Icon(entry.icon, size: 18, color: AppDesign.primary),
              ),
              const SizedBox(width: AppDesign.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppDesign.bodyMedium),
                    Text(entry.metadata,
                        style: _TripHistoryEntry.metadataStyle),
                  ],
                ),
              ),
              const SizedBox(width: AppDesign.spacing8),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppDesign.label2),
            ],
          ),
        ),
      ),
    );
    if (!first) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDesign.spacing24),
        const Text('이전 기록', style: AppDesign.headingSmall),
        const SizedBox(height: AppDesign.spacing12),
        row,
      ],
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
      return const Center(
        child: Text('저장된 여행 계획이 없어요.', style: AppDesign.bodyMedium),
      );
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
      : rawTitle = record['title']?.toString().trim() ?? '',
        date = DateTime.tryParse(record['created_at']?.toString() ?? '')
            ?.toLocal();

  static final _menuTitle = RegExp(r'^메뉴: *([^\r\n]+)');
  static final _region = RegExp(r'^지역: *([^\r\n]+)', multiLine: true);
  static final metadataStyle =
      AppDesign.caption.copyWith(color: AppDesign.label2);

  final String rawTitle;
  final DateTime? date;

  String get title =>
      _menuTitle.firstMatch(rawTitle)?.group(1)?.trim() ??
      (rawTitle.isEmpty ? '여행 계획' : rawTitle);

  IconData get icon => switch (title) {
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
        : '${savedAt.year}.${savedAt.month.toString().padLeft(2, '0')}.${savedAt.day.toString().padLeft(2, '0')} 저장';
    return region == null
        ? saved
        : '${region == 'Seoul' ? '서울' : region} · $saved';
  }
}
