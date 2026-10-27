import 'package:provider/provider.dart';
import '../../viewmodels/friends/friend_management_viewmodel.dart';
import '../../navigation/app_tab_shell.dart';
import '../common/reference_design.dart';
import 'package:flutter/material.dart';

/// Shared navigation keeps each destination's existing screen and actions.
class TripNestNavigation extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String>? onSelect;
  const TripNestNavigation(
      {super.key, required this.currentRoute, this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (AppTabVisibility.maybeOf(context) != null)
      return const SizedBox.shrink();
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
                tooltip: '알림',
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Color(0xFF202020))),
      ]);
}

/// Matching friend and notification actions for main screens except the map.
class TripNestSocialActions extends StatelessWidget {
  const TripNestSocialActions({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<FriendManagementViewModel>(
            builder: (context, friends, _) => IconButton(
              tooltip: friends.pendingRequestCount > 0
                  ? '친구 요청 ${friends.pendingRequestCount}개'
                  : '친구',
              onPressed: () async {
                await Navigator.pushNamed(context, '/friend_management');
                await friends.refreshPendingRequestCount();
              },
              icon: Badge.count(
                count: friends.pendingRequestCount,
                isLabelVisible: friends.pendingRequestCount > 0,
                backgroundColor: const Color(0xFFE5484D),
                textColor: Colors.white,
                child: const Icon(Icons.people_outline_rounded,
                    color: Color(0xFF202020)),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '알림',
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: const Icon(Icons.notifications_none_rounded,
                color: Color(0xFF202020)),
          ),
        ],
      );
}
