import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/services/schedule/schedule_service.dart';
import 'package:fluttertrip/models/schedule/schedule_model.dart';

void main() {
  test('Separate service instances notify shared listeners only after successful writes', () async {
    var fail = false;
    final client = SupabaseClient('https://example.supabase.co', 'test-key',
        httpClient: MockClient((request) async => fail
            ? http.Response('{"message":"denied","code":"42501"}', 403,
                headers: {'content-type': 'application/json'}, request: request)
            : http.Response('', 201, request: request)));
    final editor = ScheduleService(client: client);
    final listEditor = ScheduleService(client: client);
    var changes = 0;
    void onChanged() => changes++;
    ScheduleService.changes.addListener(onChanged);
    addTearDown(() async {
      ScheduleService.changes.removeListener(onChanged);
      await client.dispose();
    });
    final schedule = ScheduleModel(id: 'test', userId: 'owner', title: '여행',
        startTime: DateTime(2026, 10, 13, 11),
        endTime: DateTime(2026, 10, 13, 12), colorValue: 0xFF222222);
    final save = editor.addOrUpdate(schedule);
    expect(changes, 0);
    await save;
    expect(changes, 1);
    await listEditor.addAll([schedule]);
    expect(changes, 2);
    await listEditor.addAll([]);
    expect(changes, 2);
    await editor.delete('test');
    expect(changes, 3);
    fail = true;
    await expectLater(editor.addOrUpdate(schedule), throwsA(isA<PostgrestException>()));
    await expectLater(listEditor.addAll([schedule]), throwsA(isA<PostgrestException>()));
    await expectLater(editor.delete('test'), throwsA(isA<PostgrestException>()));
    expect(changes, 3);
  });
}
