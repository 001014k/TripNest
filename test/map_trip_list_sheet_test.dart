import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/widgets/map/map_trip_list_sheet.dart';
import 'package:fluttertrip/widgets/common/reference_design.dart';

void main() {
  testWidgets('Counts the owner once and unique invited members', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MapTripListSheet(
      lists: [{
        'id': 'list', 'name': '함께 여행', 'user_id': 'owner',
        'list_bookmarks': [],
        'list_members': [
          {'user_id': 'owner'}, {'user_id': 'friend'}, {'user_id': 'friend'},
        ],
      }],
      selectedListId: null, onSelect: (_) {}, onReset: () {},
    ))));
    expect(tester.widget<ReferencePeople>(find.byType(ReferencePeople)).count, 2);
  });

  testWidgets(
      'List picker scrolls many lists and preserves select and reset actions',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selected;
    var reset = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Align(
                alignment: Alignment.bottomCenter,
                child: MapTripListSheet(
                    lists: List.generate(
                        20,
                        (i) => {
                              'id': '$i',
                              'name': '여행 리스트 $i',
                              'list_bookmarks': [],
                              'list_members': []
                            }),
                    selectedListId: '0',
                    onSelect: (id) => selected = id,
                    onReset: () => reset = true)))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('경로 시작').first);
    expect(selected, '0');
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('초기화 · 전체 장소 보기'));
    expect(reset, isTrue);
  });
}
