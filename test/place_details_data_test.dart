import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fluttertrip/services/places/place_hours.dart';
import 'package:fluttertrip/services/places/places_service.dart';

void main() {
  test('Opening hours use Sunday zero and hour/minute fields', () {
    final hours = <String, dynamic>{
      'periods': [
        {
          'open': {'day': 0, 'hour': 9, 'minute': 30},
          'close': {'day': 0, 'hour': 18}
        },
        {
          'open': {'day': 6, 'hour': 22},
          'close': {'day': 0, 'hour': 2}
        }
      ]
    };
    expect(PlaceHours.forDay(hours, 0), '09:30 - 18:00');
    expect(PlaceHours.forDay(hours, 6), '22:00 - 다음날 02:00');
    expect(PlaceHours.forDay(hours, 1), '휴무');
    expect(
        PlaceHours.forDay({
          'periods': [
            {
              'open': {'day': 0, 'hour': 0}
            }
          ]
        }, 3),
        '24시간 영업');
  });
  test(
      'Localized weekday descriptions are matched by day rather than array order',
      () {
    final hours = <String, dynamic>{
      'weekdayDescriptions': [
        '일요일: 휴무',
        '토요일: 오전 11:00 ~ 오후 10:00',
        'Monday: 9:00 AM – 5:00 PM'
      ]
    };
    expect(PlaceHours.forDay(hours, 6), '오전 11:00 ~ 오후 10:00');
    expect(PlaceHours.forDay(hours, 1), '9:00 AM – 5:00 PM');
  });
  test('Place Details requests and returns rating, review count and hours',
      () async {
    final service = PlacesService(
        apiKey: 'test',
        client: MockClient((request) async {
          if (request.method == 'POST')
            return http.Response(
                jsonEncode({
                  'places': [
                    {'id': 'fixture'}
                  ]
                }),
                200);
          expect(request.url.queryParameters['fields'],
              contains('userRatingCount'));
          expect(request.url.queryParameters['languageCode'], 'ko');
          return http.Response(
              jsonEncode({
                'rating': 4.5,
                'userRatingCount': 123,
                'regularOpeningHours': {'openNow': true}
              }),
              200);
        }));
    final data = await service.searchPlaceDetails('장소');
    expect(data?['rating'], 4.5);
    expect(data?['userRatingCount'], 123);
    expect(data?['regularOpeningHours'], isNotNull);
  });
  test('API denial is not disguised as missing place data', () async {
    final service = PlacesService(
        apiKey: 'test',
        client: MockClient((_) async => http.Response('{}', 403)));
    await expectLater(service.searchPlaceDetails('장소'),
        throwsA(isA<PlacesLookupException>()));
  });
}
