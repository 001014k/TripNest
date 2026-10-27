import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fluttertrip/views/markers/markercreationscreen_view.dart';
import 'package:fluttertrip/viewmodels/markers/markercreationscreen_viewmodel.dart';

class FakeCreationModel extends MarkerCreationScreenViewModel {
  @override
  Future<void> fetchUserLists() async {}
  @override
  List<Map<String, dynamic>> get lists => [
        {'id': 'list-1', 'name': '서울 여행', 'list_bookmarks': <dynamic>[]}
      ];
}

void main() {
  testWidgets(
      'Three steps preserve edits and return the selected category and list',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map<String, dynamic>? result;
    await tester
        .pumpWidget(ChangeNotifierProvider<MarkerCreationScreenViewModel>(
      create: (_) => FakeCreationModel(),
      child: MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        result = await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MarkerCreationScreen(
                                    initialLatLng: LatLng(37.5, 127),
                                    initialTitle: '테스트 장소',
                                    initialAddress: '서울 성동구')));
                      },
                      child: const Text('열기'))))),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '수정한 장소');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('카테고리 선택'), findsOneWidget);
    await tester.tap(find.text('다음'));
    await tester.pump();
    expect(find.text('카테고리를 선택해주세요.'), findsOneWidget);
    await tester.tap(find.text('카페'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('저장할 리스트 선택'), findsOneWidget);
    await tester.tap(find.text('서울 여행'));
    await tester.tap(find.text('기본 정보'));
    await tester.pumpAndSettle();
    expect(find.text('수정한 장소'), findsOneWidget);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '저장하기'));
    await tester.pumpAndSettle();
    expect(result?['title'], '수정한 장소');
    expect(result?['keyword'], '카페');
    expect(result?['listId'], 'list-1');
    expect(result?['address'], '서울 성동구');
    expect(tester.takeException(), isNull);
  });
}
