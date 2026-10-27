import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/services/notifications/notification_service.dart';

void main() {
  test(
      'Events create server notifications before dispatch; empty/failure never dispatch',
      () async {
    final calls = <String>[];
    var empty = false;
    var failure = false;
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      final path = request.url.path;
      if (path.contains('/auth/')) {
        return http.Response(
            jsonEncode({
              'access_token': 'test-token',
              'refresh_token': 'refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'actor',
                'aud': 'authenticated',
                'app_metadata': {},
                'user_metadata': {},
                'created_at': '2026-10-15T00:00:00Z'
              },
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'});
      }
      calls.add(path);
      if (path.contains('/rpc/')) {
        return http.Response(
            failure
                ? '{"message":"denied"}'
                : jsonEncode({
                    'notification_ids': empty ? [] : ['notification-1']
                  }),
            failure ? 403 : 200,
            request: request,
            headers: {'content-type': 'application/json'});
      }
      expect(jsonDecode(request.body)['notification_ids'], ['notification-1']);
      return http.Response('{"sent":1}', 200,
          request: request, headers: {'content-type': 'application/json'});
    }));
    addTearDown(client.dispose);
    await client.auth
        .signInWithPassword(email: 'test@example.com', password: 'test');
    final service = NotificationService(supabase: client);
    await service.notifyFriendRequest('request-id');
    await service.notifyListUpdated('list-id', 'removed');
    await service.notifyMarkerAddedToList(
        listId: 'list-id', markerId: 'marker-id', markerTitle: '카페');
    expect(calls, [
      '/rest/v1/rpc/notify_friend_request',
      '/functions/v1/send-push-notification',
      '/rest/v1/rpc/notify_list_updated',
      '/functions/v1/send-push-notification',
      '/rest/v1/rpc/notify_list_marker_added',
      '/functions/v1/send-push-notification',
    ]);
    calls.clear();
    empty = true;
    await service.notifyFriendRequest('request-id');
    failure = true;
    await service.notifyListUpdated('list-id', 'removed');
    expect(calls.every((path) => path.contains('/rpc/')), true);
    expect(calls.length, 2);
  });
}
