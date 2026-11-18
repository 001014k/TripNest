import 'package:flutter/material.dart';

/// 오프라인 미리보기에서 삽화 영역만 표시합니다.
/// 제목, 탐색 및 진행 상태는 접근성을 지원하는 기본 위젯으로 유지합니다.
class IntroPreview extends StatelessWidget {
  const IntroPreview({super.key, required this.page});
  final int page;
  static const _regions = [
    Rect.fromLTWH(35, 110, 445, 530),
    Rect.fromLTWH(530, 125, 420, 515),
    Rect.fromLTWH(1010, 125, 423, 515),
  ];

  @override
  Widget build(BuildContext context) {
    final region = _regions[page];
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: region.width,
          height: region.height,
          child: ClipRect(
            child: Stack(children: [
              Positioned(
                left: -region.left,
                top: -region.top,
                width: 1475,
                height: 1066,
                child: Image.asset('assets/images/onboarding_reference.png',
                    fit: BoxFit.fill, filterQuality: FilterQuality.high),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
