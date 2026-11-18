/// 명시적인 장소 제목만 연결하며 본문에 언급된 이름은 연결 대상으로 보지 않습니다.
class PlaceAnswerSection {
  const PlaceAnswerSection(this.text, [this.place]);
  final String text;
  final Map<String, dynamic>? place;
}

List<PlaceAnswerSection> splitPlaceAnswer(
    String message, List<Map<String, dynamic>> places) {
  final sections = <PlaceAnswerSection>[];
  final used = <Map<String, dynamic>>{};
  final lines = <String>[];
  Map<String, dynamic>? active;
  void flush() {
    final text = lines.join('\n').trim();
    if (text.isNotEmpty || active != null) {
      sections.add(PlaceAnswerSection(text, active));
    }
    lines.clear();
    active = null;
  }

  for (final line in message.split('\n')) {
    final trimmed = line.trim();
    final match = RegExp(r'^[•*\-]\s*(?:추천 장소:\s*)?(.+?)\s*\(검증됨\)\s*$')
            .firstMatch(trimmed) ??
        RegExp(r'^📍\s*(.+)$').firstMatch(trimmed) ??
        RegExp(r'^\[\s*(.+?)\s*\(검증됨\)\s*\]$').firstMatch(trimmed);
    if (match != null) {
      flush();
      final title = match.group(1)!.trim();
      final matches = places
          .where((p) =>
              p['title']?.toString().trim() == title && !used.contains(p))
          .toList();
      if (matches.length == 1) {
        active = matches.single;
        used.add(active!);
      }
    } else if (trimmed.startsWith('검증됨은') || trimmed.startsWith("'(검증됨)'은")) {
      flush();
    }
    lines.add(line);
  }
  flush();
  // 공급자가 예상과 다른 형식을 사용해도 검증된 장소 카드를 유지합니다.
  for (final place in places.where((p) => !used.contains(p))) {
    sections.add(PlaceAnswerSection('', place));
  }
  return sections;
}
