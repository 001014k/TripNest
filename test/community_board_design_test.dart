import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertrip/views/community/community_post_detail_view.dart';
import 'package:fluttertrip/models/community/community_post_model.dart';
import 'package:fluttertrip/design/app_design.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/views/community/community_board_view.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final font = File('/System/Library/Fonts/AppleSDGothicNeo.ttc');
    if (font.existsSync()) {
      final loader = FontLoader('StoryKorean')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false, detectSessionInUri: false),
      httpClient: MockClient((request) async => http.Response(
          jsonEncode([
            {
              'id': 'post',
              'author_id': 'author',
              'title': '산책하기 좋은 곳',
              'content': '조용하게 산책하기 좋은 곳이에요.',
              'place_title': '서울숲',
              'place_address': '서울 성동구',
              'destination': '서울',
              'created_at': '2026-10-12T00:00:00Z',
              'profiles': {'nickname': '아주 긴 이름을 사용하는 여행자'},
              'travel_post_likes': [
                {'count': 12}
              ],
              'travel_post_comments': [
                {'count': 3}
              ],
            }
          ]),
          200,
          request: request,
          headers: {'content-type': 'application/json; charset=utf-8'})),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets('Story tabs filter posts and popular uses a photo grid',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        theme: AppDesign.lightTheme.copyWith(
            textTheme: AppDesign.lightTheme.textTheme
                .apply(fontFamily: 'StoryKorean')),
        home: RepaintBoundary(key: key, child: const CommunityBoardView())));
    await tester.pumpAndSettle();
    final output = Platform.environment['STORY_PREVIEW_PATH'];
    if (output != null) {
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.tap(find.text('인기'));
    await tester.pumpAndSettle();
    expect(find.byType(SliverGrid), findsOneWidget);
    expect(find.text('서울숲'), findsOneWidget);
    expect(find.text('팔로잉'), findsNothing);
    expect(find.text('내 주변'), findsOneWidget);
    await tester.tap(find.text('최근'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제주도'));
    await tester.pumpAndSettle();
    expect(find.text('이 주제의 이야기가 아직 없어요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Marker share detail fits narrow screens and large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppDesign.lightTheme,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        home: CommunityPostDetailView(
            post: CommunityPost(
                id: 'post',
                title: '서울숲',
                content: '산책하기 좋은 조용한 장소입니다.',
                destination: '서울',
                authorId: 'author',
                authorNickname: '아주 긴 이름을 사용하는 여행자',
                createdAt: DateTime(2026, 10, 13),
                placeTitle: '서울숲 산책하기 좋은 장소',
                placeAddress: '서울특별시 성동구 뚝섬로 273',
                placeCategory: '공원'))));
    await tester.pumpAndSettle();
    expect(find.text('TRAVEL JOURNAL'), findsNothing);
    expect(find.text('팔로우'), findsNothing);
    await tester.scrollUntilVisible(find.text('산책하기 좋은 조용한 장소입니다.'), 150,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    expect(find.text('서울숲 산책하기 좋은 장소'), findsWidgets);
    await tester.scrollUntilVisible(find.byTooltip('댓글 등록'), 150, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    expect(find.byTooltip('댓글 등록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact story feed and composer fit narrow screens',
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
      home: const CommunityBoardView(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('서울숲'), findsOneWidget);
    expect(find.text('TRAVEL JOURNAL'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('12'), 120,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('3'), findsOneWidget);
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.text('로그인 후 좋아요를 누를 수 있습니다.'), findsOneWidget);
    await tester.tap(find.text('장소 공유'));
    await tester.pumpAndSettle();
    expect(find.text('공유할 마커가 없습니다. 먼저 지도에서 장소를 저장해주세요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
