import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fluttertrip/services/shared_links/shared_link_platform.dart';
import 'package:fluttertrip/services/shared_links/threads_place_extractor_service.dart';

void main() {
  const url = 'https://www.threads.net/@travel/post/ABC?x=1';
  test('Threads domains and post validation', () {
    expect(SharedLinkPlatform.detect(url), 'Threads');
    expect(SharedLinkPlatform.detect('https://threads.com/@travel/post/ABC'),
        'Threads');
    expect(
        SharedLinkPlatform.detect(
            'https://threads.com.evil.test/@travel/post/ABC'),
        '기타');
    expect(ThreadsPlaceExtractorService.postUri(url).toString(),
        'https://www.threads.com/@travel/post/ABC');
    for (final invalid in [
      'https://threads.com/@travel',
      'https://threads.com@evil.test/@travel/post/ABC',
      'https://instagram.com/p/ABC'
    ]) {
      expect(() => ThreadsPlaceExtractorService.postUri(invalid),
          throwsFormatException);
    }
  });
  test('Includes root and author continuation, excludes others and duplicates',
      () {
    final text = ThreadsPlaceExtractorService.authorText(url, [
      {'code': 'ABC', 'username': 'travel', 'text': '서울숲'},
      {
        'code': 'DEF',
        'username': 'travel',
        'text': '북촌',
        'isReply': true,
        'replyToAuthor': 'travel'
      },
      {
        'code': 'GHI',
        'username': 'other',
        'text': '광고 장소',
        'isReply': true,
        'replyToAuthor': 'travel'
      },
      {'code': 'XYZ', 'username': 'travel', 'text': '무관한 글', 'isReply': false},
      {
        'code': 'DEF',
        'username': 'travel',
        'text': '북촌',
        'isReply': true,
        'replyToAuthor': 'travel'
      },
    ]);
    expect(text, '서울숲\n\n북촌');
  });
  test('Missing or textless original fails instead of extracting comments', () {
    expect(() => ThreadsPlaceExtractorService.authorText(url, []),
        throwsFormatException);
    expect(
        () => ThreadsPlaceExtractorService.authorText(url, [
              {'code': 'ABC', 'text': ''}
            ]),
        throwsFormatException);
  });
  test('Calls Threads actor and reads completed dataset', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.method == 'POST') {
        expect(request.url.path, '/v2/acts/memo23~threads-scraper/runs');
        final body = jsonDecode(request.body);
        expect(body['postUrls'], ['https://www.threads.com/@travel/post/ABC']);
        expect(body['includeReplies'], true);
        return http.Response(
            jsonEncode({
              'data': {'id': 'run', 'defaultDatasetId': 'dataset'}
            }),
            201);
      }
      if (request.url.path.contains('actor-runs')) {
        return http.Response('{"data":{"status":"SUCCEEDED"}}', 200);
      }
      return http.Response('[{"code":"ABC","text":"post"}]', 200);
    });
    final rows =
        await ThreadsPlaceExtractorService(client: client, token: 'test')
            .fetch(url);
    expect(rows.single['code'], 'ABC');
    expect(paths.length, 3);
    client.close();
  });
  test('App share URL resolves before actor request and author matching',
      () async {
    const shared = 'https://www.threads.com/share/_--JZCgqq/';
    const canonical =
        'https://www.threads.com/@coffeelog_korea/post/De6cWV8kVb8';
    var actorCalled = false;
    final client = MockClient((request) async {
      if (request.url.host == 'www.threads.com') {
        expect(request.method, 'HEAD');
        expect(request.followRedirects, false);
        expect(request.headers.containsKey('Authorization'), false);
        return http.Response('', 302,
            headers: {'location': '$canonical?xmt=tracking'});
      }
      if (request.method == 'POST') {
        actorCalled = true;
        expect(jsonDecode(request.body)['postUrls'], [canonical]);
        return http.Response(
            '{"data":{"id":"run","defaultDatasetId":"dataset"}}', 201);
      }
      if (request.url.path.contains('actor-runs')) {
        return http.Response('{"data":{"status":"SUCCEEDED"}}', 200);
      }
      return http.Response(
          jsonEncode([
            {'code': 'De6cWV8kVb8', 'text': '서울숲'}
          ]),
          200, headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final service = ThreadsPlaceExtractorService(client: client, token: 'test');
    final resolved = await service.resolvePostUri(shared);
    final rows = await service.fetch(shared);
    expect(actorCalled, true);
    expect(ThreadsPlaceExtractorService.authorText(resolved.toString(), rows),
        '서울숲');
    client.close();
  });
  test('Redirects outside Threads and redirect loops are rejected', () async {
    for (final target in ['https://evil.test/post/ABC', '/share/loop/']) {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.url.host, 'www.threads.com');
        return http.Response('', 302, headers: {'location': target});
      });
      await expectLater(
          ThreadsPlaceExtractorService(client: client)
              .resolvePostUri('https://www.threads.com/share/test/'),
          throwsFormatException);
      expect(calls, lessThanOrEqualTo(5));
      client.close();
    }
  });
  test('Failed actor produces actionable error', () async {
    final client = MockClient((request) async => http.Response(
        request.method == 'POST'
            ? '{"data":{"id":"run","defaultDatasetId":"dataset"}}'
            : '{"data":{"status":"FAILED"}}',
        200));
    await expectLater(
        ThreadsPlaceExtractorService(client: client, token: 'test').fetch(url),
        throwsFormatException);
    client.close();
  });
}
