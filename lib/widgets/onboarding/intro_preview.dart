import 'package:flutter/material.dart';

/// Offline editorial previews; only the illustration region is displayed.
/// Headings, navigation and progress remain native, accessible widgets.
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
