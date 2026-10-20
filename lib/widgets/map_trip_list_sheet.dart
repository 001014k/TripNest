import 'package:flutter/material.dart';
import 'reference_design.dart';

/// The travel card belongs to the map's list picker, not the resting map.
class MapTripListSheet extends StatelessWidget {
  const MapTripListSheet(
      {super.key,
      required this.lists,
      required this.selectedListId,
      required this.onSelect,
      required this.onReset});
  final List<Map<String, dynamic>> lists;
  final String? selectedListId;
  final ValueChanged<String> onSelect;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 28,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFCECED0),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 18),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('여행 리스트 선택',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
            const SizedBox(height: 14),
            ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .55),
                child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: lists.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 25, color: Color(0xFFF0F0F2)),
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      final id = list['id'] as String;
                      final places = (list['list_bookmarks'] as List?) ?? [];
                      final members = (list['list_members'] as List?) ?? [];
                      final title = places.isEmpty
                          ? ''
                          : places.first['title']?.toString() ?? '';
                      return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => onSelect(id),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                if (title.isNotEmpty)
                                  ReferencePhoto(
                                      title: title, width: 66, height: 72)
                                else
                                  Container(
                                      width: 66,
                                      height: 72,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFF2F3F2),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: const Icon(Icons.map_outlined,
                                          color: Color(0xFF777777), size: 30)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(list['name']?.toString() ?? '이름 없음',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 5),
                                      Text('저장한 장소 ${places.length}개',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF85868A))),
                                      const SizedBox(height: 6),
                                      if (members.isNotEmpty)
                                        ReferencePeople(count: members.length)
                                      else
                                        Text(
                                            selectedListId == id
                                                ? '현재 선택한 리스트'
                                                : '나의 여행 리스트',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF85868A))),
                                    ])),
                                const SizedBox(width: 8),
                                FilledButton(
                                    onPressed: () => onSelect(id),
                                    style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF202020),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15))),
                                    child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.play_arrow_rounded,
                                              size: 19),
                                          SizedBox(width: 3),
                                          Text('경로 시작',
                                              style: TextStyle(fontSize: 12))
                                        ])),
                              ])));
                    })),
            const SizedBox(height: 14),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh_rounded, size: 19),
                    label: const Text('초기화 · 전체 장소 보기'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF202020),
                        side: const BorderSide(color: Color(0xFFE5E5E7)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))))),
          ])));
}
