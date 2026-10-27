import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/services/shared_links/apify_service.dart';

void main() {
  test('Restricted responses produce actionable errors; captions still work', () {
    expect(() => ApifyService.validateInstagramResults([
      {'error': 'restricted_page', 'restricted_age': 13, 'failure_reason': 'MA'}
    ]), throwsA(isA<InstagramAccessException>().having((e) => e.message, 'message', contains('연령 제한'))));
    expect(() => ApifyService.validateInstagramResults([{'caption': '여행 장소'}]), returnsNormally);
    expect(() => ApifyService.validateInstagramResults([]), returnsNormally);
  });
}
