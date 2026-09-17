import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../env.dart';

class ApifyService {
  static const String _baseUrl = 'https://api.apify.com/v2';

  /// Apify Actor 실행
  ///
  /// [instagramUrl] : 분석할 Instagram 게시물 URL
  ///
  /// 반환값:
  /// Apify Dataset에서 가져온 원본 결과 List
  Future<List<dynamic>> fetchInstagramData({
    required String instagramUrl,
  }) async {
    final token = Env.apifyApiToken;

    if (token == null || token.isEmpty) {
      throw Exception('Apify API Token이 설정되지 않았습니다.');
    }

    // 1. Actor 실행
    final runResponse = await http.post(
      Uri.parse(
        '$_baseUrl/acts/nH2AHrwxeTRJoN5hX/runs?token=$token',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': [
          instagramUrl,
        ],
      }),
    );

    if (runResponse.statusCode < 200 || runResponse.statusCode >= 300) {
      throw Exception(
        'Apify Actor 실행 실패: '
            '${runResponse.statusCode} ${runResponse.body}',
      );
    }

    final runData = jsonDecode(runResponse.body);

    final runId = runData['data']?['id'];
    final datasetId = runData['data']?['defaultDatasetId'];

    if (runId == null || datasetId == null) {
      throw Exception('Apify 실행 정보(runId/datasetId)를 가져오지 못했습니다.');
    }

    // 2. Actor 실행 완료까지 대기
    await _waitForRunCompletion(
      runId: runId,
      token: token,
    );

    // 3. Dataset 결과 가져오기
    final datasetResponse = await http.get(
      Uri.parse(
        '$_baseUrl/datasets/$datasetId/items?token=$token',
      ),
    );

    if (datasetResponse.statusCode < 200 ||
        datasetResponse.statusCode >= 300) {
      throw Exception(
        'Apify Dataset 조회 실패: '
            '${datasetResponse.statusCode} ${datasetResponse.body}',
      );
    }

    final result = jsonDecode(datasetResponse.body);

    if (result is! List) {
      throw Exception('Apify Dataset 결과 형식이 올바르지 않습니다.');
    }

    return result;
  }

  /// Actor 실행 상태 확인
  Future<void> _waitForRunCompletion({
    required String runId,
    required String token,
  }) async {
    const maxAttempts = 60;
    const interval = Duration(seconds: 2);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/actor-runs/$runId?token=$token',
        ),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Apify 실행 상태 조회 실패: '
              '${response.statusCode} ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final status = data['data']?['status'];

      switch (status) {
        case 'SUCCEEDED':
          return;

        case 'FAILED':
        case 'ABORTED':
        case 'TIMED-OUT':
          throw Exception('Apify Actor 실행 실패: $status');
      }

      await Future.delayed(interval);
    }

    throw TimeoutException('Apify Actor 실행 시간이 초과되었습니다.');
  }
}