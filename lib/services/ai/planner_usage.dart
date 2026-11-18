import 'dart:convert';
import 'package:http/http.dart' as http;

/// 공급자가 보고한 사용량은 호출별 최신 값으로 교체하며 스트림 조각을 합산하지 않습니다.
class PlannerUsage {
  PlannerUsage(this.menu) : startedAt = DateTime.now();
  final String menu;
  final DateTime startedAt;
  final List<Map<String, dynamic>?> _rounds = [];
  int toolCalls = 0;
  String status = 'running';

  void Function(Map<String, dynamic>) startRound() {
    final index = _rounds.length;
    _rounds.add(null);
    return (metadata) => _rounds[index] = Map.of(metadata);
  }

  int? _sum(String field) {
    if (_rounds.isEmpty || _rounds.any((r) => r?[field] is! num)) return null;
    return _rounds.fold<int>(0, (sum, r) => sum + (r![field] as num).toInt());
  }

  Map<String, dynamic> toJson() => {
        'menu': menu,
        'startedAt': startedAt.toIso8601String(),
        'status': status,
        'modelCalls': _rounds.length,
        'toolCalls': toolCalls,
        'reportedRounds': _rounds.where((r) => r != null).length,
        'promptTokens': _sum('promptTokenCount'),
        'outputTokens': _sum('candidatesTokenCount'),
        'thinkingTokens': _sum('thoughtsTokenCount'),
        'totalTokens': _sum('totalTokenCount'),
        'rounds': _rounds.map((r) => r == null ? null : Map.of(r)).toList(),
      };
}

/// 구형 SDK가 사고 토큰 메타데이터를 버리기 전에 원본 SSE를 읽습니다.
/// 원본 바이트와 스트림 오류는 변경 없이 전달합니다.
class PlannerUsageClient extends http.BaseClient {
  PlannerUsageClient(this.inner, this.beginRound);
  final http.Client inner;
  final void Function(Map<String, dynamic>)? Function() beginRound;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final report = request.url.path.endsWith(':streamGenerateContent')
        ? beginRound()
        : null;
    final response = await inner.send(request);
    if (report == null) return response;
    final decoder =
        const Utf8Decoder(allowMalformed: true).startChunkedConversion(
      const LineSplitter().startChunkedConversion(_UsageLines(report)),
    );
    Stream<List<int>> observed() async* {
      try {
        await for (final bytes in response.stream) {
          decoder.add(bytes);
          yield bytes;
        }
      } finally {
        decoder.close();
      }
    }

    return http.StreamedResponse(observed(), response.statusCode,
        headers: response.headers,
        request: response.request,
        contentLength: response.contentLength,
        reasonPhrase: response.reasonPhrase,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection);
  }

  @override
  void close() => inner.close();
}

class _UsageLines implements Sink<String> {
  _UsageLines(this.report);
  final void Function(Map<String, dynamic>) report;
  final _data = <String>[];
  @override
  void add(String line) {
    if (line.isEmpty) {
      _flush();
    } else if (line.startsWith('data:')) {
      _data.add(line.substring(5).trimLeft());
    }
  }

  void _flush() {
    if (_data.isEmpty) return;
    final data = _data.join('\n');
    _data.clear();
    try {
      final json = jsonDecode(data);
      if (json is Map && json['usageMetadata'] is Map) {
        report(Map<String, dynamic>.from(json['usageMetadata'] as Map));
      }
    } on FormatException {/* JSON이 아닌 SSE 이벤트는 응답 처리에 영향을 주지 않습니다. */}
  }

  @override
  void close() => _flush();
}
