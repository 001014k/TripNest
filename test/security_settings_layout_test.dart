import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/views/profile/security_settings_view.dart';

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

  for (final scale in [1.0, 1.6]) {
    testWidgets('Security layout fits with text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: const SecuritySettingsView()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('로그인 및 보안'), findsOneWidget);
      expect(find.text('미연결'), findsNWidgets(3));
      expect(find.text('로그인 계정 0개 연결됨'), findsOneWidget);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('공용 기기에서는 로그아웃해 주세요.'), findsOneWidget);
    });
  }
}
