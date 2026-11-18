import 'package:google_generative_ai/google_generative_ai.dart';

/// 모든 도구 호출·응답 쌍을 포함한 사용자 대화 턴을 온전히 유지합니다.
/// 오래된 큰 턴은 통째로 제거하며, 최신 턴도 크기 제한을 넘으면
/// 함수 호출·응답을 잘라 보내는 대신 통째로 제거합니다.
List<Content> boundedPlannerHistory(Iterable<Content> history,
    {int maxTurns = 12, int maxCharacters = 24000}) {
  final turns = <List<Content>>[];
  for (final content in history) {
    if (content.role == 'user' && content.parts.any((p) => p is TextPart)) {
      turns.add([]);
    }
    if (turns.isNotEmpty) turns.last.add(content);
  }
  final kept = <List<Content>>[];
  var characters = 0;
  for (final turn in turns.reversed) {
    final last = turn.last;
    if (last.role != 'model' || last.parts.any((p) => p is FunctionCall)) {
      continue;
    }
    final size =
        turn.fold<int>(0, (sum, c) => sum + c.toJson().toString().length);
    if (kept.length >= maxTurns || characters + size > maxCharacters) break;
    kept.add(turn);
    characters += size;
  }
  return kept.reversed.expand((turn) => turn).toList();
}
