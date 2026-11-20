import 'package:uuid/uuid.dart';
import '../markers/marker_model.dart';
import '../schedule/schedule_model.dart';

/// 모든 장소 ID를 유지하면서 선택한 시간 구간을 리스트 순서대로 배분합니다.
List<ScheduleModel> buildListSchedules({
  required List<MarkerModel> places,
  required String userId,
  required String title,
  required DateTime start,
  required DateTime end,
  List<String> participants = const [],
  List<String>? scheduleIds,
}) {
  if (scheduleIds != null && scheduleIds.length != places.length) {
    throw ArgumentError('일정 ID 개수가 장소 개수와 다릅니다.');
  }
  final minutes = end.difference(start).inMinutes;
  if (places.isEmpty || minutes < places.length) {
    throw ArgumentError('장소마다 최소 1분 이상의 시간이 필요합니다.');
  }
  return [
    for (var i = 0; i < places.length; i++)
      ScheduleModel(
        id: scheduleIds?[i] ?? const Uuid().v4(),
        userId: userId,
        title: '${title.trim()} · ${places[i].title}',
        startTime: start.add(Duration(minutes: minutes * i ~/ places.length)),
        endTime: i == places.length - 1
            ? end
            : start.add(Duration(minutes: minutes * (i + 1) ~/ places.length)),
        placeId: places[i].id,
        latitude: places[i].lat,
        longitude: places[i].lng,
        colorValue: 0xFF222222,
        collaboratorIds: List.of(participants),
      ),
  ];
}
