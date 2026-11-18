import 'package:flutter/material.dart';

class AppPhotoHero extends StatelessWidget {
  const AppPhotoHero({super.key, required this.tag, required this.child});
  final Object? tag;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (tag == null || MediaQuery.disableAnimationsOf(context)) return child;
    return Hero(
      tag: tag!,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (context, animation, direction, from, to) {
        // 화면 전환 애니메이션에는 이미 표시된 썸네일을 사용합니다.
        // 새로 로딩 중인 상세 화면의 임시 이미지를 대신 이동시키지 않습니다.
        final hero = (direction == HeroFlightDirection.push
            ? from.widget
            : to.widget) as Hero;
        return Material(type: MaterialType.transparency, child: hero.child);
      },
      child: child,
    );
  }
}
