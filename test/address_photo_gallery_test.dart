import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fluttertrip/services/places/address_photo_preview_service.dart';

void main() {
  test('Gallery selects matching place and returns at most five unique photos', () async {
    final service = AddressPhotoPreviewService(client: MockClient((request) async {
      expect(jsonDecode(request.body)['textQuery'], '테스트 공원, 서울 성동구');
      return http.Response(jsonEncode({'places': [
        {'displayName': {'text': '다른 장소'}, 'formattedAddress': '부산',
          'photos': [{'name': 'wrong'}]},
        {'displayName': {'text': '테스트 공원'}, 'formattedAddress': '서울 성동구',
          'photos': [for (var i = 0; i < 7; i++) {'name': 'places/test/photos/$i'}]},
      ]}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    final photos = await service.loadPhotos('서울 성동구', '테스트 공원');
    expect(photos, hasLength(5));
    expect(photos.first, contains('places/test/photos/0/media'));
    expect(photos.last, contains('places/test/photos/4/media'));
  });

  test('Empty photos and empty queries return no gallery images', () async {
    var calls = 0;
    final service = AddressPhotoPreviewService(client: MockClient((_) async {
      calls++;
      return http.Response('{"places": []}', 200);
    }));
    expect(await service.loadPhotos('', null), isEmpty);
    expect(calls, 0);
    expect(await service.loadPhotos('서울', '공원'), isEmpty);
    expect(calls, 1);
  });
}
