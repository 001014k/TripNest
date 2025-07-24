import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_model.dart';

class ScheduleService {
  final _supabase = Supabase.instance.client;

  Future<List<ScheduleModel>> fetchByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0).toIso8601String();
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final data = await _supabase
        .from('schedules')
        .select()
        .gte('start_time', start)
        .lte('start_time', end);

    // data는 List<dynamic> 타입이므로 타입캐스트 후 반환
    return (data as List<dynamic>)
        .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ScheduleModel>> fetchByDateRange(DateTime start, DateTime end) async {
    final data = await _supabase
        .from('schedules')
        .select()
        .gte('start_time', start.toIso8601String())
        .lte('start_time', end.toIso8601String());

    return (data as List<dynamic>)
        .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }


  Future<void> addOrUpdate(ScheduleModel sch) async {
    await _supabase.from('schedules')
        .upsert(sch.toJson());
  }

  Future<void> delete(String id) async {
    await _supabase.from('schedules').delete().eq('id', id);
  }
}
