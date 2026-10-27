import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/widgets/community/nearby_location_notice.dart';

void main() {
  testWidgets('Location recovery fits large text and opens settings instructions', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retries = 0;
    await tester.pumpWidget(MaterialApp(home: MediaQuery(data: const MediaQueryData(size: Size(320,740), textScaler: TextScaler.linear(1.5)), child: Scaffold(body: NearbyLocationNotice(onRetry: () => retries++)))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('다시 시도하기'), 150);
    await tester.tap(find.text('다시 시도하기'));
    expect(retries, 1);
    await tester.scrollUntilVisible(find.text('위치 설정 방법 보기'), 100);
    await tester.tap(find.text('위치 설정 방법 보기'));
    await tester.pumpAndSettle();
    expect(find.text('위치 설정 열기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
