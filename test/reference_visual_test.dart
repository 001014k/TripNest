import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fluttertrip/views/markers/markerdetail_view.dart';
import 'package:fluttertrip/viewmodels/markers/markerdetail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/models/lists/list_model.dart';
import 'package:fluttertrip/models/schedule/schedule_model.dart';
import 'package:fluttertrip/views/schedule/schedule_view.dart';
import 'package:fluttertrip/viewmodels/lists/list_viewmodel.dart';
import 'package:fluttertrip/views/lists/list_view.dart';
import 'package:fluttertrip/widgets/common/reference_design.dart';
import 'package:fluttertrip/widgets/navigation/tripnest_navigation.dart';

class FixtureLists extends ListViewModel {
  FixtureLists() {
    lists = [
      ListModel(
          id: '1',
          name: '강남 여행 리스트',
          createdAt: DateTime(2026),
          markerCount: 12,
          collaboratorCount: 3,
          isOwner: true),
      ListModel(
          id: '2',
          name: '성수 카페 투어',
          createdAt: DateTime(2026),
          markerCount: 8,
          collaboratorCount: 3),
      ListModel(
          id: '3',
          name: '주말 전시 코스',
          createdAt: DateTime(2026),
          markerCount: 5,
          collaboratorCount: 2,
          isOwner: true),
    ];
  }
  @override
  Future<void> loadLists() async {}
}

class FixtureDetail extends MarkerDetailViewModel {
  FixtureDetail(super.marker) {
    savedLists = [
      {'id': 'list-1', 'name': '강남 여행 리스트'}
    ];
  }
  @override
  Future<void> fetchUserMarkerDetail(String markerId) async {}
  @override
  Future<List<String>> fetchPhotos(String address, String? title) async => [];
  @override
  String get title => '다운타우너 강남';
  @override
  String get address => '서울 강남구 강남대로 102길 15';
  @override
  String get keyword => '맛집';
  @override
  String get region => '서울 강남구';
  @override
  String get memo => '수제버거와 감자튀김이 맛있는 인기 맛집';
  @override
  List<String> get tags => ['수제버거', '감자튀김', '브런치', '데이트'];
  @override
  String get businessHours => '매일 11:00 - 22:00';
  @override
  double get rating => 4.5;
  @override
  int get reviewCount => 1234;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-key',
        authOptions: const FlutterAuthClientOptions(
            autoRefreshToken: false, detectSessionInUri: false));
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    final fontFile = File('/System/Library/Fonts/Supplemental/AppleGothic.ttf');
    if (fontFile.existsSync()) {
      await (FontLoader('ReferenceKorean')
            ..addFont(
                Future.value(ByteData.sublistView(fontFile.readAsBytesSync()))))
          .load();
    }
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets(
      'Marker detail has reference sections and retains navigation actions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
            fontFamily: 'ReferenceKorean',
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF222222))),
        home: RepaintBoundary(
            key: const Key('detail-screen'),
            child: MarkerDetailView(
                marker: const Marker(
                    markerId: MarkerId('fixture'), position: LatLng(37.5, 127)),
                keyword: '맛집',
                viewModelFactory: FixtureDetail.new))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('저장된 리스트'), findsOneWidget);
    expect(find.text('강남 여행 리스트'), findsOneWidget);
    expect(find.text('방문자 리뷰'), findsOneWidget);
    await expectLater(find.byKey(const Key('detail-screen')),
        matchesGoldenFile('goldens/reference_marker_detail.png'));
    await tester.tap(find.text('길찾기'));
    await tester.pumpAndSettle();
    expect(find.text('어디로 안내할까요?'), findsOneWidget);
    Navigator.of(tester.element(find.text('어디로 안내할까요?'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장된 리스트'));
    await tester.pumpAndSettle();
    expect(find.text('강남 여행 리스트'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Marker detail fits a narrow phone with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!),
        home: MarkerDetailView(
            marker: const Marker(
                markerId: MarkerId('fixture'), position: LatLng(37.5, 127)),
            keyword: '맛집',
            viewModelFactory: FixtureDetail.new)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('List layout and ownership filters at reference phone width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider<ListViewModel>(
        create: (_) => FixtureLists(),
        child: MaterialApp(
          theme: ThemeData(
              fontFamily: 'ReferenceKorean',
              useMaterial3: true,
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF222222))),
          home:
              const RepaintBoundary(key: Key('list-screen'), child: ListPage()),
        )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(find.byKey(const Key('list-screen')),
        matchesGoldenFile('goldens/reference_list.png'));
    await tester.tap(find.text('내 리스트'));
    await tester.pumpAndSettle();
    expect(find.text('성수 카페 투어'), findsNothing);
    expect(find.text('강남 여행 리스트'), findsOneWidget);
    await tester.tap(find.text('공유 리스트'));
    await tester.pumpAndSettle();
    expect(find.text('강남 여행 리스트'), findsNothing);
    expect(find.text('성수 카페 투어'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Calendar renders Korean month, selected day and event markers',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DateTime? nextMonth;
    DateTime? selected;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'ReferenceKorean'),
        home: RepaintBoundary(
            key: const Key('calendar-screen'),
            child: Scaffold(
              backgroundColor: const Color(0xFFFAFAFA),
              bottomNavigationBar:
                  const TripNestNavigation(currentRoute: '/schedule'),
              body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TripNestHeader(),
                        const SizedBox(height: 24),
                        const Text('일정',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text('여행의 소중한 순간들을 일정으로 계획해보세요.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 18),
                        ReferenceCalendar(
                            month: DateTime(2025, 4),
                            selected: DateTime(2025, 4, 12),
                            eventDays: const {10, 12, 14, 18, 26},
                            onSelected: (value) => selected = value,
                            onMonthChanged: (value) => nextMonth = value),
                      ])),
            ))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(find.byKey(const Key('calendar-screen')),
        matchesGoldenFile('goldens/reference_calendar.png'));
    await tester.tap(find.text('12'));
    expect(selected, DateTime(2025, 4, 12));
    await tester.tap(find.byTooltip('다음 달'));
    expect(nextMonth, DateTime(2025, 5));
  });
  testWidgets('Schedule editor matches card layout without overflow at 390px',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'ReferenceKorean', useMaterial3: true),
        home: RepaintBoundary(
            key: const Key('editor-screen'),
            child: ScheduleEditView(
                date: DateTime(2025, 4, 12),
                schedule: ScheduleModel(
                    id: 'test',
                    userId: 'test',
                    title: '토요일 브런치',
                    startTime: DateTime(2025, 4, 12, 11),
                    endTime: DateTime(2025, 4, 12, 13),
                    colorValue: 0xFF222222,
                    collaboratorIds: ['a', 'b', 'c'])))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(find.byKey(const Key('editor-screen')),
        matchesGoldenFile('goldens/reference_editor.png'));
  });

  testWidgets('List fits 320px with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider<ListViewModel>(
        create: (_) => FixtureLists(),
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!),
            home: const ListPage())));
    await tester.pumpAndSettle();
  });
}
