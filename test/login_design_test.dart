import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/views/auth/login_option_view.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false, detectSessionInUri: false),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets(
      'Login layout, password visibility, validation and recovery navigation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = File('/System/Library/Fonts/Supplemental/AppleGothic.ttf');
    if (font.existsSync()) {
      await (FontLoader('LoginPreview')
            ..addFont(
                Future.value(ByteData.sublistView(font.readAsBytesSync()))))
          .load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'LoginPreview', useMaterial3: true),
      routes: {
        '/forgot_password': (_) => const Scaffold(body: Text('비밀번호 복구 화면'))
      },
      home: const RepaintBoundary(
          key: Key('login-preview'), child: CombinedLoginView()),
    ));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(CombinedLoginView));
      for (final asset in ['assets/images/login_seoul.png', 'assets/google_signin_button.png', 'assets/kakao_icon.png']) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('login-preview')));
    await tester.runAsync(() async {
      final rendered = await boundary.toImage();
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/tripnest-login-preview.png').writeAsBytes(bytes!.buffer.asUint8List());
      rendered.dispose();
    });
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue);
    await tester.tap(find.byTooltip('비밀번호 표시'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse);
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();
    expect(find.text('이메일과 비밀번호를 입력하세요.'), findsOneWidget);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('비밀번호 찾기'));
    await tester.tap(find.text('비밀번호 찾기'));
    await tester.pumpAndSettle();
    expect(find.text('비밀번호 복구 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
