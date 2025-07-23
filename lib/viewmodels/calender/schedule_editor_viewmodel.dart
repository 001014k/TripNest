import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/schedule_model.dart';

class ScheduleEditorViewModel extends ChangeNotifier {
  final _client = Supabase.instance.client;

  String id = '';
  String title = '';

  // 화면에서 날짜와 시간을 관리하는 변수
  DateTime? date;
  TimeOfDay? time;

  DateTime? startTime;
  DateTime? endTime;
  String? placeId;
  double? latitude;
  double? longitude;
  int colorValue = 0;
  List<String>? collaboratorIds;

  String location = '';
  String category = '관광지';
  String budget = '';
  String memo = '';
  bool alarm = true;
  bool shareWithFriends = true;

  bool isEditMode = false;

  void initializeWith(Map<String, dynamic>? event) {
    if (event != null) {
      id = event['id'] ?? '';
      title = event['title'] ?? '';

      // start_time이 있으면 date와 time을 분리해서 저장
      if (event['start_time'] != null) {
        startTime = DateTime.parse(event['start_time']);
        date = DateTime(startTime!.year, startTime!.month, startTime!.day);
        time = TimeOfDay(hour: startTime!.hour, minute: startTime!.minute);
      } else {
        date = null;
        time = null;
        startTime = null;
      }

      endTime = event['end_time'] != null ? DateTime.parse(event['end_time']) : null;

      placeId = event['place_id'];
      latitude = event['latitude'] != null ? (event['latitude'] as num).toDouble() : null;
      longitude = event['longitude'] != null ? (event['longitude'] as num).toDouble() : null;
      colorValue = event['color_value'] ?? 0;
      collaboratorIds = (event['collaborator_ids'] as List?)?.map((e) => e as String).toList();

      location = event['location'] ?? '';
      category = event['category'] ?? '관광지';
      budget = event['budget'] ?? '';
      memo = event['memo'] ?? '';
      alarm = event['alarm'] ?? true;
      shareWithFriends = event['share_with_friends'] ?? true;

      isEditMode = true;
    }
    notifyListeners();
  }

  Future<ScheduleModel?> saveSchedule() async {
    if (title.isEmpty || date == null || time == null) {
      throw Exception('제목, 날짜, 시간은 필수입니다.');
    }

    // date + time 합쳐서 startTime 생성
    startTime = DateTime(
      date!.year,
      date!.month,
      date!.day,
      time!.hour,
      time!.minute,
    );

    // endTime이 null이면 기본적으로 1시간 뒤로 설정
    endTime ??= startTime!.add(const Duration(hours: 1));

    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final scheduleData = {
      'user_id': user.id,
      'title': title,
      'start_time': startTime!.toIso8601String(),
      'end_time': endTime!.toIso8601String(),
      'place_id': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'color_value': colorValue,
      'collaborator_ids': collaboratorIds,
      'location': location,
      'category': category,
      'budget': budget,
      'memo': memo,
      'alarm': alarm,
      'share_with_friends': shareWithFriends,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (isEditMode && id.isNotEmpty) {
        final updated = await _client
            .from('schedules')
            .update(scheduleData)
            .eq('id', id)
            .select()
            .single();

        if (updated == null) {
          throw Exception('일정 수정에 실패했습니다.');
        }

        return ScheduleModel.fromJson(updated);
      } else {
        scheduleData['created_at'] = DateTime.now().toIso8601String();

        final inserted = await _client
            .from('schedules')
            .insert(scheduleData)
            .select()
            .single();

        if (inserted == null) {
          throw Exception('일정 저장에 실패했습니다.');
        }

        return ScheduleModel.fromJson(inserted);
      }
    } catch (e) {
      throw Exception('일정 저장 중 오류가 발생했습니다: $e');
    }
  }
}
