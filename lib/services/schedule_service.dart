import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_model.dart';

class ScheduleService {
  final _supabase = Supabase.instance.client;

  Future<List<ScheduleModel>> fetchByDate(DateTime date) async {
    final from = date.toIso8601String().split('T').first;
    final to = from;
    final res = await _supabase
        .from('schedules')
        .select()
        .gte('date', from)
        .lte('date', to);
    return (res as List).map((e) => ScheduleModel.fromJson(e)).toList();
  }

  Future<void> addOrUpdate(ScheduleModel sch) async {
    await _supabase.from('schedules')
        .upsert(sch.toJson());
  }

  Future<void> delete(String id) async {
    await _supabase.from('schedules').delete().eq('id', id);
  }
}
