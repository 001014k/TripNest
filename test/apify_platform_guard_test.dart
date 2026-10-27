import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/services/shared_links/apify_service.dart';

void main() {
  test('Non-Instagram URLs fail before any Apify network request', () async {
    final service = ApifyService();
    for (final url in [
      'https://blog.naver.com/trip/123',
      'https://m.blog.naver.com/PostView.naver?logNo=123',
      'https://naver.me/example',
      'https://trip.tistory.com/1',
      'https://instagram.com.evil.test/p/123',
      'https://instagram.com@blog.naver.com/trip/123',
    ]) {
      await expectLater(service.fetchInstagramData(instagramUrl: url),
          throwsA(isA<FormatException>()));
    }
  });
}
