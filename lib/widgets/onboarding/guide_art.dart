import 'package:flutter/material.dart';

/// 오프라인에서도 표시되며 레이아웃에 맞춰 크기가 변하는 가벼운 삽화입니다.
class GuideArt extends StatelessWidget {
  const GuideArt({super.key, this.page = 0, this.compact = false});
  final int page;
  final bool compact;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
            height: compact ? 155 : 290,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                  width: compact ? 180 : 260,
                  height: compact ? 120 : 240,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F2),
                      borderRadius: BorderRadius.circular(36)),
                  child: Icon(Icons.map_outlined,
                      size: compact ? 100 : 180,
                      color: const Color(0xFFD2D4D8))),
              Icon(
                  page == 2
                      ? Icons.people_alt_outlined
                      : page == 1
                          ? Icons.link
                          : Icons.location_on_outlined,
                  size: compact ? 52 : 64,
                  color: const Color(0xFF222222)),
              if (!compact) ...[
                Positioned(
                    top: 12,
                    right: 18,
                    child: Transform.rotate(
                        angle: .09,
                        child: _card(
                            page == 1
                                ? Icons.link_rounded
                                : Icons.bookmark_border_rounded,
                            page == 1 ? '후기 속 장소' : '가고 싶은 곳',
                            '나만의 여행에 저장'))),
                Positioned(
                    bottom: 12,
                    left: 16,
                    child: Transform.rotate(
                        angle: -.08,
                        child: _card(
                            page == 2
                                ? Icons.people_outline
                                : Icons.coffee_outlined,
                            page == 2 ? '함께 만드는 여행' : '골목 속 작은 카페',
                            '새로운 여행의 시작'))),
              ],
            ])),
      );
  Widget _card(IconData icon, String title, String subtitle) => Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, 7))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              height: 78,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: const Color(0xFFF2F0EC),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 32, color: const Color(0xFF67676C))),
          const SizedBox(height: 9),
          Text(title,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF77777D))),
        ]),
      );
}
