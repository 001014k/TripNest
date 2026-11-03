import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../env.dart';

/// Preserves HTTP/SSE semantics while keeping third-party credentials on the server.
class ServerApiClient extends http.BaseClient {
  ServerApiClient(
      {http.Client? transport,
      String? endpoint,
      Future<String> Function()? accessToken})
      : _transport = transport ?? _sharedTransport,
        _endpoint = endpoint ?? '${Env.supabaseUrl}/functions/v1/app-api',
        _accessToken = accessToken;
  static final http.Client _sharedTransport = http.Client();
  final http.Client _transport;
  final String _endpoint;
  final Future<String> Function()? _accessToken;
  Future<String> _token() async {
    if (_accessToken != null) return _accessToken();
    final auth = Supabase.instance.client.auth;
    var session = auth.currentSession;
    if (session == null) throw StateError('로그인이 필요합니다.');
    if (session.isExpired) session = (await auth.refreshSession()).session;
    if (session == null) throw StateError('로그인이 필요합니다.');
    return session.accessToken;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final params = Map<String, String>.of(request.url.queryParameters)
      ..remove('key')
      ..remove('serviceKey');
    final target = request.url
        .replace(queryParameters: params)
        .toString()
        .replaceFirst(RegExp(r'\?$'), '');
    final body = await request.finalize().bytesToString();
    final proxy = http.Request('POST', Uri.parse(_endpoint))
      ..headers.addAll({
        'Authorization': 'Bearer ${await _token()}',
        'apikey': Env.supabaseAnonKey,
        'Content-Type': 'application/json'
      })
      ..body = jsonEncode({
        'url': target.toString(),
        'method': request.method,
        'body': body,
        'fieldMask': request.headers['X-Goog-FieldMask'] ??
            request.headers['x-goog-fieldmask']
      });
    final response = await _transport.send(proxy);
    return http.StreamedResponse(response.stream, response.statusCode,
        headers: response.headers, request: request);
  }

  static Future<String> imageUrl(String url) async {
    final response = await Supabase.instance.client.functions
        .invoke('app-api', body: {'action': 'resolveImage', 'url': url});
    final value = response.data;
    if (value is! Map || value['url'] is! String) {
      throw StateError('사진 주소를 가져오지 못했습니다.');
    }
    return value['url'] as String;
  }

  @override
  void close() {
    if (!identical(_transport, _sharedTransport)) _transport.close();
  }
}
