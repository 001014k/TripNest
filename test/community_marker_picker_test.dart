import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/models/community/community_post_model.dart';
import 'package:fluttertrip/widgets/community/community_marker_picker.dart';

void main() {
  testWidgets('Search, category and single selection return the chosen marker', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    CommunityMarker? result;
    const markers = [CommunityMarker(id: 'cafe', title: '바다 카페', address: '제주', category: '카페'), CommunityMarker(id: 'food', title: '서울 식당', address: '서울', category: '맛집')];
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () async { result = await showModalBottomSheet<CommunityMarker>(context: context, isScrollControlled: true, builder: (_) => const CommunityMarkerPicker(markers: markers)); }, child: const Text('선택'))))));
    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.tap(find.text('음식점'));
    await tester.pumpAndSettle();
    expect(find.text('바다 카페'), findsNothing);
    await tester.tap(find.text('전체'));
    await tester.enterText(find.byType(TextField), '제주');
    await tester.pumpAndSettle();
    expect(find.text('서울 식당'), findsNothing);
    await tester.tap(find.text('바다 카페'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 마커로 공유하기 (1)'));
    await tester.pumpAndSettle();
    expect(result?.id, 'cafe');
    expect(tester.takeException(), isNull);
  });
}
