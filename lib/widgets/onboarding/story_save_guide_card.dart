import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 북마크 안내이며, 버튼 동작은 기존 마커 생성 흐름을 유지합니다.
class StorySaveGuideCard extends StatelessWidget {
  const StorySaveGuideCard(
      {super.key,
      required this.target,
      required this.last,
      required this.canTry});
  final Rect target;
  final bool last, canTry;
  static const _ink = Color(0xff222222);
  static const _muted = Color(0xff808089);

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final safe = MediaQuery.paddingOf(context);
        // 실제 북마크 버튼을 가리지 않도록 대상 주변의 넓은 공간을 사용합니다.
        // 카드를 버튼 위로 옮기지 않고 내부 내용을 스크롤합니다.
        final safeTop = safe.top + 8;
        final safeBottom = bounds.maxHeight - safe.bottom - 12;
        final above = math.max(0.0, target.top - 16 - safeTop);
        final below = math.max(0.0, safeBottom - target.bottom - 16);
        final placeBelow = below >= above;
        final top = placeBelow ? target.bottom + 16 : safeTop;
        final bottom =
            placeBelow ? safe.bottom + 12 : bounds.maxHeight - target.top + 16;
        return Stack(children: [
          Positioned(
              left: 12,
              right: 12,
              top: top,
              bottom: bottom,
              child: Align(
                  alignment:
                      placeBelow ? Alignment.topCenter : Alignment.bottomCenter,
                  child: ClipRRect(
                      key: const ValueKey('story-save-guide-card'),
                      borderRadius: BorderRadius.circular(24),
                      child: Material(
                          color: Colors.white,
                          child: SizedBox(
                              width: double.infinity,
                              child: SingleChildScrollView(
                                  child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 10, 16, 2),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Container(
                                                      width: 42,
                                                      height: 42,
                                                      decoration: BoxDecoration(
                                                          color: const Color(
                                                              0xfff3f3f4),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      12)),
                                                      child: const Icon(
                                                          Icons
                                                              .bookmark_add_outlined,
                                                          color: _ink)),
                                                  const SizedBox(width: 10),
                                                  const Expanded(
                                                      child: Text(
                                                          '이야기 속 장소를\n내 지도에 저장해요',
                                                          style: TextStyle(
                                                              fontSize: 19,
                                                              height: 1.25,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              letterSpacing:
                                                                  -.7,
                                                              color: _ink))),
                                                  IconButton(
                                                      tooltip: '안내 닫기',
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      icon: const Icon(
                                                          Icons.close,
                                                          color: _ink))
                                                ]),
                                            const SizedBox(height: 4),
                                            const SizedBox(height: 6),
                                            const Text(
                                                '북마크를 누르면 마커 생성 화면이 열려요.\n이름과 키워드를 확인한 뒤 저장해주세요.',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1.4,
                                                    color: _muted)),
                                            const SizedBox(height: 4),
                                            const _PlaceExample(),
                                            const SizedBox(height: 4),
                                            const Row(children: [
                                              Icon(Icons.bookmark,
                                                  size: 18, color: _ink),
                                              SizedBox(width: 8),
                                              Expanded(
                                                  child: Text(
                                                      '이미 저장한 장소는 저장됨으로 표시돼요.',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: _muted))),
                                            ]),
                                            const Divider(
                                                height: 18,
                                                color: Color(0xffeeeef0)),
                                            const _SaveSteps(),
                                            const SizedBox(height: 6),
                                            Row(children: [
                                              Expanded(
                                                  child: OutlinedButton(
                                                      style: OutlinedButton.styleFrom(
                                                          foregroundColor: _ink,
                                                          minimumSize:
                                                              const Size(0, 46),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 10),
                                                          side: const BorderSide(
                                                              color: Color(
                                                                  0xff96969b)),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      12))),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, 'example'),
                                                      child: const Text('예시로 보기',
                                                          textAlign: TextAlign.center))),
                                              if (canTry) ...[
                                                const SizedBox(width: 8),
                                                Expanded(
                                                    child: FilledButton(
                                                        style: FilledButton.styleFrom(
                                                            backgroundColor:
                                                                _ink,
                                                            foregroundColor:
                                                                Colors.white,
                                                            minimumSize:
                                                                const Size(
                                                                    0, 46),
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 10),
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        12))),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, 'try'),
                                                        child: const Text(
                                                            '직접 해보기 →',
                                                            textAlign:
                                                                TextAlign.center)))
                                              ]
                                            ]),
                                            const SizedBox(height: 6),
                                            const Divider(
                                                height: 1,
                                                color: Color(0xffeeeef0)),
                                            Center(
                                                child: TextButton(
                                                    style: TextButton.styleFrom(
                                                        foregroundColor:
                                                            _muted),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, 'next'),
                                                    child: Text(last
                                                        ? '닫기'
                                                        : '다음 안내'))),
                                          ])))))))),
        ]);
      });
}

class _PlaceExample extends StatelessWidget {
  const _PlaceExample();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xfff5f5f6),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('예시',
            style: TextStyle(fontSize: 10, color: Color(0xff808089))),
        const SizedBox(height: 5),
        Row(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                  width: 76,
                  height: 64,
                  child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                          width: 210,
                          height: 177,
                          child: Stack(children: [
                            Positioned(
                                left: -146,
                                top: -1085,
                                width: 877,
                                height: 1794,
                                child: Image.asset(
                                    'assets/images/story_save_guide_reference.png',
                                    fit: BoxFit.fill))
                          ]))))),
          const SizedBox(width: 12),
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('장소 이름',
                    style: TextStyle(fontSize: 10, color: Color(0xff808089))),
                Text('골목 속 작은 카페',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('키워드',
                    style: TextStyle(fontSize: 10, color: Color(0xff808089))),
                SizedBox(height: 3),
                Wrap(spacing: 6, children: [
                  _Keyword(Icons.local_cafe_outlined, '카페'),
                  _Keyword(Icons.camera_alt_outlined, '사진')
                ]),
              ])),
        ]),
      ]));
}

class _Keyword extends StatelessWidget {
  const _Keyword(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xffebebee),
          borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11))
      ]));
}

class _SaveSteps extends StatelessWidget {
  const _SaveSteps();
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0)
            const Icon(Icons.arrow_forward, size: 14, color: Color(0xff99999f)),
          Expanded(
              child: Column(children: [
            CircleAvatar(
                radius: 10,
                backgroundColor: const Color(0xffe5e5e8),
                child: Text('${i + 1}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xff222222)))),
            const SizedBox(height: 4),
            Text(['북마크', '이름·키워드 확인', '저장'][i],
                style: const TextStyle(fontSize: 10, color: Color(0xff808089))),
          ])),
        ],
      ]);
}
