import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/widgets/community/community_feed_skeleton.dart';

void main() {
  testWidgets('Feed skeleton matches each tab and respects reduced motion', (tester) async {
    for (final width in [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      for (final tab in [0, 1, 2]) {
        await tester.pumpWidget(MaterialApp(home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800), disableAnimations: true),
          child: Scaffold(body: CommunityFeedSkeleton(key: ValueKey(tab), tab: tab)),
        )));
        await tester.pumpAndSettle();
        expect(find.byType(tab == 1 ? SliverGrid : SliverList), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
