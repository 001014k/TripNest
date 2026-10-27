import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/widgets/map/map_keyword_sheet.dart';

void main() {
  testWidgets(
      'Keyword selection stays pending until done and supports multiple or all',
      (tester) async {
    final original = <String>{'카페'};
    Set<String>? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await showModalBottomSheet<Set<String>>(
                          context: context,
                          builder: (_) => MapKeywordSheet(keywords: const {
                                '카페': Icons.coffee,
                                '음식점': Icons.restaurant
                              }, selected: original));
                    },
                    child: const Text('열기'))))));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '맛집'));
    await tester.pumpAndSettle();
    expect(original, {'카페'});
    expect(result, isNull);
    await tester.tap(find.text('2개 선택 · 완료'));
    await tester.pumpAndSettle();
    expect(result, {'카페', '음식점'});
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '전체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전체 보기 · 완료'));
    await tester.pumpAndSettle();
    expect(result, isEmpty);
  });
}
