import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../design/app_design.dart';

/// 대화를 별도 경로로 구성해 iOS 뒤로가기 제스처와 Android 시스템 뒤로가기를 지원합니다.
class PlannerSessionNavigator extends StatefulWidget {
  const PlannerSessionNavigator(
      {super.key,
      this.navigatorKey,
      required this.home,
      required this.chat,
      required this.onLeaveChat});
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget home;
  final Widget? chat;
  final VoidCallback onLeaveChat;

  @override
  State<PlannerSessionNavigator> createState() =>
      _PlannerSessionNavigatorState();
}

class _PlannerSessionNavigatorState extends State<PlannerSessionNavigator> {
  final _fallbackNavigator = GlobalKey<NavigatorState>();
  GlobalKey<NavigatorState> get _navigator =>
      widget.navigatorKey ?? _fallbackNavigator;

  @override
  Widget build(BuildContext context) => NavigatorPopHandler<Object?>(
        onPopWithResult: (result) => _navigator.currentState?.pop(result),
        child: Navigator(
          key: _navigator,
          pages: [
            MaterialPage<void>(
                key: const ValueKey('planner-home'), child: widget.home),
            if (widget.chat != null)
              CupertinoPage<void>(
                key: const ValueKey('planner-chat'),
                child:
                    ColoredBox(color: AppDesign.primaryBg, child: widget.chat!),
              ),
          ],
          onDidRemovePage: (page) {
            if (page.key == const ValueKey('planner-chat') &&
                widget.chat != null) {
              FocusScope.of(context).unfocus();
              widget.onLeaveChat();
            }
          },
        ),
      );
}
