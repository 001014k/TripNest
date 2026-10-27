import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/viewmodels/community/community_board_viewmodel.dart';

void main() {
  test('Latest tab request controls loading and ignores earlier failure',
      () async {
    final requests = <http.Request>[];
    final pending = <Completer<http.Response>>[];
    final client = SupabaseClient('https://example.supabase.co', 'test',
        httpClient: MockClient((request) {
      requests.add(request);
      final response = Completer<http.Response>();
      pending.add(response);
      return response.future;
    }));
    final vm = CommunityBoardViewModel(client: client);
    final first = vm.loadPosts();
    await Future<void>.delayed(Duration.zero);
    final second = vm.loadPosts();
    await Future<void>.delayed(Duration.zero);
    expect(vm.isLoading, isTrue);
    pending[1].complete(http.Response('[]', 200,
        request: requests[1], headers: {'content-type': 'application/json'}));
    await second;
    expect(vm.isLoading, isFalse);
    pending[0].complete(http.Response('{"message":"old failure"}', 403,
        request: requests[0], headers: {'content-type': 'application/json'}));
    await first;
    expect(vm.errorMessage, isNull);
    expect(vm.isLoading, isFalse);
    final third = vm.loadPosts();
    await Future<void>.delayed(Duration.zero);
    expect(vm.isLoading, isTrue);
    pending[2].complete(http.Response('[]', 200,
        request: requests[2], headers: {'content-type': 'application/json'}));
    await third;
    expect(vm.isLoading, isFalse);
    vm.dispose();
    await client.dispose();
  });
}
