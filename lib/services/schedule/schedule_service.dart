import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/schedule/schedule_model.dart';
import '../infrastructure/paged_rows.dart';

class ScheduleConflict implements Exception {
  const ScheduleConflict();
  @override
  String toString() => '일정이 변경되었거나 삭제됐어요. 목록에서 최신 내용을 다시 확인해주세요.';
}

class ScheduleService {
  ScheduleService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;
  final SupabaseClient _supabase;
  static final ValueNotifier<int> _changes = ValueNotifier(0);
  static Listenable get changes => _changes;

  Future<List<ScheduleModel>> fetchByDate(DateTime date) => fetchByDateRange(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day + 1)
          .subtract(const Duration(microseconds: 1)));

  Future<List<ScheduleModel>> fetchByDateRange(
      DateTime start, DateTime end) async {
    final owner = _supabase.auth.currentUser?.id;
    final rows = await loadRowsById(
        () => _supabase
            .from('schedules')
            .select()
            .gt('end_time', start.toUtc().toIso8601String())
            .lte('start_time', end.toUtc().toIso8601String()),
        isCancelled: () => owner != _supabase.auth.currentUser?.id);
    return rows.map(ScheduleModel.fromJson).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<void> addOrUpdate(ScheduleModel schedule,
      {int? expectedRevision}) async {
    if (expectedRevision == null) {
      await _create([schedule]);
    } else {
      final updated = await _supabase
          .from('schedules')
          .update(schedule.toJson())
          .eq('id', schedule.id)
          .eq('user_id', schedule.userId)
          .eq('revision', expectedRevision)
          .select('id');
      if (updated.isEmpty) throw const ScheduleConflict();
    }
    _changes.value++;
  }

  // 최초 생성 재시도는 기존 행을 덮어쓰지 않습니다.
  Future<void> _create(List<ScheduleModel> schedules) async {
    try {
      await _supabase.rpc('create_schedules_once', params: {
        'p_schedules': schedules.map((s) => s.toJson()).toList(),
      });
    } on PostgrestException catch (error) {
      if (error.code == '40001') throw const ScheduleConflict();
      rethrow;
    }
  }

  Future<void> addAll(List<ScheduleModel> schedules) async {
    if (schedules.isEmpty) return;
    await _create(schedules);
    _changes.value++;
  }

  Future<void> delete(String id) async {
    final deleted =
        await _supabase.from('schedules').delete().eq('id', id).select('id');
    if (deleted.isEmpty) throw const ScheduleConflict();
    _changes.value++;
  }
}
