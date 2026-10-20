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
        // Keep the already-visible thumbnail during flight, rather than flying
        // a newly loading detail placeholder across the screen.
        final hero = (direction == HeroFlightDirection.push
            ? from.widget
            : to.widget) as Hero;
        return Material(type: MaterialType.transparency, child: hero.child);
      },
      child: child,
    );
  }
}
