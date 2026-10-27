import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/design/app_design.dart';
import 'package:fluttertrip/widgets/common/app_overlays.dart';

void main() {
  testWidgets('Long choice sheets scroll, expose selection, and return a value',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? selected;
    await tester.pumpWidget(MaterialApp(
        theme: AppDesign.lightTheme,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  child: const Text('열기'),
                  onPressed: () async {
                    selected = await showAppSheet<int>(
                        context: context,
                        builder: (sheet) => AppSheet(
                              title: '저장한 장소 선택',
                              subtitle: '일정에 연결할 장소를 선택해주세요.',
                              children: List.generate(
                                  30,
                                  (i) => AppSheetOption(
                                      title: '여행 장소 $i',
                                      subtitle: '긴 주소도 여러 줄로 자연스럽게 표시합니다.',
                                      selected: i == 0,
                                      onTap: () => Navigator.pop(sheet, i))),
                            ));
                  },
                )))));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('닫기'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.scrollUntilVisible(find.text('여행 장소 29'), 250,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('여행 장소 29'));
    await tester.pumpAndSettle();
    expect(selected, 29);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Input dialog validates and stays usable with keyboard and large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    String? name;
    await tester.pumpWidget(MaterialApp(
        theme: AppDesign.lightTheme,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    child: const Text('열기'),
                    onPressed: () async => name = await showDialog<String>(
                        context: context,
                        builder: (_) => const AppTextInputDialog(
                            title: '새 리스트 만들기',
                            hint: '이름을 입력해주세요',
                            submitLabel: '만들기')))))));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();
    expect(find.text('이름을 입력해주세요'), findsWidgets);
    await tester.enterText(find.byType(TextFormField), '  부산 여행  ');
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();
    expect(name, '부산 여행');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Confirmation cancellation and confirm return distinct results',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
        theme: AppDesign.lightTheme,
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    child: const Text('열기'),
                    onPressed: () async => result = await showDialog<bool>(
                        context: context,
                        builder: (_) => const AppConfirmDialog(
                            title: '삭제할까요?',
                            message: '삭제 후 복구할 수 없습니다.',
                            destructive: true,
                            confirmLabel: '삭제',
                            icon: Icons.delete_outline)))))));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(result, false);
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(tester.takeException(), isNull);
  });
}
