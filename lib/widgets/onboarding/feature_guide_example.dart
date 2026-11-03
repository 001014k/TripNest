import 'package:flutter/material.dart';
import '../../models/onboarding/feature_guide.dart';

/// Local-only demo: intentionally has no providers, services, API or permissions.
class FeatureGuideExample extends StatefulWidget {
  const FeatureGuideExample(
      {super.key, required this.guide, this.last = true, this.canTry = false});
  final FeatureGuide guide;
  final bool last, canTry;

  static Future<String?> show(BuildContext context, FeatureGuide guide,
          {bool last = true, bool canTry = false}) =>
      showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) =>
              FeatureGuideExample(guide: guide, last: last, canTry: canTry));

  @override
  State<FeatureGuideExample> createState() => _FeatureGuideExampleState();
}

class _FeatureGuideExampleState extends State<FeatureGuideExample> {
  final places = ['골목 속 작은 카페', '바다가 보이는 산책길', '작은 전시 공간'];
  final keywords = <String>{};
  bool editor = false,
      saved = false,
      editing = false,
      markerVisible = true,
      sheetOpen = true;
  int step = 0;

  Widget card(Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xfff4f4f6),
          borderRadius: BorderRadius.circular(18)),
      child: child);

  Widget demo() {
    switch (widget.guide) {
      case FeatureGuide.routeOrder:
        return Column(children: [
          const Text('장소를 길게 눌러 순서를 바꿔보세요.'),
          ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: places.length,
              onReorderItem: (oldIndex, newIndex) => setState(() {
                    places.insert(newIndex, places.removeAt(oldIndex));
                  }),
              itemBuilder: (_, i) => ListTile(
                  key: ValueKey(places[i]),
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(places[i]),
                  trailing: const Icon(Icons.drag_handle))),
          OutlinedButton(
              onPressed: () => setState(() => step = 1),
              child: const Text('번호 마커로 보기')),
          if (step == 1)
            card(Column(children: [
              const Icon(Icons.route, size: 40),
              for (var i = 0; i < places.length; i++)
                Text('${i + 1} → ${places[i]}'),
              const Text('이 순서대로 지도에 번호가 표시돼요.'),
            ])),
        ]);
      case FeatureGuide.storySave:
        return card(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.storefront_outlined, size: 48),
          Row(children: [
            const Expanded(child: Text('골목 속 작은 카페 · 예시 게시물')),
            IconButton(
                tooltip: '예시 장소 저장',
                onPressed: saved ? null : () => setState(() => editing = true),
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border))
          ]),
          if (!editing && !saved) const Text('북마크를 눌러 마커 생성 과정을 확인해보세요.'),
          if (editing && !saved) ...[
            const Divider(),
            const Text('마커 만들기 · 예시'),
            const Text('장소명: 골목 속 작은 카페'),
            const Chip(label: Text('카페')),
            FilledButton(
                onPressed: () => setState(() => saved = true),
                child: const Text('예시 마커 저장')),
          ],
          if (saved) const Text('저장됨 · 체험 상태만 변경됐어요.'),
        ]));
      case FeatureGuide.temporaryMarker:
        return card(Column(children: [
          const Text('지도 예시'),
          const SizedBox(height: 12),
          if (markerVisible)
            Icon(saved ? Icons.bookmark : Icons.location_on_outlined, size: 52),
          if (!markerVisible) const Text('미저장 임시 마커가 사라졌어요.'),
          if (sheetOpen) ...[
            const Text('골목 속 작은 카페'),
            TextButton(
                onPressed: () => setState(() => saved = true),
                child: Text(saved ? '저장됨 · 예시' : '내 지도에 저장 · 예시')),
            OutlinedButton(
                onPressed: () => setState(() {
                      sheetOpen = false;
                      markerVisible = saved;
                    }),
                child: const Text('장소 하단창 닫기')),
          ] else ...[
            if (saved) const Text('저장한 마커는 하단창을 닫아도 남아요.'),
            TextButton(
                onPressed: () => setState(() {
                      sheetOpen = true;
                      markerVisible = true;
                      saved = false;
                    }),
                child: const Text('다시 체험하기')),
          ],
        ]));
      case FeatureGuide.collaboration:
        return card(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('주말 여행 · 예시 리스트'),
          const SizedBox(height: 12),
          const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('여행 친구 · 예시 멤버')),
          Wrap(spacing: 8, children: [
            ChoiceChip(
                label: const Text('게스트'),
                selected: !editor,
                onSelected: (_) => setState(() => editor = false)),
            ChoiceChip(
                label: const Text('편집자'),
                selected: editor,
                onSelected: (_) => setState(() => editor = true)),
          ]),
          const SizedBox(height: 12),
          Text(editor ? '장소 추가·삭제가 가능해요.' : '리스트와 장소를 읽기만 할 수 있어요.'),
          const Text('친구 초대와 역할 변경은 소유자가 할 수 있어요.'),
        ]));
      case FeatureGuide.keywords:
        return card(Column(children: [
          const Text('지도에서 보고 싶은 키워드를 골라보세요.'),
          Wrap(spacing: 8, children: [
            for (final label in ['카페', '맛집', '숙소', '전시회'])
              FilterChip(
                  label: Text(label),
                  selected: keywords.contains(label),
                  onSelected: (value) => setState(() {
                        if (value) {
                          keywords.add(label);
                        } else {
                          keywords.remove(label);
                        }
                      }))
          ]),
          Text(keywords.isEmpty
              ? '전체 장소 표시 · 예시'
              : '${keywords.join(', ')} 장소만 표시 · 예시'),
        ]));
      case FeatureGuide.nearby:
        return card(Column(children: [
          const Icon(Icons.near_me_outlined, size: 48),
          const Text('내 주변 · 위치 권한 없이 보는 예시'),
          const ListTile(
              title: Text('골목 속 작은 카페'), subtitle: Text('예시 거리 500m')),
          const Text('실제 실행할 때 위치 권한을 요청할 수 있어요. 허용하지 않아도 최근·인기 게시물은 볼 수 있어요.'),
        ]));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                      child: Text('체험용 예시 · 실제로 저장되지 않아요',
                          style: TextStyle(fontSize: 12))),
                  IconButton(
                      tooltip: '예시 안내 닫기',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close))
                ]),
                const SizedBox(height: 12),
                Text(widget.guide.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(widget.guide.description,
                    style: const TextStyle(height: 1.6)),
                const SizedBox(height: 20),
                demo(),
                const SizedBox(height: 24),
                if (widget.canTry)
                  SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, 'try'),
                          child: const Text('직접 해보기'))),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: () => Navigator.pop(context, 'next'),
                        child: Text(widget.last ? '안내 마치기' : '다음 안내'))),
              ])));
}
