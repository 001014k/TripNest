import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 사용자가 저장한 장소와 별개로 제공하는 로컬 여행 일정 예시입니다.
class RouteGuideCard extends StatelessWidget {
  const RouteGuideCard(
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
        final above = target.top - safe.top;
        final placeAbove = above > 240;
        final top = placeAbove ? safe.top + 16 : target.bottom + 16;
        final bottom =
            placeAbove ? bounds.maxHeight - target.top + 20 : safe.bottom + 16;
        final showBubble = placeAbove &&
            target.left > 150 &&
            MediaQuery.textScalerOf(context).scale(14) < 20;
        return Stack(children: [
          if (showBubble)
            Positioned(
                right: bounds.maxWidth - target.left + 8,
                top: target.center.dy - 22,
                child: IgnorePointer(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      constraints: BoxConstraints(
                          maxWidth: math.max(100, target.left - 28)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 12,
                                offset: Offset(0, 4))
                          ]),
                      child: const Text('여기서 여행 리스트를 선택해요',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _ink))),
                  CustomPaint(size: const Size(8, 14), painter: _BubbleTip()),
                ]))),
          Positioned(
              left: 20,
              right: 20,
              top: top,
              bottom: bottom,
              child: Align(
                  alignment:
                      placeAbove ? Alignment.bottomCenter : Alignment.topCenter,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Material(
                          color: Colors.white,
                          child: SingleChildScrollView(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 12, 18, 4),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                  width: 42,
                                                  height: 42,
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xfff3f3f4),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12)),
                                                  child: const Icon(
                                                      Icons
                                                          .format_list_bulleted_rounded,
                                                      color: _ink)),
                                              IconButton(
                                                  tooltip: '안내 닫기',
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  icon: const Icon(Icons.close,
                                                      color: _ink))
                                            ]),
                                        const SizedBox(height: 8),
                                        const Text('가고 싶은 순서대로\n여행을 준비해요',
                                            style: TextStyle(
                                                fontSize: 25,
                                                height: 1.25,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -.7,
                                                color: _ink)),
                                        const SizedBox(height: 10),
                                        const Text(
                                            '여행 리스트를 선택하고, 장소를 길게 눌러\n방문 순서를 바꿔보세요.',
                                            style: TextStyle(
                                                fontSize: 14,
                                                height: 1.6,
                                                color: _muted)),
                                        const SizedBox(height: 12),
                                        const _RouteExample(),
                                        const SizedBox(height: 8),
                                        const Text('리스트 선택 → 순서 변경 → 번호 마커로 확인',
                                            style: TextStyle(
                                                fontSize: 11,
                                                height: 1.5,
                                                color: _muted)),
                                        const SizedBox(height: 14),
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
                                                  onPressed: () => Navigator.pop(
                                                      context, 'example'),
                                                  child: const Text('예시로 보기',
                                                      textAlign: TextAlign.center))),
                                          if (canTry) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: FilledButton(
                                                    style: FilledButton.styleFrom(
                                                        backgroundColor: _ink,
                                                        foregroundColor:
                                                            Colors.white,
                                                        minimumSize:
                                                            const Size(0, 46),
                                                        padding:
                                                            const EdgeInsets.symmetric(
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
                                                    foregroundColor: _muted),
                                                onPressed: () => Navigator.pop(
                                                    context, 'next'),
                                                child: Text(
                                                    last ? '닫기' : '다음 안내'))),
                                      ]))))))),
        ]);
      });
}

class _RouteExample extends StatelessWidget {
  const _RouteExample();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: const Color(0xfff5f5f5),
          borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        for (var i = 0; i < 3; i++)
          Container(
              margin: EdgeInsets.only(bottom: i < 2 ? 3 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                  color: i == 1 ? Colors.white : const Color(0xfffafafa),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: i == 1
                          ? const Color(0xff222222)
                          : const Color(0xffe8e8eb)),
                  boxShadow: i == 1
                      ? const [
                          BoxShadow(
                              color: Color(0x13000000),
                              blurRadius: 8,
                              offset: Offset(0, 3))
                        ]
                      : null),
              child: Row(children: [
                Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0
                            ? const Color(0xff222222)
                            : const Color(0xffe5e5e8)),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 12,
                            color: i == 0
                                ? Colors.white
                                : const Color(0xff222222)))),
                const SizedBox(width: 8),
                _ExamplePhoto(index: i),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(['골목 속 작은 카페', '바다가 보이는 산책길', '노을이 예쁜 공원'][i],
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xff222222)))),
                if (i == 1)
                  const Icon(Icons.unfold_more,
                      size: 20, color: Color(0xff222222)),
                const Icon(Icons.drag_handle,
                    size: 19, color: Color(0xffb3b3b8)),
              ])),
      ]));
}

class _ExamplePhoto extends StatelessWidget {
  const _ExamplePhoto({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
              width: 38,
              height: 38,
              child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                      width: 90,
                      height: 74,
                      child: ClipRect(
                          child: Stack(children: [
                        Positioned(
                            left: -252,
                            top: -[836.0, 925.0, 1020.0][index],
                            width: 887,
                            height: 1774,
                            child: Image.asset(
                                'assets/images/route_guide_reference.png',
                                fit: BoxFit.fill))
                      ])))))));
}

class _BubbleTip extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = Colors.white);
  @override
  bool shouldRepaint(_BubbleTip oldDelegate) => false;
}
