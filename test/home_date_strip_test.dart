import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/widgets/home/home_date_strip.dart';

void main() {
  testWidgets(
      'Home date strip selects dates across month boundary and opens picker',
      (tester) async {
    DateTime? selected;
    int? pickedMonth;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 320,
                child: HomeDateStrip(
                    start: DateTime(2026, 10, 30),
                    selected: DateTime(2026, 10, 30),
                    onSelect: (date) => selected = date,
                    onPickMonth: (month) => pickedMonth = month)))));
    await tester.tap(find.text('31'));
    expect(selected, DateTime(2026, 10, 31));
    await tester.tap(find.text('1'));
    expect(selected, DateTime(2026, 11, 1));
    await tester.tap(find.text('10월'));
    await tester.pumpAndSettle();
    expect(find.text('1월'), findsOneWidget);
    await tester.tap(find.text('2월'));
    await tester.pumpAndSettle();
    expect(pickedMonth, 2);
    await tester.drag(find.byType(ListView), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
