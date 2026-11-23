import 'package:http/http.dart' as http;

/// 앱 계정 삭제와 외부 계정 연결 해제의 성공 여부를 따로 처리합니다.
class ProviderDisconnectService {
  ProviderDisconnectService({http.Client? client})
      : _client = client ?? http.Client();
  final http.Client _client;

  Future<bool> disconnect(
      {required List<String> providers, String? providerToken}) async {
    final social = providers.where((p) => p != 'email' && p != 'phone').toSet();
    if (social.isEmpty) return true;
    // 여러 공급자가 연결돼 있으면 현재 토큰의 발급자를 추측해 전송하지 않습니다.
    if (social.length != 1 || providerToken == null || providerToken.isEmpty) {
      return false;
    }
    try {
      final response = switch (social.single) {
        'google' => await _client
              .post(Uri.https('oauth2.googleapis.com', '/revoke'), body: {
            'token': providerToken
          }).timeout(const Duration(seconds: 10)),
        'kakao' => await _client
              .post(Uri.https('kapi.kakao.com', '/v1/user/unlink'), headers: {
            'Authorization': 'Bearer $providerToken'
          }).timeout(const Duration(seconds: 10)),
        _ => null,
      };
      return response?.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _client.close();
}
