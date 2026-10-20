import '../navigation/app_tab_shell.dart';
import 'reference_design.dart';
import 'package:flutter/material.dart';

/// Shared navigation keeps each destination's existing screen and actions.
class TripNestNavigation extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String>? onSelect;
  const TripNestNavigation({super.key, required this.currentRoute, this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (AppTabVisibility.maybeOf(context) != null) return const SizedBox.shrink();
    const items = [
      ('/home', Icons.home_outlined, '홈'),
      ('/map', Icons.map_outlined, '지도'),
      ('/schedule', Icons.calendar_today_outlined, '일정'),
      ('/community', Icons.forum_outlined, '이야기'),
      ('/profile', Icons.person_outline_rounded, 'MY'),
    ];
    return Material(
        color: Colors.white,
        child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEF)))),
              child: Row(
                  children: items
                      .map((item) => Expanded(
                              child: InkWell(
                            onTap: item.$1 == currentRoute
                                ? null
                                : () {
                                    if (onSelect != null) {
                                      FocusScope.of(context).unfocus();
                                      onSelect!(item.$1);
                                    } else {
                                      AppTabController.open(context, item.$1);
                                    }
                                  },
                            child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 6, bottom: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        item.$1 == currentRoute &&
                                                item.$1 == '/home'
                                            ? Icons.home_rounded
                                            : item.$2,
                                        size: 25,
                                        color: item.$1 == currentRoute
                                            ? const Color(0xFF202020)
                                            : const Color(0xFF89898D)),
                                    const SizedBox(height: 3),
                                    Text(item.$3,
                                        style: TextStyle(
                                            fontSize: 11,
                                            height: 1.2,
                                            color: item.$1 == currentRoute
                                                ? const Color(0xFF202020)
                                                : const Color(0xFF89898D))),
                                  ],
                                )),
                          )))
                      .toList()),
            )));
  }
}

class TripNestHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final Widget? trailing;
  const TripNestHeader({super.key, this.onBack, this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
        if (onBack != null)
          IconButton(
              tooltip: '뒤로',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20))
        else
          const Padding(padding: EdgeInsets.all(10), child: ReferenceLogo()),
        if (onBack != null) ...[
          const ReferenceLogo(),
          const SizedBox(width: 10)
        ],
        const Expanded(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('TripNest',
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF202020),
                        letterSpacing: -0.8)))),
        trailing ??
            IconButton(
                tooltip: '알림 설정',
                onPressed: () =>
                    Navigator.pushNamed(context, '/notification_settings'),
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Color(0xFF202020))),
      ]);
}
