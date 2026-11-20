import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// 저장 실패 답변을 계정별로 유지합니다. 서버 확인 전에는 삭제하지 않습니다.
class TripDraftStore {
  TripDraftStore({Future<Box<String>> Function()? openBox})
      : _openBox = openBox ?? (() => Hive.openBox<String>('trip_drafts_v1'));
  static final shared = TripDraftStore();
  final Future<Box<String>> Function() _openBox;
  Future<void> _tail = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function(Box<String>) action) {
    final result = _tail.then((_) async => action(await _openBox()));
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> put(String owner, Map<String, dynamic> payload) {
    // 호출 이후 메시지나 장소 목록 변경이 임시 저장 내용에 섞이지 않게 복사합니다.
    final encoded = jsonEncode({
      'owner': owner,
      'payload': payload,
      'saved_at': DateTime.now().toUtc().toIso8601String()
    });
    return _serial((box) async {
      await box.put('$owner:${payload['p_id']}', encoded);
      await box.flush();
    });
  }

  Future<List<Map<String, dynamic>>> list(String owner) => _serial((box) async {
        final drafts = <Map<String, dynamic>>[];
        for (final key in box.keys
            .whereType<String>()
            .where((k) => k.startsWith('$owner:'))
            .toList()) {
          try {
            final value = jsonDecode(box.get(key)!);
            if (value is Map<String, dynamic> &&
                value['owner'] == owner &&
                value['payload'] is Map<String, dynamic>) {
              if (value['server_saved'] == true) {
                // 서버 확인된 항목은 복구 목록에서 제외하고 정리만 재시도합니다.
                try {
                  await box.delete(key);
                  await box.flush();
                } catch (_) {/* 다음 조회 때 다시 정리합니다. */}
              } else {
                drafts.add(value);
              }
            }
          } on FormatException {/* 손상된 항목을 삭제하지 않고 나머지 복구를 계속합니다. */}
        }
        drafts.sort((a, b) =>
            b['saved_at'].toString().compareTo(a['saved_at'].toString()));
        return drafts;
      });

  Future<void> markSaved(String owner, Map<String, dynamic> payload) =>
      _serial((box) async {
        final key = '$owner:${payload['p_id']}';
        final raw = box.get(key);
        if (raw == null) return;
        final current = jsonDecode(raw) as Map<String, dynamic>;
        if ((current['payload'] as Map)['p_write_id'] != payload['p_write_id']) {
          return;
        }
        current['server_saved'] = true;
        await box.put(key, jsonEncode(current));
        await box.flush();
      });

  Future<void> removeIfSaved(String owner, Map<String, dynamic> payload) =>
      _serial((box) async {
        final key = '$owner:${payload['p_id']}';
        final raw = box.get(key);
        if (raw == null) return;
        final current = jsonDecode(raw) as Map<String, dynamic>;
        if ((current['payload'] as Map)['p_write_id'] !=
            payload['p_write_id']) {
          return;
        }
        await box.delete(key);
        await box.flush();
      });
}
