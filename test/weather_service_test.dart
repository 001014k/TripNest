import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fluttertrip/services/weather/weather_service.dart';
import 'package:fluttertrip/widgets/home/home_weather_card.dart';

http.Response response(List<Map<String, dynamic>> rows) => http.Response(
    jsonEncode({
      'response': {
        'header': {'resultCode': '00'},
        'body': {
          'items': {'item': rows}
        }
      }
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  test('Week merges short and mid forecasts using announcement date offsets',
      () async {
    final service = WeatherService(
        apiKey: 'test',
        midApiKey: 'mid-test',
        clock: () => DateTime.utc(2026, 10, 9, 16),
        client: MockClient((request) async {
          if (request.url.path.endsWith('getMidLandFcst')) {
            expect(request.url.queryParameters['serviceKey'], 'mid-test');
            expect(request.url.queryParameters['tmFc'], '202610091800');
            return response([
              {'wf5Am': '맑음', 'wf5Pm': '구름많음', 'rnSt5Am': 10, 'rnSt5Pm': 30}
            ]);
          }
          if (request.url.path.endsWith('getMidTa')) {
            return response([
              {'taMin5': 12, 'taMax5': 23}
            ]);
          }
          return response([
            {
              'fcstDate': '20261010',
              'fcstTime': '1200',
              'category': 'SKY',
              'fcstValue': '1'
            },
            {
              'fcstDate': '20261010',
              'fcstTime': '0600',
              'category': 'TMN',
              'fcstValue': '14'
            },
            {
              'fcstDate': '20261010',
              'fcstTime': '1500',
              'category': 'TMX',
              'fcstValue': '25'
            },
          ]);
        }));
    final week = await service.loadWeek(37.5665, 126.978);
    expect(week.days.length, 8);
    expect(week.days.first.date, DateTime.utc(2026, 10, 10));
    expect(week.days.last.date, DateTime.utc(2026, 10, 17));
    expect(week.days.first.high, 25);
    expect(week.days[4].condition, '맑음 / 구름많음');
    expect(week.days[4].low, 12);
    expect(week.days[4].rainProbability, 30);
    service.dispose();
  });
  test('Denied mid forecast keeps real short forecast and missing days',
      () async {
    final service = WeatherService(
        apiKey: 'test',
        midApiKey: 'mid-test',
        clock: () => DateTime.utc(2026, 10, 10, 4),
        client: MockClient((request) async {
          if (request.url.path.contains('MidFcstInfoService')) {
            return http.Response('Forbidden', 403);
          }
          return response([
            {
              'fcstDate': '20261010',
              'fcstTime': '1200',
              'category': 'SKY',
              'fcstValue': '1'
            }
          ]);
        }));
    final week = await service.loadWeek(37.5665, 126.978);
    expect(week.days.first.condition, '맑음');
    expect(week.days.last.condition, isNull);
    expect(week.days.last.high, isNull);
    expect(week.notice, isNotNull);
    service.dispose();
  });
  test('Grid matches Seoul and Busan weather stations', () {
    expect(WeatherService.grid(37.5665, 126.978), (60, 127));
    expect(WeatherService.grid(35.1796, 129.0756), (98, 76));
  });
  test('KST midnight rollover, encoded key, weather parsing and caching',
      () async {
    var calls = 0;
    final service = WeatherService(
        apiKey: 'test%2Bkey%3D',
        clock: () => DateTime.utc(2026, 10, 9, 15, 20),
        client: MockClient((request) async {
          calls++;
          expect(request.url.queryParameters['serviceKey'], 'test+key=');
          expect(request.url.queryParameters['base_date'], '20261009');
          expect(request.url.queryParameters['base_time'], '2300');
          if (request.url.path.endsWith('getUltraSrtNcst')) {
            return response([
              {'category': 'T1H', 'obsrValue': '22.5'},
              {'category': 'PTY', 'obsrValue': '0'}
            ]);
          }
          return response([
            {
              'category': 'SKY',
              'fcstDate': '20261010',
              'fcstTime': '0000',
              'fcstValue': '1'
            },
            {
              'category': 'TMN',
              'fcstDate': '20261010',
              'fcstTime': '0600',
              'fcstValue': '15'
            },
            {
              'category': 'TMX',
              'fcstDate': '20261010',
              'fcstTime': '1500',
              'fcstValue': '24'
            },
            {
              'category': 'TMX',
              'fcstDate': '20261011',
              'fcstTime': '1500',
              'fcstValue': '99'
            },
          ]);
        }));
    final data = await service.load(37.5665, 126.978);
    expect(data.temperature, 22.5);
    expect(data.high, 24);
    expect(data.low, 15);
    expect(data.condition, '맑음');
    await service.load(37.5665, 126.978);
    expect(calls, 2);
    service.dispose();
  });
  test('Forecast failure preserves observation without invented high or low',
      () async {
    final service = WeatherService(
        apiKey: 'test',
        midApiKey: 'mid-test',
        client: MockClient((request) async {
          if (request.url.path.endsWith('getUltraSrtNcst')) {
            return response([
              {'category': 'T1H', 'obsrValue': '7'},
              {'category': 'PTY', 'obsrValue': '3'}
            ]);
          }
          return http.Response('unavailable', 503);
        }));
    final data = await service.load(37.5665, 126.978);
    expect(data.condition, '눈');
    expect(data.high, isNull);
    expect(data.low, isNull);
    service.dispose();
  });
  test('Authentication failure is surfaced', () async {
    final service = WeatherService(
        apiKey: 'test',
        midApiKey: 'mid-test',
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'response': {
                'header': {'resultCode': '30'}
              }
            }),
            200)));
    await expectLater(
        service.load(37.5665, 126.978), throwsA(isA<WeatherException>()));
    service.dispose();
  });
  testWidgets(
      'Weather card remains usable on narrow screens and has retry and region controls',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retried = false, picked = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(20),
                child: WeatherCardContent(
                    region: '서울 · 기본 지역',
                    weather: WeatherData(
                        temperature: 22,
                        precipitation: 0,
                        sky: 1,
                        high: 24,
                        low: 15,
                        observedAt: DateTime.utc(2026, 10, 10, 10)),
                    loading: false,
                    error: '날씨 서버에 연결하지 못했어요.',
                    onRegion: () => picked = true,
                    onRetry: () => retried = true)))));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('재시도'));
    expect(retried, isTrue);
    await tester.tap(find.text('서울 · 기본 지역'));
    expect(picked, isTrue);
  });
  testWidgets('Weather card visual preview', (tester) async {
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    final font = File('/System/Library/Fonts/Supplemental/AppleGothic.ttf');
    if (font.existsSync()) {
      await (FontLoader('ReferenceKorean')
            ..addFont(
                Future.value(ByteData.sublistView(font.readAsBytesSync()))))
          .load();
    }
    tester.view.physicalSize = const Size(390, 210);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'ReferenceKorean'),
        home: RepaintBoundary(
            key: const Key('weather'),
            child: Scaffold(
                body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: WeatherCardContent(
                        region: '서울',
                        weather: WeatherData(
                            temperature: 22,
                            precipitation: 0,
                            sky: 1,
                            high: 24,
                            low: 15,
                            observedAt: DateTime.utc(2026, 10, 10, 10)),
                        loading: false,
                        error: null,
                        onRegion: () {},
                        onRetry: () {}))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(find.byKey(const Key('weather')),
        matchesGoldenFile('goldens/home_weather.png'));
  });
}
