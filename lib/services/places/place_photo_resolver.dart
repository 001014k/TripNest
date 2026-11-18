import 'package:flutter/foundation.dart';
import '../infrastructure/server_api_client.dart';

/// 사진 데이터를 추가로 보관하지 않고 동시 미디어 요청을 공유합니다.
class PlacePhotoResolver {
  PlacePhotoResolver({Future<String> Function(String)? resolve})
      : _resolve = resolve ?? ServerApiClient.imageUrl;

  static final shared = PlacePhotoResolver();
  final Future<String> Function(String) _resolve;
  final _pending = <String, Future<String>>{};
  int _requests = 0;

  Future<String> resolve(String reference) {
    if (Uri.tryParse(reference)?.host != 'places.googleapis.com') {
      return Future.value(reference);
    }
    return _pending.putIfAbsent(reference, () async {
      _requests++;
      if (kDebugMode) {
        debugPrint('[Places] photo media request #$_requests');
      }
      try {
        // putIfAbsent에 요청이 등록된 후에 정리하도록 지연합니다.
        // 주입된 조회 함수가 Future 반환 전에 예외를 던져도 동일하게 처리합니다.
        return await Future<String>.sync(() => _resolve(reference));
      } finally {
        _pending.remove(reference);
      }
    });
  }
}
