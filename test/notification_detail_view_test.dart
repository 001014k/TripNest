import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/views/notifications/notification_detail_view.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ko');
    await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey: 'test',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/lists')) {
            return http.Response(
                jsonEncode([
                  {'id': 'list', 'name': '테스트 여행'}
                ]),
                200,
                request: request,
                headers: {'content-type': 'application/json; charset=utf-8'});
          }
          if (request.url.path.endsWith('/list_bookmarks')) {
            return http.Response('[]', 200,
                request: request,
                headers: {'content-type': 'application/json; charset=utf-8'});
          }
          return http.Response('null', 200,
              request: request,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }),
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false));
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<void> show(
      WidgetTester tester, String type, Map<String, dynamic> data) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: NotificationDetailView(item: {
      'type': type,
      'title': '알림 제목',
      'body': '리스트의 장소 순서가 변경됐어요.',
      'data': data,
    })));
    await tester.pumpAndSettle();
  }

  testWidgets('list update shows change and list action', (tester) async {
    await show(
        tester, 'list_update', {'list_id': 'list', 'change': 'reordered'});
    expect(find.text('변경 내용'), findsOneWidget);
    expect(find.text('테스트 여행'), findsOneWidget);
    expect(find.text('리스트 확인하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing place disables place navigation', (tester) async {
    await show(tester, 'list_marker_added', {});
    expect(find.text('장소가 삭제되었거나 접근할 수 없어요.'), findsOneWidget);
    final button = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '장소 자세히 보기'));
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unavailable friend request cannot be accepted', (tester) async {
    await show(tester, 'friend_request', {});
    expect(find.text('프로필 보기'), findsOneWidget);
    expect(find.text('수락하기'), findsNothing);
    expect(find.text('현재 처리할 수 없는 요청이에요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
