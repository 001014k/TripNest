import 'package:uuid/uuid.dart';
import 'marker_model.dart';
import 'schedule_model.dart';

/// Allocates the selected interval in list order, preserving every place ID.
List<ScheduleModel> buildListSchedules({
  required List<MarkerModel> places,
  required String userId,
  required String title,
  required DateTime start,
  required DateTime end,
  List<String> participants = const [],
}) {
  final minutes = end.difference(start).inMinutes;
  if (places.isEmpty || minutes < places.length) {
    throw ArgumentError('장소마다 최소 1분 이상의 시간이 필요합니다.');
  }
  return [
    for (var i = 0; i < places.length; i++)
      ScheduleModel(
        id: const Uuid().v4(),
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
