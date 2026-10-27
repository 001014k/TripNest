import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:fluttertrip/services/weather/weather_service.dart';
import 'package:fluttertrip/viewmodels/home/home_weather_viewmodel.dart';
import 'package:fluttertrip/widgets/home/home_weather_card.dart';

void main() {
  testWidgets(
      'Home recreation keeps region and weather without another request; '
      'expired cache refreshes in place and failures preserve data',
      (tester) async {
    var now = DateTime.utc(2026, 10, 12, 4);
    var calls = 0;
    var temperature = 22;
    var fail = false;
    Completer<void>? pending;
    final model = HomeWeatherViewModel(
        service: WeatherService(
      apiKey: 'test',
      clock: () => now,
      client: MockClient((request) async {
        calls++;
        if (pending != null) await pending.future;
        if (fail) return http.Response('unavailable', 503);
        return http.Response(
            jsonEncode({
              'response': {
                'header': {'resultCode': '00'},
                'body': {
                  'items': {
                    'item': request.url.path.endsWith('getUltraSrtNcst')
                        ? [
                            {'category': 'T1H', 'obsrValue': '$temperature'},
                            {'category': 'PTY', 'obsrValue': '0'}
                          ]
                        : <Map<String, dynamic>>[]
                  }
                }
              }
            }),
            200);
      }),
    ));
    addTearDown(model.dispose);
    await model.selectRegion('부산', 35.1796, 129.0756);
    final initialCalls = calls;
    Widget home() => ChangeNotifierProvider.value(
          value: model,
          child: const MaterialApp(home: Scaffold(body: HomeWeatherCard())),
        );
    await tester.pumpWidget(home());
    await tester.pumpAndSettle();
    expect(find.text('22°'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(home());
    expect(find.text('부산'), findsOneWidget);
    expect(find.text('22°'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();
    expect(calls, initialCalls);

    now = now.add(const Duration(minutes: 21));
    pending = Completer<void>();
    temperature = 25;
    final refresh = model.reload();
    await model.reload(); // A concurrent lifecycle refresh must be coalesced.
    await tester.pump();
    expect(calls, initialCalls * 2);
    expect(find.text('22°'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    pending.complete();
    await tester.runAsync(() => refresh);
    await tester.pumpAndSettle();
    expect(find.text('25°'), findsOneWidget);

    pending = null;
    fail = true;
    now = now.add(const Duration(minutes: 21));
    await tester.runAsync(() => model.reload());
    await tester.pumpAndSettle();
    expect(find.text('25°'), findsOneWidget);
    expect(find.text('재시도'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
