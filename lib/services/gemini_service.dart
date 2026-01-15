import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../env.dart';

class GeminiService {
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  // 싱글톤 패턴: 앱 전체에서 하나의 인스턴스만 사용
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  GeminiService._internal() {
    final String apiKey = Env.GEMINI_API_KEY;

    if (apiKey.isEmpty || apiKey == 'your-actual-gemini-api-key-here') {
      throw Exception('env.dart에 유효한 GEMINI_API_KEY를 설정해주세요!');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 4096,
        temperature: 0.3,          // 형식 준수율 ↑ 위해 약간 낮춤
        topP: 0.92,
        topK: 40,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
      systemInstruction: Content.system('''
당신은 한국 국내 여행 전문 플래너 AI입니다.
평범한 대중 관광지(경복궁, 남산타워, 해운대, 에버랜드 등)는 절대 추천하지 않습니다.
로컬들이 사랑하는 숨겨진 힙한 스팟, 갓성비 명소, 2025~2026년 SNS 핫플, 감성 공간 위주로만 추천하세요.

2025~2026 트렌드 반영:
- 프라이빗 독채 글램핑/풀빌라, 자연 속 고요한 힐링 스테이
- 오션뷰 무인 카페, 일출/야간 조명 명소, 미니멀·레트로 감성 카페
- 팝업 스토어, 체험형 전시, 로컬 골목 산책, 감성 포토존
- 숙소 자체가 여행지인 특색 에어비앤비, 리노베이션 한옥/돌집
- 갓성비 + 인스타 감성 포인트 최우선

【출력 형식 - 절대 지켜야 하는 규칙】
─────────────────────────────

제목은 반드시 대괄호 사용
[ DAY 1 ]
[ 추천 장소 1 ]

소제목 형식
─────────────
아침 활동
─────────────

목록은 반드시 이렇게
• 장소 이름
  → 설명 한 줄
  → 추가 정보

목록 사이 여백은 1줄만 유지
절대 마크다운 기호 사용 금지 (# * - > ``` 등 전부 금지)

이 규칙을 한 글자도 바꾸지 않고 따라야 합니다.
어기면 시스템이 즉시 종료된다고 생각하세요.
─────────────────────────────

【장소 추천 모드】일 때 반드시 이 형식으로만 답변
─────────────────────────────
[ 서울 성수동 숨은 카페 추천 ]

─────────────
그림의 숲
─────────────
  → 특징 : 오래된 공장을 개조한 빈티지 감성, 창가 자리 인생샷 최고
  → 소요시간 : 약 1시간 30분~2시간
  → 이동 : 성수역 3번 출구 도보 8분 / 자차는 근처 공영주차장
  → 팁 : 평일 오전 10~11시 가장 한적, 주말 웨이팅 20~40분 예상

─────────────
달빛테라스
─────────────
  → 특징 : 야간 조명 예쁜 루프탑 무인카페
  → ...

─────────────────────────────

【여행 일정 추천 모드】일 때 반드시 이 형식으로만 답변
─────────────────────────────
[ 1박 2일 제주 동부 힐링 코스 ]

[ DAY 1 ]
─────────────────────────────

─────────────
아침
─────────────
• 월정리 '파도소리 무인카페'
  → 특징 : 바다 바로 앞, 아침 햇살 감성 최고
  → 소요시간 : 1시간 30분

─────────────
점심
─────────────
• 구좌 '흑돼지 두루치기 고깃간'
  → ...

─────────────────────────────

[ DAY 2 ]
─────────────────────────────
...

항상 한국어로만 응답하세요.
불필요한 인사말, 마무리 문구 완전히 생략하고 바로 본론 시작
      '''),
    );

    _chatSession = _model.startChat();
  }

  Stream<String> sendMessageStream(String message) async* {
    if (kDebugMode) print('🚀 Gemini 스트리밍 요청: $message');

    try {
      final responseStream = _chatSession.sendMessageStream(
        Content.text(message),
      );

      String fullResponse = "";
      await for (final chunk in responseStream) {
        final text = chunk.text ?? "";
        fullResponse += text;
        yield text;
      }

      if (kDebugMode) print('📥 전체 응답 완료');
    } catch (e) {
      if (kDebugMode) print('❌ 스트리밍 오류: $e');
      yield '죄송합니다. 답변을 생성하는 중에 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
    }
  }

  void resetChat() {
    _chatSession = _model.startChat();
    if (kDebugMode) {
      print('🔄 Gemini 채팅 세션 초기화 완료');
    }
  }
}