import '../common/app_overlays.dart';
import 'package:flutter/material.dart';

class MapKeywordSheet extends StatefulWidget {
  const MapKeywordSheet(
      {super.key, required this.keywords, required this.selected});
  final Map<String, IconData> keywords;
  final Set<String> selected;
  @override
  State<MapKeywordSheet> createState() => _MapKeywordSheetState();
}

class _MapKeywordSheetState extends State<MapKeywordSheet> {
  late final Set<String> _selected = Set.of(widget.selected);
  @override
  Widget build(BuildContext context) => AppSheet(
        title: '키워드 선택',
        subtitle: '하나 또는 여러 개를 선택할 수 있어요.',
        footer: FilledButton(
            onPressed: () => Navigator.pop(context, Set<String>.of(_selected)),
            child: Text(_selected.isEmpty
                ? '전체 보기 · 완료'
                : '${_selected.length}개 선택 · 완료')),
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilterChip(
                label: const Text('전체'),
                selected: _selected.isEmpty,
                onSelected: (_) => setState(_selected.clear)),
            ...widget.keywords.entries.map((entry) => FilterChip(
                  avatar: Icon(entry.value,
                      size: 18,
                      color: _selected.contains(entry.key)
                          ? Colors.white
                          : const Color(0xFF222222)),
                  label:
                      Text({'호텔': '숙소', '음식점': '맛집'}[entry.key] ?? entry.key),
                  selected: _selected.contains(entry.key),
                  selectedColor: const Color(0xFF222222),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                      color: _selected.contains(entry.key)
                          ? Colors.white
                          : const Color(0xFF222222)),
                  onSelected: (active) => setState(() {
                    active
                        ? _selected.add(entry.key)
                        : _selected.remove(entry.key);
                  }),
                )),
          ]),
        ],
      );
}
