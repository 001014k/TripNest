import 'dart:io';
import 'package:flutter/services.dart';
import 'package:fluttertrip/views/lists/list_collaboration_view.dart';
import 'package:fluttertrip/viewmodels/lists/collaborator_viewmodel.dart';
import 'package:fluttertrip/viewmodels/lists/list_viewmodel.dart';
import 'package:fluttertrip/models/lists/collaborator_model.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/views/friends/friend_management_view.dart';
import 'package:fluttertrip/viewmodels/friends/friend_management_viewmodel.dart';

class FakeFriends extends FriendManagementViewModel {
  String? sent;
  String? accepted;
  @override
  String get currentUserId => 'test-user';
  @override
  Future<List<Map<String, dynamic>>> getFriendsList() async => [
        {'id': 'one', 'nickname': '지은'},
        {'id': 'two', 'nickname': '민수'},
      ];
  @override
  Future<List<Map<String, dynamic>>> getReceivedFriendRequests() async =>
      accepted == null
          ? [
              {
                'requester_id': 'three',
                'requester': {'nickname': '서연'}
              }
            ]
          : [];
  @override
  Future<String> sendFriendRequest(String nickname) async {
    sent = nickname;
    return '친구 요청이 전송되었습니다.';
  }

  @override
  Future<String> acceptFriendRequest(String id) async {
    accepted = id;
    return '친구 요청을 수락했습니다.';
  }
}

class FakeCollaborators extends CollaboratorViewModel {
  @override
  String? get listOwnerId => 'owner';
  @override
  String? get listOwnerNickname => '나';
  @override
  bool get isCurrentUserOwner => true;
  @override
  List<Collaborator> get collaborators =>
      [Collaborator(userId: 'member', nickname: '길이가 긴 친구 이름', role: 'editor')];
  @override
  List<Map<String, String>> get friends => [
        {'id': 'friend', 'nickname': '민수'}
      ];
  @override
  Future<void> loadListOwner(String id) async {}
  @override
  Future<void> getCollaborators(String id) async {}
  @override
  Future<void> getFriends(String id) async {}
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    final fontFile = File('/System/Library/Fonts/Supplemental/AppleGothic.ttf');
    if (fontFile.existsSync()) {
      await (FontLoader('SocialKorean')
            ..addFont(
                Future.value(ByteData.sublistView(fontFile.readAsBytesSync()))))
          .load();
    }
    await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-key',
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false));
  });
  testWidgets(
      'friend search, favorites and request acceptance preserve actions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = FakeFriends()..onlineUserIds = {'one'};
    final boundary = GlobalKey();
    await tester.pumpWidget(
        ChangeNotifierProvider<FriendManagementViewModel>.value(
            value: vm,
            child: MaterialApp(
                theme: ThemeData(fontFamily: 'SocialKorean'),
                home: RepaintBoundary(
                    key: boundary, child: const FriendManagementView()))));
    await tester.pumpAndSettle();
    expect(find.text('전체 친구  2'), findsOneWidget);
    final output = Platform.environment['SOCIAL_PREVIEW_PATH'];
    if (output != null) {
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.enterText(find.byType(TextField), '민수');
    await tester.pumpAndSettle();
    expect(find.text('지은'), findsNothing);
    expect(find.widgetWithText(ListTile, '민수'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('즐겨찾기 추가'));
    await tester.pumpAndSettle();
    expect(
        (await SharedPreferences.getInstance())
            .getStringList('favorite_friends_test-user'),
        ['two']);
    await tester.tap(find.text('받은 요청  1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수락'));
    await tester.pumpAndSettle();
    expect(vm.accepted, 'three');
    expect(find.text('받은 친구 요청이 없어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('add friend submits trimmed nickname on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = FakeFriends();
    await tester.pumpWidget(
        ChangeNotifierProvider<FriendManagementViewModel>.value(
            value: vm, child: const MaterialApp(home: FriendAddView())));
    await tester.enterText(find.byType(TextField), ' 지은 ');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '친구 요청 보내기'));
    await tester.pumpAndSettle();
    expect(vm.sent, '지은');
    expect(find.text('친구 요청이 전송되었습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('collaboration members and invite tabs fit a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<CollaboratorViewModel>(
              create: (_) => FakeCollaborators()),
          ChangeNotifierProvider<ListViewModel>(create: (_) => ListViewModel()),
        ],
        child: MaterialApp(
            theme: ThemeData(fontFamily: 'SocialKorean'),
            home: const ListCollaborationView(listId: 'list'))));
    await tester.pumpAndSettle();
    expect(find.text('리스트 소유자'), findsOneWidget);
    expect(find.text('편집자'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('친구 초대'));
    await tester.pumpAndSettle();
    expect(find.text('민수'), findsOneWidget);
    expect(find.text('초대'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
