import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum AppMotion { detail, editor, fade }

/// Material route semantics and Cupertino's interactive back gesture are retained.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute(
      {required super.builder,
      super.settings,
      this.motion = AppMotion.detail,
      super.fullscreenDialog});
  final AppMotion motion;

  @override
  Duration get transitionDuration => Duration(
          milliseconds: switch (motion) {
        AppMotion.detail => 280,
        AppMotion.editor => 260,
        AppMotion.fade => 220,
      });
  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    if (motion == AppMotion.detail) {
      return const CupertinoPageTransitionsBuilder().buildTransitions<T>(
          this, context, animation, secondaryAnimation, child);
    }
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curved,
      child: motion == AppMotion.editor
          ? SlideTransition(
              position: curved
                  .drive(Tween(begin: const Offset(0, .06), end: Offset.zero)),
              child: child)
          : child,
    );
  }
}
