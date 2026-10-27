import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/widgets/home/home_skeleton.dart';

void main() {
  testWidgets('Home placeholders fit narrow screens with reduced motion', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(size: Size(320, 800), disableAnimations: true),
      child: Scaffold(body: ListView(children: const [
        Padding(padding: EdgeInsets.all(20), child: HomeSkeleton()),
        HomePhotoSkeletons(),
      ])),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
