/// Google Places uses Sunday=0 and separate hour/minute fields.
class PlaceHours {
  static const days = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
  static const english = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  static List<String> weekly(Map<String, dynamic>? hours) => [
        for (final day in [1, 2, 3, 4, 5, 6, 0])
          '${days[day]}\n${forDay(hours, day)}'
      ];

  static String forDay(Map<String, dynamic>? hours, int day) {
    if (hours == null) return '영업시간 정보 없음';
    for (final description in (hours['weekdayDescriptions'] as List? ?? [])) {
      final text = description.toString();
      final match = RegExp(
              '^(?:${days[day]}|${english[day]})\\s*[:：]\\s*(.*)\$',
              caseSensitive: false)
          .firstMatch(text);
      if (match != null) return match.group(1)!;
    }
    final periods = hours['periods'] as List?;
    if (periods == null) return '영업시간 정보 없음';
    final intervals = <String>[];
    for (final period in periods) {
      final open = period['open'] as Map?;
      final close = period['close'] as Map?;
      if (open == null) continue;
      if (open['day'] == 0 &&
          open['hour'] == 0 &&
          (open['minute'] ?? 0) == 0 &&
          close == null) {
        return '24시간 영업';
      }
      if (open['day'] != day) continue;
      final start = _time(open);
      if (start == null) continue;
      final end = close == null ? null : _time(close);
      intervals.add(end == null
          ? '$start ~'
          : '$start - ${close!['day'] != day ? '다음날 ' : ''}$end');
    }
    return intervals.isEmpty ? '휴무' : intervals.join(', ');
  }

  static String? _time(Map point) {
    if (point['hour'] is! num) return null;
    return '${point['hour'].toString().padLeft(2, '0')}:${(point['minute'] ?? 0).toString().padLeft(2, '0')}';
  }
}
