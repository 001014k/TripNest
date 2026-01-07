import 'package:google_generative_ai/google_generative_ai.dart';
import '../../env.dart';  // Supabase와 동일한 방식

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  // 싱글톤 패턴: 앱 전체에서 하나의 인스턴스만 사용 (토큰/비용 관리에 좋음)
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal() {
    // env.dart에서 직접 가져오기
    final String apiKey = Env.GEMINI_API_KEY;

    if (apiKey.isEmpty || apiKey == 'your-actual-gemini-api-key-here') {
      throw Exception('env.dart에 유효한 GEMINI_API_KEY를 설정해주세요!');
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',  // 비용 효율 최고 + 빠름
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 700,   // 충분히 상세하면서 토큰 절약
        temperature: 0.8,
      ),
      systemInstruction: Content.system('''
당신은 친절하고 전문적인 한국 여행 플래너 AI입니다.
사용자가 선택한 모드에 따라 정확하고 실용적인 추천을 해주세요.

[장소 추천 모드]일 때는:
- 해당 지역이나 테마에 맞는 개별 장소 4~6개 추천
- 각 장소에 간단 설명, 소요 시간, 가는 팁 포함
- 마크다운 형식으로 깔끔하게 정리

[여행 일정 추천 모드]일 때는:
- 날짜별 상세 일정 구성 (Day 1, Day 2...)
- 아침/점심/오후/저녁 활동 제안
- 이동 경로, 식사 추천 포함
- 현실적인 시간 배분 고려

항상 한국어로만 응답하고, 불필요한 인사말이나 과도한 설명은 줄이세요.
'''),
    );

    _chatSession = _model.startChat();
  }

  /// 사용자 메시지 전송하고 AI 응답 받기
  Future<String> sendMessage(String message) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      return response.text ?? '응답을 생성하지 못했습니다.';
    } catch (e) {
      return 'AI 호출 중 오류 발생: $e';
    }
  }
}