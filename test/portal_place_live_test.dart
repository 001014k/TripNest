// ignore_for_file: avoid_print
// Opt-in integration test: uses live public pages and configured API credentials.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/services/shared_links/portal_place_extractor_service.dart';

void main() {
  const enabled = bool.fromEnvironment('LIVE_PORTAL_TEST');
  final cases = <String, String>{
    'Blogger review':
        'https://senseandseoulability.blogspot.com/2015/07/seoul-forest.html',
    'Naver blog review':
        'https://blog.naver.com/PostView.nhn?blogId=doragi178&logNo=223661896739',
    'Tistory review': 'https://physics-choe.tistory.com/101',
  };
  for (final entry in cases.entries) {
    test(entry.key, () async {
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {};
      try {
        final result = await PortalPlaceExtractorService().extract(entry.value);
        print(jsonEncode({
          'site': entry.key,
          'url': entry.value,
          'status': 'success',
          'places': result
              .map((p) => {
                    'name': p.title,
                    'address': p.address,
                    'lat': p.latitude,
                    'lng': p.longitude
                  })
              .toList()
        }));
        expect(result, isNotEmpty);
        expect(
            result.any((p) =>
                p.title.contains(entry.key.startsWith('Naver') ? '파로' : '서울숲')),
            isTrue);
        expect(result.every((p) => p.latitude != null && p.longitude != null),
            isTrue);
      } catch (e) {
        print(jsonEncode({
          'site': entry.key,
          'status': 'failed',
          'reason': e is FormatException ? e.message : e.runtimeType.toString()
        }));
        rethrow;
      } finally {
        debugPrint = original;
      }
    }, skip: !enabled, timeout: const Timeout(Duration(minutes: 3)));
  }
}
