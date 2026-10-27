import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/widgets/map/route_order_sheet.dart';
void main() {
  testWidgets('Route sheet supports map, start and dismissible guidance on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320,740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var starts = 0;
    var maps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RouteOrderSheet(places: const [RouteOrderPlace(id: 'one', title: '오르다 카페', address: '제주특별자치도 제주시 한림읍 협재로 19-1', keyword: '카페'),RouteOrderPlace(id: 'two', title: '협재해변', address: '제주시 한림읍', keyword: '관광지')], controller: controller, onReorder: (_, __) {}, onPlace: (_) {}, onMap: () => maps++, onBack: () {}, onStart: () => starts++))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('지도에서 보기'));
    await tester.tap(find.text('경로 시작하기'));
    await tester.tap(find.byTooltip('안내 닫기'));
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(maps, 1);
    expect(find.text('드래그하여 순서 변경'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
