import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SocialExtractionService {
  SocialExtractionService(
      {Future<Map<String, dynamic>> Function(Map<String, dynamic>)? invoke,
      this.pollInterval = const Duration(seconds: 2)})
      : _invoke = invoke;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)? _invoke;
  final Duration pollInterval;
  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    if (_invoke != null) return _invoke(body);
    final response = await Supabase.instance.client.functions
        .invoke('social-extraction', body: body);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> fetch(String platform, String url) async {
    final userId =
        _invoke == null ? Supabase.instance.client.auth.currentUser?.id : null;
    if (_invoke == null && userId == null) {
      throw const FormatException('로그인이 필요합니다.');
    }
    void checkAccount() {
      if (_invoke == null &&
          Supabase.instance.client.auth.currentUser?.id != userId) {
        throw const FormatException('계정이 변경되어 분석을 중단했습니다.');
      }
    }

    try {
      final started = await _call({
        'action': 'start',
        'platform': platform,
        'url': url,
        'requestId': const Uuid().v4()
      }).timeout(const Duration(seconds: 20));
      final job = started['jobId'];
      if (job is! String) throw const FormatException('분석 요청을 시작하지 못했습니다.');
      final deadline = DateTime.now().add(const Duration(minutes: 2));
      while (DateTime.now().isBefore(deadline)) {
        checkAccount();
        final result = await _call({'action': 'poll', 'jobId': job})
            .timeout(const Duration(seconds: 20));
        checkAccount();
        if (result['status'] == 'SUCCEEDED' && result['rows'] is List) {
          return result['rows'] as List;
        }
        await Future<void>.delayed(pollInterval);
      }
      throw TimeoutException('분석 시간이 초과되었습니다. 다시 시도해주세요.');
    } on FunctionException catch (e) {
      final details = e.details;
      throw FormatException(details is Map
          ? (details['error']?.toString() ?? '게시물 분석에 실패했습니다.')
          : '게시물 분석에 실패했습니다.');
    }
  }
}
