import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/models/weather/weather_forecast.dart';
import 'package:fluttertrip/widgets/weather/weather_forecast_sheet.dart';

WeeklyWeather forecast(String condition) =>
    WeeklyWeather(midRegion: '서울', days: [
      ForecastDay(
          date: DateTime(2026, 10, 10),
          condition: condition,
          low: 12,
          high: 22),
    ]);

void main() {
  testWidgets(
      'Refresh loads new forecast without returning a Future from setState',
      (tester) async {
    final pending = Completer<WeeklyWeather>();
    final requests = <bool>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WeatherForecastSheet(
                region: '서울',
                load: (force) {
                  requests.add(force);
                  return force ? pending.future : Future.value(forecast('맑음'));
                }))));
    await tester.pumpAndSettle();
    expect(find.text('맑음'), findsOneWidget);
    await tester.tap(find.byTooltip('새로고침'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(requests, [false, true]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(forecast('흐림'));
    await tester.pumpAndSettle();
    expect(find.text('흐림'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retry recovers from a failed forecast request', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WeatherForecastSheet(
                region: '서울',
                load: (force) {
                  return force
                      ? Future.value(forecast('맑음'))
                      : Future.error(Exception('offline'));
                }))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('예보를 불러오지 못했어요 · 재시도'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('맑음'), findsOneWidget);
  });
}
