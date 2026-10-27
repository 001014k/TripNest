import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fluttertrip/services/shared_links/portal_place_extractor_service.dart';
import 'package:fluttertrip/services/shared_links/shared_link_platform.dart';
import 'package:fluttertrip/models/shared_links/instagram_place_source_model.dart';
import 'package:fluttertrip/models/shared_links/link_place_preview_model.dart';

void main() {
  test('Recognizes portal short links without accepting lookalike domains', () {
    expect(SharedLinkPlatform.detect('https://naver.me/test'), 'Naver');
    expect(SharedLinkPlatform.detect('https://maps.app.goo.gl/test'),
        'Google Maps');
    expect(SharedLinkPlatform.detect('https://www.google.co.kr/search?q=park'),
        'Google');
    expect(SharedLinkPlatform.detect('https://kko.to/test'), 'Kakao');
    expect(SharedLinkPlatform.detect('https://map.daum.net/test'), 'Daum');
    expect(SharedLinkPlatform.detect('https://naver.com.evil.test'), '기타');
  });
  test(
      'Resolves short links, extracts multiple places, rejects hallucinations and deduplicates',
      () async {
    final visited = <String>[];
    final client = MockClient((request) async {
      visited.add(request.url.toString());
      if (request.url.host == 'naver.me') {
        return http.Response('', 302,
            headers: {'location': 'https://blog.naver.com/trip/123'});
      }
      return http.Response(
          '<html><main>서울숲 서울 성동구 뚝섬로 273\n북서울꿈의숲 서울 강북구</main><script>광고</script></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'});
    });
    final extractor = PortalPlaceExtractorService(
        client: client,
        extractSources: (text) async {
          expect(text, contains('서울숲'));
          expect(text, isNot(contains('광고')));
          return [
            const InstagramPlaceSource(name: '서울숲'),
            const InstagramPlaceSource(name: '북서울꿈의숲'),
            const InstagramPlaceSource(name: '서울숲'),
            const InstagramPlaceSource(name: '없는 장소')
          ];
        },
        search: (query) async => [
              LinkPlacePreview(
                  url: '',
                  title: query,
                  address: '서울 $query 주소',
                  latitude: 37,
                  longitude: 127)
            ]);
    final result = await extractor.extract('https://naver.me/test');
    expect(visited.last, 'https://m.blog.naver.com/trip/123');
    expect(result.length, 2);
    expect(result.every((p) => p.url == 'https://naver.me/test'), isTrue);
    client.close();
  });
  test('Map and search links are excluded, review articles are supported', () {
    for (final url in [
      'https://place.map.kakao.com/123',
      'https://maps.app.goo.gl/test',
      'https://www.google.com/search?q=서울숲',
      'https://map.naver.com/p/123'
    ]) {
      expect(SharedLinkPlatform.supportsPlaces(url), isFalse);
      expect(SharedLinkPlatform.isExcludedPortal(url), isTrue);
    }
    for (final url in [
      'https://cafe.naver.com/trip/123',
      'https://cafe.daum.net/trip/abc/123',
      'https://trip.blogspot.com/2026/review.html',
      'https://trip.tistory.com/123'
    ]) {
      expect(SharedLinkPlatform.supportsPlaces(url), isTrue);
    }
    expect(
        SharedLinkPlatform.detect('https://instagram.com/p/test'), 'Instagram');
  });
  test('Blocked pages report failure without saving a guessed place', () async {
    final client = MockClient((_) async => http.Response('', 403));
    await expectLater(
        PortalPlaceExtractorService(
                client: client,
                extractSources: (_) async =>
                    throw StateError('AI must not run'))
            .extract('https://cafe.naver.com/trip/123'),
        throwsFormatException);
    client.close();
  });
  test('Cafe frame reads article before navigation and rejects other districts',
      () async {
    final client = MockClient((request) async {
      if (request.url.path == '/trip/1') {
        return http.Response(
            '<iframe id="cafe_main" src="/ArticleRead.nhn?id=1"></iframe>',
            200);
      }
      return http.Response(
          '<main>메뉴</main><div class="se-main-container">${' ' * 19000}맛집 서울 성동구</div>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'});
    });
    final service = PortalPlaceExtractorService(
        client: client,
        extractSources: (text) async {
          expect(text, contains('맛집 서울 성동구'));
          expect(text, isNot(contains('메뉴')));
          return [const InstagramPlaceSource(name: '맛집', address: '서울 성동구')];
        },
        search: (_) async => [
              LinkPlacePreview(
                  url: '',
                  title: '맛집',
                  address: '서울 용산구',
                  latitude: 37,
                  longitude: 127),
              LinkPlacePreview(
                  url: '',
                  title: '맛집',
                  address: '서울 성동구',
                  latitude: 37.5,
                  longitude: 127),
            ]);
    final results = await service.extract('https://cafe.naver.com/trip/1');
    expect(results.single.address, '서울 성동구');
    client.close();
  });
  test('Redirect loops fail', () async {
    final client = MockClient((_) async =>
        http.Response('', 302, headers: {'location': 'https://naver.me/loop'}));
    await expectLater(
        PortalPlaceExtractorService(client: client)
            .extract('https://naver.me/loop'),
        throwsFormatException);
    client.close();
  });
}
