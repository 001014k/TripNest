import 'package:flutter/material.dart';
import '../../models/schedule_model.dart';
import '../../services/schedule_service.dart';

class CalendarViewModel extends ChangeNotifier {
  final ScheduleService _svc = ScheduleService();
  Map<DateTime, List<ScheduleModel>> events = {};

  Future<void> loadMonth(DateTime focusedMonth) async {
    events.clear();
    // 한 달 범위 계산 후 fetch 및 그룹화
    // 생략 - 일자별 fetchByDate 반복
  }

  List<ScheduleModel> eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }
}
