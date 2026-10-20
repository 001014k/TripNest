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
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                                color: const Color(0xFFD4D4D8),
                                borderRadius: BorderRadius.circular(4)))),
                    const SizedBox(height: 20),
                    const Text('키워드 선택',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('하나 또는 여러 개를 선택할 수 있어요.',
                        style:
                            TextStyle(color: Color(0xFF85858B), fontSize: 13)),
                    const SizedBox(height: 18),
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
                            label: Text({'호텔': '숙소', '음식점': '맛집'}[entry.key] ??
                                entry.key),
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
                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF222222),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            onPressed: () => Navigator.pop(
                                context, Set<String>.of(_selected)),
                            child: Text(_selected.isEmpty
                                ? '전체 보기 · 완료'
                                : '${_selected.length}개 선택 · 완료'))),
                  ]))));
}
