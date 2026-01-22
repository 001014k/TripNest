import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../env.dart';

class GeminiService {
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  // Simulated function for Google Maps search
  Map<String, dynamic> _executeFunctionCall(FunctionCall call) {
    if (call.name == 'searchGoogleMaps') {
      final placeName = call.args['placeName'] as String;
      if (kDebugMode) print('🔍 AI requested Google Maps search for: $placeName');
      // Simulate Google Maps search result
      if (placeName.contains('명동') || placeName.contains('서울') || placeName.contains('N서울타워')) {
        // Keep existing logic for Seoul places
        return {
          'placeName': placeName,
          'found': true,
          'address': '$placeName 주소 (시뮬레이션)',
          'description': '$placeName에 대한 설명 (시뮬레이션)',
        };
      } else if (placeName.contains('강릉') || placeName.contains('영진해변') || placeName.contains('안목해변') || placeName.contains('초당순두부')) {
        // Add logic for Gangneung places
        return {
          'placeName': placeName,
          'found': true,
          'address': '$placeName 강원도 강릉시 (시뮬레이션)',
          'description': '$placeName은 강릉의 유명 장소입니다. (시뮬레이션)',
        };
      } else if (placeName.contains('경주') || placeName.contains('황리단길') || placeName.contains('첨성대') || placeName.contains('불국사')) {
        // Add logic for Gyeongju places
        return {
          'placeName': placeName,
          'found': true,
          'address': '$placeName 경상북도 경주시 (시뮬레이션)',
          'description': '$placeName은 경주의 유명 장소입니다. (시뮬레이션)',
        };
      } else if (_isKnownRegion(placeName)) { // <--- Correctly placed now
        // Generic logic for other known regions
        return {
          'placeName': placeName,
          'found': true,
          'address': '$placeName 대한민국 (시뮬레이션)',
          'description': '$placeName은(는) 대한민국 내 유명 장소입니다. (시뮬레이션)',
        };
      }
      else {
        return {
          'placeName': placeName,
          'found': false,
          'message': 'Google 지도에서 "$placeName"을(를) 찾을 수 없습니다.',
        };
      }
    }
    // Handle other function calls if any
    return {'error': 'Unknown function: ${call.name}'};
  }

  bool _isKnownRegion(String placeName) {
    final knownRegions = [
      '부산', '대구', '인천', '광주', '대전', '울산', '세종', '제주', '전주', '여수', '통영', '속초', '안동', '단양', '수원', '용인', '고양', '창원', '성남', '청주', '천안', '전주', '포항', '김해', '구미', '아산', '익산', '원주', '순천', '춘천', '목포', '진주', '군산', '서산', '광명', '김천', '제천', '공주', '나주', '상주', '양산'
    ]; // Add more as needed

    final lowerCasePlaceName = placeName.toLowerCase();
    for (final region in knownRegions) {
      if (lowerCasePlaceName.contains(region.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

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
        maxOutputTokens: 8192,
        temperature: 0.3,          // 형식 준수율 ↑ 위해 약간 낮춤
        topP: 0.92,
        topK: 40,
      ),
      tools: [
        Tool(functionDeclarations: [
          FunctionDeclaration(
            'searchGoogleMaps',
            'Searches for a place on Google Maps and returns its verification status and basic details.',
            Schema.object(
              properties: {
                'placeName': Schema.string(
                  description: 'The name of the place to search for on Google Maps.',
                )
              },
            ),
          )
        ])
      ],
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
      systemInstruction: Content.system('''
당신은 한국 국내 여행 전문 플래너 AI입니다.
서울, 경기 등 대도시를 포함하여 전국 어디든 좋지만, 누구나 아는 평범한 대중 관광지(경복궁, 남산타워, 해운대, 에버랜드 등)는 제외하고 추천해 주세요.
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

【장소 검증 및 소개 모드】:
사용자가 특정 장소의 정보나 검증을 요청할 경우, 'searchGoogleMaps' 도구를 사용하여 해당 장소를 검색해야 합니다.

<searchGoogleMaps 도구 사용 예시>
사용자가 "명동극장" 정보를 요청하면 다음과 같이 도구를 호출합니다:
Call:searchGoogleMaps(placeName: "명동극장")

도구의 응답(response)을 받은 후, 'found' 값이 true인 경우 해당 장소의 'address'와 'description'을 활용하여 다음 형식으로 답변합니다.
─────────────────────────────
[ <검증된 장소 이름> ]

─────────────
주소
─────────────
→ <Google 지도에서 확인된 주소>

─────────────
소개
─────────────
→ <해당 장소에 대한 간략한 소개>

─────────────────────────────

'found' 값이 false인 경우, 다음 형식으로 답변합니다.
─────────────────────────────
[ <검색 실패> ]

─────────────
결과
─────────────
→ 죄송합니다. ' <사용자 입력 장소 이름> '을(를) Google 지도에서 찾을 수 없습니다. 다른 장소로 다시 시도해 주세요.
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
- 사용자가 요청한 지역과 기간에 맞춰 여행 일정을 구성하세요.
- 일정에 포함할 장소를 결정할 때마다 'searchGoogleMaps' 도구를 사용하여 해당 장소가 실제로 존재하는지 확인해야 합니다.
- 도구 응답에서 'found'가 true인 경우에만 일정에 포함시키고, 장소 이름 뒤에 "(검증됨)" 표시를 추가하세요.
- 만약 'found'가 false인 장소는 해당 일정에서 제외하고, 주어진 지역(예: 강릉)에 적합한 다른 장소를 찾아 대체해야 합니다.
- 모든 장소가 검증 실패할 경우에만 일정을 생성할 수 없다고 알리고, 그 외에는 최대한 일정을 완성해야 합니다.
- 첫 번째 장소가 검증되면, 즉시 아래 '【여행 일정 추천 모드 예시】'와 동일한 형식으로 일정을 출력하기 시작해야 합니다.

─────────────────────────────
[ 1박 2일 제주 동부 힐링 코스 ]

[ DAY 1 ]
─────────────────────────────

─────────────
아침
─────────────
• 월정리 '파도소리 무인카페' (검증됨)
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
        final functionCall = chunk.candidates.firstOrNull?.content.parts
            .whereType<FunctionCall>()
            .firstOrNull;

        if (functionCall != null) {
          // AI wants to call a function
          if (kDebugMode) print('🛠️ AI requested function call: ${functionCall.name} with args: ${functionCall.args}');
          
          final Map<String, dynamic> functionResult = _executeFunctionCall(functionCall);
          
          // Send the function result back to the model
          if (kDebugMode) print('↩️ Sending function result back to AI: $functionResult');
          final toolResponseStream = _chatSession.sendMessageStream(
            Content.functionResponse(functionCall.name, functionResult),
          );

          await for (final toolResponseChunk in toolResponseStream) {
            final text = toolResponseChunk.text ?? '';
            fullResponse += text;
            yield text;
          }

        } else {
          // Regular text response
          final text = chunk.text ?? "";
          fullResponse += text;
          yield text;
        }
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