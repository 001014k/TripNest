import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 주변 장소 미리보기는 예시이며, 권한은 실제 기능을 사용할 때만 요청합니다.
class NearbyGuideCard extends StatelessWidget {
  const NearbyGuideCard(
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
        // 하단 영역을 포함한 카드 전체가 들어갈 공간을 확보합니다.
        // 화면 중간의 기준점 때문에 카드가 너무 좁은 세로 공간에 갇히지 않도록 합니다.
        final requiredHeight = 550.0 +
            math.max(0, MediaQuery.textScalerOf(context).scale(14) - 14) * 12;
        final bottom = safe.bottom + 12;
        final top = math.max(
            safe.top + 8,
            math.min(target.bottom + 16,
                bounds.maxHeight - bottom - requiredHeight));
        final showBubble = target.bottom + 10 < top &&
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
                      child: const Text('내 주변에서 가까운 이야기를 찾아요',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _ink))),
                  CustomPaint(size: const Size(8, 14), painter: _BubbleTip()),
                ]))),
          Positioned(
              left: 12,
              right: 12,
              top: top,
              bottom: bottom,
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Material(
                          color: Colors.white,
                          child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 10, 16, 2),
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
                                                          .location_on_outlined,
                                                      color: _ink)),
                                              IconButton(
                                                  tooltip: '안내 닫기',
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  icon: const Icon(Icons.close,
                                                      color: _ink))
                                            ]),
                                        const SizedBox(height: 8),
                                        const Text('내 주변의 이야기를\n발견해보세요',
                                            style: TextStyle(
                                                fontSize: 23,
                                                height: 1.25,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -.7,
                                                color: _ink)),
                                        const SizedBox(height: 10),
                                        const Text(
                                            '현재 위치를 기준으로 가까운 장소의\n여행 이야기를 모아 보여드려요.',
                                            style: TextStyle(
                                                fontSize: 14,
                                                height: 1.4,
                                                color: _muted)),
                                        const SizedBox(height: 8),
                                        const _NearbyExample(),
                                        const SizedBox(height: 8),
                                        Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                                color: const Color(0xfff5f4f4),
                                                borderRadius:
                                                    BorderRadius.circular(14)),
                                            child: const Row(children: [
                                              Icon(Icons.location_on_outlined,
                                                  size: 20, color: _muted),
                                              SizedBox(width: 8),
                                              Expanded(
                                                  child: Text(
                                                      '위치 권한이 필요할 수 있어요.\n허용하지 않아도 최근·인기 이야기는 볼 수 있어요.',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          height: 1.5,
                                                          color: _muted)))
                                            ])),
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

class _NearbyExample extends StatelessWidget {
  const _NearbyExample();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: const Color(0xfff5f4f4),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        ExcludeSemantics(
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                    width: 82,
                    height: 84,
                    child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                            width: 235,
                            height: 195,
                            child: ClipRect(
                                child: Stack(children: [
                              Positioned(
                                  left: -153,
                                  top: -1010,
                                  width: 893,
                                  height: 1761,
                                  child: Image.asset(
                                      'assets/images/nearby_guide_reference.png',
                                      fit: BoxFit.fill))
                            ]))))))),
        const SizedBox(width: 12),
        const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('골목 속 작은 카페',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff222222))),
          SizedBox(height: 6),
          Text('산책하다 발견한 조용한 공간',
              style: TextStyle(
                  fontSize: 11, height: 1.4, color: Color(0xff808089))),
          SizedBox(height: 6),
          Row(children: [
            Icon(Icons.location_on_outlined,
                size: 15, color: Color(0xff808089)),
            SizedBox(width: 4),
            Text('내 주변 이야기 · 예시',
                style: TextStyle(fontSize: 10, color: Color(0xff808089)))
          ])
        ])),
      ]));
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
