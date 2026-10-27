import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertrip/models/markers/marker_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/design/app_design.dart';
import 'package:fluttertrip/models/schedule/schedule_model.dart';
import 'package:fluttertrip/views/schedule/schedule_view.dart';
import 'package:fluttertrip/widgets/navigation/tripnest_navigation.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      httpClient: MockClient((request) async => http.Response(
          request.url.path.endsWith('/user_markers')
              ? '{"title":"테스트 브런치 카페","address":"서울","keyword":"카페","snippet":""}'
              : '[]',
          200, headers: {'content-type': 'application/json'}, request: request)),
      authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false, detectSessionInUri: false),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets(
      'Compact navigation matches the four reference destinations and opens schedule',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!),
      routes: {
        '/schedule': (_) => const Scaffold(body: Text('schedule destination'))
      },
      home: const Scaffold(
          bottomNavigationBar: TripNestNavigation(currentRoute: '/home')),
    ));
    for (final label in ['홈', '지도', '일정', 'MY']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('리스트'), findsNothing);
    expect(find.text('공유 링크'), findsNothing);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('일정'));
    await tester.pumpAndSettle();
    expect(find.text('schedule destination'), findsOneWidget);
  });

  testWidgets('Schedule editor rejects an empty title before saving',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppDesign.lightTheme,
        home: ScheduleEditView(date: DateTime(2026, 9, 28))));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('일정 제목을 입력해주세요.'), findsOneWidget);
    expect(find.text('처리 중…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('List schedule previews all places on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppDesign.lightTheme,
      home: ScheduleEditView(date: DateTime(2026, 10, 13), initialTitle: '제주 여행',
        initialPlaces: List.generate(3, (i) => MarkerModel(id: '$i', title: '방문 장소 $i',
          address: '제주특별자치도 제주시 주소 $i', keyword: '카페', lat: 33, lng: 126,
          markerImagePath: '')))));
    expect(find.text('제주 여행'), findsOneWidget);
    expect(find.text('3개 일정 추가'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('방문 장소 2'), 150,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    expect(find.text('13:00–14:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Date and both time pickers use Korean labels', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppDesign.lightTheme,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ScheduleEditView(date: DateTime(2026, 10, 13))));
    for (final field in ['날짜', '시작 시간', '종료 시간']) {
      await tester.ensureVisible(find.text(field));
      await tester.tap(find.text(field));
      await tester.pumpAndSettle();
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      if (field != '날짜') {
        expect(find.text('오전'), findsOneWidget);
        expect(find.text('오후'), findsOneWidget);
      }
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Existing schedule shows its title, times and participant count',
      (tester) async {
    final schedule = ScheduleModel(
        id: 'schedule',
        userId: 'user',
        title: '토요일 브런치',
        startTime: DateTime(2026, 9, 28, 11),
        endTime: DateTime(2026, 9, 28, 13),
        colorValue: 0xFF222222,
        placeId: 'place',
        collaboratorIds: ['a', 'b', 'c']);
    await tester.pumpWidget(MaterialApp(
        theme: AppDesign.lightTheme,
        home:
            ScheduleEditView(date: DateTime(2026, 9, 28), schedule: schedule)));
    expect(find.text('토요일 브런치'), findsOneWidget);
    expect(find.text('11:00'), findsOneWidget);
    expect(find.text('9월 28일 13:00'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('3명'), 150,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    expect(find.text('테스트 브런치 카페'), findsOneWidget);
    expect(find.text('3명'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
