import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 키워드 안내는 실제 필터 요소에 선택 예시를 표시합니다.
class KeywordGuideCard extends StatelessWidget {
  const KeywordGuideCard(
      {super.key,
      required this.target,
      required this.last,
      required this.canTry});
  final Rect target;
  final bool last, canTry;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final safe = MediaQuery.paddingOf(context);
        final bottom = safe.bottom + 64;
        final tooltipTop = target.bottom + 12;
        final cardTop = math.min(tooltipTop + 64, bounds.maxHeight * .32);
        return Stack(children: [
          if (bounds.maxHeight > 650)
            Positioned(
                top: tooltipTop,
                right: 16,
                child: IgnorePointer(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                      Padding(
                          padding: EdgeInsets.only(
                              right: math.max(
                                  16, bounds.maxWidth - target.center.dx - 24)),
                          child: CustomPaint(
                              size: const Size(18, 9), painter: _Pointer())),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x18000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 5))
                              ]),
                          child: const Text('여기서 키워드를 선택해요',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff202023)))),
                    ]))),
          Positioned(
              left: 12,
              right: 12,
              top: cardTop,
              bottom: bottom,
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Material(
                          color: Colors.white,
                          child: SingleChildScrollView(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 10, 20, 8),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                            child: Container(
                                                width: 34,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xffd5d5d9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3)))),
                                        const SizedBox(height: 8),
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
                                                      Icons.tune_rounded,
                                                      color:
                                                          Color(0xff222222))),
                                              IconButton(
                                                  tooltip: '안내 닫기',
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  icon: const Icon(Icons.close,
                                                      color: Color(0xff333333)))
                                            ]),
                                        const SizedBox(height: 10),
                                        const Text('원하는 장소만\n골라보세요',
                                            style: TextStyle(
                                                fontSize: 28,
                                                height: 1.2,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -.8,
                                                color: Color(0xff202023))),
                                        const SizedBox(height: 12),
                                        const Text(
                                            '카페부터 맛집까지, 여러 키워드를\n함께 선택해 지도에서 볼 수 있어요.',
                                            style: TextStyle(
                                                fontSize: 15,
                                                height: 1.6,
                                                color: Color(0xff77777d))),
                                        const SizedBox(height: 16),
                                        Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 14),
                                            decoration: BoxDecoration(
                                                color: const Color(0xfff6f5f4),
                                                borderRadius:
                                                    BorderRadius.circular(16)),
                                            child: Column(children: [
                                              const Wrap(
                                                  alignment:
                                                      WrapAlignment.center,
                                                  spacing: 6,
                                                  runSpacing: 8,
                                                  children: [
                                                    _ExampleChip(
                                                        '카페',
                                                        Icons.coffee_outlined,
                                                        true),
                                                    _ExampleChip(
                                                        '맛집',
                                                        Icons
                                                            .restaurant_outlined,
                                                        true),
                                                    _ExampleChip(
                                                        '숙소',
                                                        Icons.bed_outlined,
                                                        false)
                                                  ]),
                                              const SizedBox(height: 12),
                                              const Text('키워드 선택 → 완료 → 지도에 적용',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Color(0xff77777d))),
                                            ])),
                                        const SizedBox(height: 16),
                                        Row(children: [
                                          Expanded(
                                              child: OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                      foregroundColor: const Color(
                                                          0xff222222),
                                                      minimumSize:
                                                          const Size(0, 48),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 8),
                                                      side: const BorderSide(
                                                          color: Color(
                                                              0xff96969b)),
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  13))),
                                                  onPressed: () => Navigator.pop(
                                                      context, 'example'),
                                                  child: const Text('예시로 보기'))),
                                          if (canTry) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: FilledButton(
                                                    style: FilledButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xff222222),
                                                        foregroundColor:
                                                            Colors.white,
                                                        minimumSize:
                                                            const Size(0, 48),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                                horizontal: 8),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    13))),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, 'try'),
                                                    child:
                                                        const Text('직접 해보기 →')))
                                          ]
                                        ]),
                                        const SizedBox(height: 12),
                                        const Divider(
                                            height: 1,
                                            color: Color(0xffeeeef0)),
                                        Center(
                                            child: TextButton(
                                                style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        const Color(
                                                            0xff77777d)),
                                                onPressed: () => Navigator.pop(
                                                    context, 'next'),
                                                child: Text(
                                                    last ? '닫기' : '다음 안내'))),
                                      ]))))))),
        ]);
      });
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip(this.label, this.icon, this.selected);
  final String label;
  final IconData icon;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
          color: selected ? const Color(0xff222222) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected
                  ? const Color(0xff222222)
                  : const Color(0xff99999e))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 18, color: selected ? Colors.white : const Color(0xff333333)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : const Color(0xff333333))),
        if (selected) ...[
          const SizedBox(width: 4),
          const Icon(Icons.check, size: 15, color: Colors.white)
        ]
      ]));
}

class _Pointer extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close(),
      Paint()..color = Colors.white);
  @override
  bool shouldRepaint(_Pointer oldDelegate) => false;
}
