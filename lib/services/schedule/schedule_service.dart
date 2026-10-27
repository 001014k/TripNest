import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/schedule/schedule_model.dart';

class ScheduleService {
  ScheduleService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;
  final SupabaseClient _supabase;
  static final ValueNotifier<int> _changes = ValueNotifier(0);
  static Listenable get changes => _changes;

  Future<List<ScheduleModel>> fetchByDate(DateTime date) async {
    final start =
        DateTime(date.year, date.month, date.day, 0, 0, 0).toUtc().toIso8601String();
    final end =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();

    final data = await _supabase
        .from('schedules')
        .select()
        .gte('start_time', start)
        .lte('start_time', end)
        .order('start_time');

    // data는 List<dynamic> 타입이므로 타입캐스트 후 반환
    return (data as List<dynamic>)
        .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ScheduleModel>> fetchByDateRange(
      DateTime start, DateTime end) async {
    final data = await _supabase
        .from('schedules')
        .select()
        .gte('start_time', start.toUtc().toIso8601String())
        .lte('start_time', end.toUtc().toIso8601String())
        .order('start_time');

    return (data as List<dynamic>)
        .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addOrUpdate(ScheduleModel sch) async {
    await _supabase.from('schedules').upsert(sch.toJson());
    _changes.value++;
  }

  Future<void> addAll(List<ScheduleModel> schedules) async {
    if (schedules.isEmpty) return;
    await _supabase
        .from('schedules')
        .insert(schedules.map((schedule) => schedule.toJson()).toList());
    _changes.value++;
  }

  Future<void> delete(String id) async {
    await _supabase.from('schedules').delete().eq('id', id);
    _changes.value++;
  }
}
