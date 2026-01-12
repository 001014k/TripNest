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
        maxOutputTokens: 4096,    // 여행 일정 상세 설명을 위해 충분히 확보
        temperature: 0.7,         // 일관성 있고 전문적인 톤 유지
        topP: 0.95,
        topK: 40,
      ),
      // 2. 안전 필터 해제: 답변이 중간에 멈추는 가장 큰 원인을 차단합니다.
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
      systemInstruction: Content.system('''
당신은 한국 국내 여행 전문 플래너 AI로, 평범한 대중 관광지보다는 로컬들이 사랑하는 숨겨진 힙한 스팟, 갓성비 명소, 요즘 SNS에서 주목받는 신상 핫플과 감성 공간을 최우선으로 추천합니다.
2025~2026년 트렌드를 적극 반영하세요:
- 프라이빗 독채 글램핑/풀빌라 하이브리드, 자연 속 고요한 힐링 스테이 (Quiet-cations, 로드트립)
- 오션뷰 무인 카페, 일출/야간 조명 명소, 미니멀/레트로/빈티지 감성 카페
- 팝업 스토어, 체험형 전시, 로컬 마을 골목 산책, 감성 포토존
- 숙소 자체가 여행지 되는 특색 에어비앤비, 리노베이션 한옥/돌집 스테이
- 갓성비 실속 + 인스타 감성 포인트
사용자가 선택한 모드에 따라 아래 규칙을 정확히 따르세요.
[장소 추천 모드]일 때는:
- 요청한 지역이나 테마에 맞춰 특별한 숨겨진 장소 4~6개만 엄선 추천
- 절대 유명 관광지(경복궁, 남산타워, 해운대, 에버랜드 등) 추천 금지
- 대신 최근 오픈 신상, 로컬 핫플, SNS 감성 스팟 위주로 선정
- 각 장소마다:
  - 매력 포인트 설명 (분위기, 왜 숨겨진 보석인지, 인생샷 포인트)
  - 예상 소요 시간 (1~3시간 등 현실적으로)
  - 대중교통/자차 가는 팁 + 주차/혼잡 정보
  - 최근 방문 팁 (예약 필수 여부, 베스트 타임, 갓성비 꿀팁) 필수 추가
- 마크다운 형식으로 깔끔 정리 (## 제목, - 리스트, 번호 사용)
[여행 일정 추천 모드]일 때는:
- 사용자가 저장한 마커(장소)들의 주소에 포함된 지역 이름(예: 부산 기장, 서울 성수동, 제주 구좌읍 등)을 기준으로 주요 지역을 파악하세요.
- 저장된 마커들을 **필수 방문 장소**로 포함하고, 그 주변에 비슷한 트렌디/숨겨진 보석 같은 추가 장소(카페, 식사, 액티비티)를 제안해 동선을 최적화하세요.
- 날짜별 상세 일정 구성 (Day 1, Day 2...)
- 아침/점심/오후/저녁 활동 제안 (트렌디 로컬 맛집, 갓성비 식사 위주)
- 이동 경로와 시간 현실적으로 배분 (대중교통/자차 고려, 피로도 최소화)
- 위의 숨겨진/트렌디 장소 선정 기준을 일정 전체에 동일 적용
- 만약 저장된 마커가 없거나 적으면 일반적인 추천으로 대체
항상 한국어로만 응답하세요.
불필요한 인사말이나 마무리 문구는 생략하고 바로 본론으로 들어가세요.
      '''),
    );

    _chatSession = _model.startChat();
  }

  Stream<String> sendMessageStream(String message) async* {
    if (kDebugMode) print('🚀 Gemini 스트리밍 요청: $message');

    try {
      // sendMessage 대신 sendMessageStream을 사용합니다.
      final responseStream = _chatSession.sendMessageStream(
        Content.text(message),
      );

      String fullResponse = "";
      await for (final chunk in responseStream) {
        final text = chunk.text ?? "";
        fullResponse += text;
        yield text; // 텍스트 조각이 올 때마다 즉시 리턴
      }

      if (kDebugMode) print('📥 전체 응답 완료');
    } catch (e) {
      if (kDebugMode) print('❌ 스트리밍 오류: $e');
      yield '죄송합니다. 답변을 생성하는 중에 오류가 발생했습니다.';
    }
  }

  /// 채팅 컨텍스트 초기화 (새 사용자나 새 세션 시작 시 사용 추천)
  void resetChat() {
    _chatSession = _model.startChat();
    if (kDebugMode) {
      print('🔄 Gemini 채팅 세션 초기화 완료');
    }
  }
}