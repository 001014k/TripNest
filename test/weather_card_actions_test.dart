import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/widgets/home/home_weather_card.dart';

void main() {
  testWidgets(
      'Weekly forecast has a visible button separate from region selection',
      (tester) async {
    var regionTaps = 0;
    var forecastTaps = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WeatherCardContent(
      region: '서울',
      weather: null,
      loading: false,
      error: null,
      onRegion: () => regionTaps++,
      onForecast: () => forecastTaps++,
      onRetry: () {},
    ))));
    expect(find.widgetWithText(TextButton, '주간 예보'), findsOneWidget);
    await tester.tap(find.text('주간 예보'));
    expect(forecastTaps, 1);
    expect(regionTaps, 0);
    await tester.tap(find.text('서울'));
    expect(regionTaps, 1);
    expect(forecastTaps, 1);
    expect(tester.takeException(), isNull);
  });
}
