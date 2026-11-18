import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 저장하지 않은 장소의 예시이며, 기존 이야기·지도 화면 흐름을 유지합니다.
class UnsavedPlaceGuideCard extends StatelessWidget {
  const UnsavedPlaceGuideCard(
      {super.key,
      required this.target,
      required this.last,
      required this.canTry,
      this.inDetail = false});
  final Rect target;
  final bool last, canTry, inDetail;
  static const _ink = Color(0xff222222);
  static const _muted = Color(0xff808089);

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final safe = MediaQuery.paddingOf(context);
        // 강조한 조작 요소를 가리지 않고 카드와 화살표로 연결합니다.
        // 내용이 길면 확보된 공간 안에서 스크롤합니다.
        final safeTop = safe.top + 8;
        final safeBottom = bounds.maxHeight - safe.bottom - 12;
        const gap = 40.0;
        final above = math.max(0.0, target.top - gap - safeTop);
        final below = math.max(0.0, safeBottom - target.bottom - gap);
        final placeBelow = below >= above;
        final top = placeBelow ? target.bottom + gap : safeTop;
        final bottom =
            placeBelow ? safe.bottom + 12 : bounds.maxHeight - target.top + gap;
        return Stack(children: [
          Positioned(
              left: (target.center.dx - 14).clamp(12.0, bounds.maxWidth - 40),
              top: placeBelow ? target.bottom + 6 : target.top - 34,
              child: IgnorePointer(
                  child: Icon(
                      placeBelow
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      key: const ValueKey('unsaved-guide-pointer'),
                      size: 28,
                      color: Colors.white))),
          Positioned(
              left: 12,
              right: 12,
              top: top,
              bottom: bottom,
              child: Align(
                  alignment:
                      placeBelow ? Alignment.topCenter : Alignment.bottomCenter,
                  child: ClipRRect(
                      key: const ValueKey('unsaved-guide-card'),
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
                                                              .location_on_outlined,
                                                          color: _ink)),
                                                  IconButton(
                                                      tooltip: '안내 닫기',
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      icon: const Icon(
                                                          Icons.close,
                                                          color: _ink))
                                                ]),
                                            const SizedBox(height: 8),
                                            Text(
                                                inDetail
                                                    ? '강조된 장소 주소 카드를 확인해보세요'
                                                    : '강조된 게시물을 선택해보세요',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: _muted)),
                                            const SizedBox(height: 8),
                                            const Text('발견한 장소를\n내 지도에 담아보세요',
                                                style: TextStyle(
                                                    fontSize: 23,
                                                    height: 1.25,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -.7,
                                                    color: _ink)),
                                            const SizedBox(height: 10),
                                            Text(
                                                inDetail
                                                    ? '장소 주소 카드를 누르면 지도에서 위치를 확인하고 저장할 수 있어요.'
                                                    : '게시물 사진이나 제목을 누르면 상세 페이지가 열려요. 상세 페이지에서 장소 주소 카드를 선택해 지도에서 확인해보세요.',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1.4,
                                                    color: _muted)),
                                            const SizedBox(height: 8),
                                            const _PlaceExample(),
                                            const SizedBox(height: 8),
                                            const Text(
                                                '게시물 열기 → 장소 주소 카드 → 지도에서 저장',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    height: 1.5,
                                                    color: _muted)),
                                            const SizedBox(height: 10),
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
                                            const SizedBox(height: 10),
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
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffe1e1e6)),
          borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        const SizedBox(
            height: 64,
            width: double.infinity,
            child: _PreviewCrop(region: Rect.fromLTWH(147, 1126, 591, 132))),
        Padding(
            padding: const EdgeInsets.all(9),
            child: Row(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const SizedBox(
                      width: 48,
                      height: 46,
                      child: _PreviewCrop(
                          region: Rect.fromLTWH(157, 1273, 137, 100)))),
              const SizedBox(width: 10),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('골목 속 작은 카페',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff222222))),
                    SizedBox(height: 4),
                    Text('아직 저장하지 않은 장소',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xff808089)))
                  ])),
              const Icon(Icons.bookmark_border,
                  color: Color(0xff222222), size: 24),
            ])),
      ]));
}

class _PreviewCrop extends StatelessWidget {
  const _PreviewCrop({required this.region});
  final Rect region;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
              width: region.width,
              height: region.height,
              child: ClipRect(
                  child: Stack(children: [
                Positioned(
                    left: -region.left,
                    top: -region.top,
                    width: 886,
                    height: 1776,
                    child: Image.asset(
                        'assets/images/unsaved_guide_reference.png',
                        fit: BoxFit.fill))
              ])))));
}
