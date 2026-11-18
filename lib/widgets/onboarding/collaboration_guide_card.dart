import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 멤버 역할을 예시로 보여주며, 버튼을 누르면 실제 리스트 관리 메뉴를 엽니다.
class CollaborationGuideCard extends StatelessWidget {
  const CollaborationGuideCard(
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
                      child: const Text('리스트 관리에서 협업자 관리를 선택해요',
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
                                        const Text('친구를 초대하고\n역할을 나눠보세요',
                                            style: TextStyle(
                                                fontSize: 23,
                                                height: 1.25,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -.7,
                                                color: _ink)),
                                        const SizedBox(height: 10),
                                        const Text(
                                            '리스트 관리(⋮) → 협업자 관리에서\n친구를 초대하고 역할을 정해보세요.',
                                            style: TextStyle(
                                                fontSize: 14,
                                                height: 1.4,
                                                color: _muted)),
                                        const SizedBox(height: 8),
                                        const _MemberExample(),
                                        const SizedBox(height: 8),
                                        const Text('리스트 관리 → 협업자 관리 → 친구 초대',
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

class _MemberExample extends StatelessWidget {
  const _MemberExample();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xfff5f4f3),
          borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        for (var i = 0; i < 2; i++) ...[
          if (i == 1) const Divider(height: 22, color: Color(0xffdddddf)),
          Row(children: [
            ExcludeSemantics(
                child: ClipOval(
                    child: SizedBox(
                        width: 40,
                        height: 40,
                        child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                                width: 88,
                                height: 88,
                                child: ClipRect(
                                    child: Stack(children: [
                                  Positioned(
                                      left: -143,
                                      top: i == 0 ? -1114 : -1242,
                                      width: 880,
                                      height: 1788,
                                      child: Image.asset(
                                          'assets/images/collaboration_guide_reference.png',
                                          fit: BoxFit.fill))
                                ]))))))),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(i == 0 ? '지은' : '민수',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff222222))),
                  const SizedBox(height: 3),
                  Text(i == 0 ? '장소 추가·삭제 가능' : '리스트 읽기 전용',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xff808089))),
                ])),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                    color: i == 0 ? const Color(0xff222222) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xff77777d))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(i == 0 ? '편집자' : '게스트',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              i == 0 ? Colors.white : const Color(0xff222222))),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down,
                      size: 16,
                      color: i == 0 ? Colors.white : const Color(0xff222222))
                ])),
          ]),
        ],
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
