import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/views/planner/chat_recommendation_view.dart';

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

  for (final width in [375.0, 390.0]) {
    testWidgets('Planner cards and keyboard fit at $width', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester
          .pumpWidget(const MaterialApp(home: ChatRecommendationScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('AI 여행 플래너'), findsOneWidget);
      final left = tester.getTopLeft(find.ancestor(of: find.text('근처 명소'), matching: find.byType(InkWell)));
      final right = tester.getTopLeft(find.ancestor(of: find.text('테마 여행'), matching: find.byType(InkWell)));
      expect(left.dy, right.dy);
      expect(right.dx, greaterThan(left.dx));
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '서울 카페');
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getBottomRight(find.byTooltip('메시지 보내기')).dy,
          lessThanOrEqualTo(524));
    });
  }
}
