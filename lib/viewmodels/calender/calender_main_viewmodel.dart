import 'package:flutter/material.dart';
import '../../models/schedule_model.dart';
import '../../services/schedule_service.dart';

class CalendarViewModel extends ChangeNotifier {
  final ScheduleService _svc = ScheduleService();

  Map<DateTime, List<ScheduleModel>> events = {};

  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();

  DateTime? get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;

  /// 선택된 날짜 변경
  void onDaySelected(DateTime selected, DateTime focused) {
    _selectedDay = selected;
    _focusedDay = focused;
    notifyListeners();
  }

  /// 특정 월 기준으로 일정을 불러와 events 맵에 저장
  Future<void> loadMonth(DateTime focusedMonth) async {
    events.clear();

    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0, 23, 59, 59);

    final schedules = await _svc.fetchByDateRange(firstDay, lastDay);

    for (final schedule in schedules) {
      final dayKey = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );

      events.putIfAbsent(dayKey, () => []);
      events[dayKey]!.add(schedule);
    }

    notifyListeners();
  }

  /// 특정 날짜에 해당하는 일정 반환
  List<ScheduleModel> eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }

  /// 선택된 날짜의 이벤트 반환
  List<ScheduleModel> get selectedEvents {
    if (_selectedDay == null) return [];
    final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    return events[key] ?? [];
  }
}
