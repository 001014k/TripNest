import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/models/lists/list_schedule_draft.dart';
import 'package:fluttertrip/models/markers/marker_model.dart';

void main() {
  final places = List.generate(
      3,
      (i) => MarkerModel(
          id: 'place-$i',
          title: '장소 $i',
          address: '주소 $i',
          keyword: '카페',
          lat: 37.0 + i,
          lng: 127.0,
          markerImagePath: ''));
  test('Maps every place in order and divides time without gaps', () {
    final start = DateTime(2026, 10, 13, 23);
    final end = start.add(const Duration(minutes: 100));
    final result = buildListSchedules(
        places: places,
        userId: 'owner',
        title: '여행',
        start: start,
        end: end,
        participants: ['friend']);
    expect(result.map((s) => s.placeId), ['place-0', 'place-1', 'place-2']);
    expect(result.map((s) => s.id).toSet().length, 3);
    expect(result.first.startTime, start);
    expect(result.first.toJson()['start_time'], start.toUtc().toIso8601String());
    expect(result.last.toJson()['end_time'], end.toUtc().toIso8601String());
    expect(result.last.endTime, end);
    for (var i = 0; i < result.length; i++) {
      expect(result[i].latitude, places[i].lat);
      expect(result[i].longitude, places[i].lng);
      expect(result[i].title, '여행 · 장소 $i');
      expect(result[i].userId, 'owner');
      expect(result[i].collaboratorIds, ['friend']);
      if (i > 0) expect(result[i].startTime, result[i - 1].endTime);
    }
  });
  test('Rejects empty places and intervals too short for all places', () {
    final start = DateTime(2026);
    for (final items in [<MarkerModel>[], places]) {
      expect(
          () => buildListSchedules(
              places: items,
              userId: 'owner',
              title: '여행',
              start: start,
              end: start.add(const Duration(minutes: 2))),
          throwsArgumentError);
    }
  });
}
