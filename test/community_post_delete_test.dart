import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/viewmodels/community/community_post_detail_viewmodel.dart';

void main() {
  test(
      'Only owner can delete; request is scoped and empty results are failures',
      () async {
    var deletes = 0;
    var empty = false;
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      if (request.url.path.contains('/auth/')) {
        return http.Response(
            jsonEncode({
              'access_token':
                  '${base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256'}))).replaceAll('=', '')}.${base64Url.encode(utf8.encode(jsonEncode({
                            'sub': 'owner',
                            'exp': 4102444800
                          }))).replaceAll('=', '')}.test',
              'token_type': 'bearer',
              'refresh_token': 'test-refresh',
              'expires_in': 3600,
              'user': {
                'id': 'owner',
                'aud': 'authenticated',
                'created_at': '2026-10-21T00:00:00Z',
                'app_metadata': {},
                'user_metadata': {}
              }
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'});
      }
      expect(request.method, 'DELETE');
      expect(request.url.queryParameters['id'], 'eq.post-1');
      expect(request.url.queryParameters['author_id'], 'eq.owner');
      deletes++;
      return http.Response(empty ? '[]' : '[{"id":"post-1"}]', 200,
          request: request, headers: {'content-type': 'application/json'});
    }));
    final vm = CommunityPostDetailViewModel(postId: 'post-1', client: client);
    expect(await vm.deletePost('owner'), isFalse);
    expect(deletes, 0);
    await client.auth
        .signInWithPassword(email: 'test@example.com', password: 'test-only');
    expect(vm.canDelete('other'), isFalse);
    expect(await vm.deletePost('other'), isFalse);
    expect(deletes, 0);
    expect(await vm.deletePost('owner'), isTrue);
    expect(deletes, 1);
    empty = true;
    expect(await vm.deletePost('owner'), isFalse);
    expect(vm.errorMessage, isNotNull);
    expect(vm.isDeleting, isFalse);
    vm.dispose();
    await client.dispose();
  });
}
