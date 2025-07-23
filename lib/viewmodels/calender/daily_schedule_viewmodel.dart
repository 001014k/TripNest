import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/schedule_model.dart';

class DailyScheduleViewModel extends ChangeNotifier {
  final _client = Supabase.instance.client;

  List<ScheduleModel> schedules = [];
  bool isLoading = false;

  Future<void> loadSchedules(DateTime date) async {
    isLoading = true;
    notifyListeners();

    final user = _client.auth.currentUser;
    if (user == null) {
      schedules = [];
      isLoading = false;
      notifyListeners();
      return;
    }

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    try {
      final data = await _client
          .from('schedules')
          .select()
          .eq('user_id', user.id)
          .gte('start_time', dayStart.toIso8601String())
          .lt('start_time', dayEnd.toIso8601String())
          .order('start_time', ascending: true);

      schedules = (data as List<dynamic>)
          .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      schedules = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> delete(String scheduleId) async {
    try {
      final response = await _client
          .from('schedules')
          .delete()
          .eq('id', scheduleId);

      if (response.error != null) {
        throw Exception('일정 삭제에 실패했습니다: ${response.error!.message}');
      }

      // 삭제 성공 시 로컬 리스트에서 제거 및 UI 갱신
      schedules.removeWhere((schedule) => schedule.id == scheduleId);
      notifyListeners();
    } catch (e) {
      throw Exception('일정 삭제 중 오류가 발생했습니다: $e');
    }
  }
}
