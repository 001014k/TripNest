import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/widgets/community/story_place_preview.dart';
void main() {
  testWidgets('All four actions stay on one line at 320px with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(1.5)), child: Scaffold(body: Padding(padding: const EdgeInsets.all(20), child: Row(children: [for (final label in ['128', '24', '저장하기', '공유하기']) Expanded(child: StoryActionButton(icon: Icons.favorite_border, label: label, onPressed: () => taps++))]))))));
    final actions = find.byType(StoryActionButton);
    final y = tester.getCenter(actions.at(0)).dy;
    for (var i = 0; i < 4; i++) { expect(tester.getCenter(actions.at(i)).dy, y); await tester.tap(actions.at(i)); }
    expect(taps, 4);
    expect(tester.takeException(), isNull);
  });
}
