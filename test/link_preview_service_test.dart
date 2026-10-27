import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fluttertrip/services/shared_links/link_preview_service.dart';

void main() {
  test('Desktop Naver post loads mobile title and image, preserving post query',
      () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'm.blog.naver.com');
      expect(request.url.queryParameters['logNo'], '224446324014');
      return http.Response(
          '<meta property="og:title" content="경주 글램핑 후기">'
          '<meta property="og:image" content="https://blogthumb.pstatic.net/photo.jpg?type=w2">',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'});
    });
    final result = await LinkPreviewService(client: client).load(
        'https://blog.naver.com/PostView.naver?blogId=dsa45788&logNo=224446324014');
    expect(result.title, '경주 글램핑 후기');
    expect(result.image, 'https://blogthumb.pstatic.net/photo.jpg?type=w2');
    client.close();
  });
  test('Other platforms keep their URL and resolve relative images', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'www.instagram.com');
      return http.Response(
          '<meta property="og:image" content="/photo.jpg">', 200);
    });
    expect(
        (await LinkPreviewService(client: client)
                .load('https://www.instagram.com/p/test'))
            .image,
        'https://www.instagram.com/photo.jpg');
    client.close();
  });
  test('Actual emulator blog image can be downloaded', () async {
    final result = await const LinkPreviewService()
        .load('https://blog.naver.com/dsa45788/224446324014');
    expect(result.title, contains('글램핑'));
    expect(result.image, isNotNull);
    final response = await http.get(Uri.parse(result.image!));
    expect(response.statusCode, 200);
    expect(response.headers['content-type'], startsWith('image/'));
    expect(response.bodyBytes.length, greaterThan(1000));
  }, skip: !const bool.fromEnvironment('LIVE_PREVIEW_TEST'));
}
