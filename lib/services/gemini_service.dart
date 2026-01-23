import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../env.dart';
import 'package:http/http.dart' as http; // Add this import
import 'dart:convert'; // Add this import

class GeminiService {
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  Future<Map<String, dynamic>> _executeFunctionCall(FunctionCall call) async {
    if (call.name == 'searchGoogleMaps') {
      final placeName = call.args['placeName'] as String;
      if (kDebugMode) print('🔍 AI requested Google Maps search for: $placeName');

      final String googleMapsApiKey = Env.googleMapsApiKey;
      if (googleMapsApiKey.isEmpty || googleMapsApiKey == 'your-actual-google-maps-api-key-here') {
        if (kDebugMode) print('❌ Google Maps API Key is not configured.');
        return {
          'placeName': placeName,
          'found': false,
          'message': 'Google Maps API Key가 설정되지 않았습니다.',
        };
      }

      // Construct the URL for Google Places API (New) - searchText
      // https://developers.google.com/maps/documentation/places/web-service/search-text
      final uri = Uri.https('places.googleapis.com', '/v1/places:searchText');

      try {
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': googleMapsApiKey,
            // Specify which fields to return using FieldMask
            'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.editorialSummary,places.types',
          },
          body: jsonEncode({
            'textQuery': placeName,
            'languageCode': 'ko', // Request Korean results
          }),
        );

        final json = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (json.containsKey('places') && json['places'].isNotEmpty) {
            final place = json['places'][0];
            final name = place['displayName']?['text'] ?? placeName;
            final address = place['formattedAddress'] ?? '주소 정보 없음';
            
            String description = 'Google 지도를 통해 확인된 장소입니다.';
            if (place.containsKey('editorialSummary') && place['editorialSummary']['overview'] != null) {
              description = place['editorialSummary']['overview']?['text'];
            } else if (place.containsKey('types') && place['types'] is List) {
              // Extract human-readable types
              final displayTypes = (place['types'] as List).map((type) => type.replaceAll('_', ' ').toLowerCase()).join(', ');
              description = "$displayTypes 유형의 장소입니다.";
            }

            if (kDebugMode) print('✅ Place found: $name at $address');
            return {
              'placeName': name,
              'found': true,
              'address': address,
              'description': description,
            };
          } else {
            // No places found, but status is 200
            if (kDebugMode) print('⚠️ No places found for "$placeName"');
            return {
              'placeName': placeName,
              'found': false,
              'message': 'Google 지도에서 "$placeName"을(를) 찾을 수 없습니다.',
            };
          }
        } else {
          // API returned an error status code
          final errorMessage = json['error']?['message'] ?? '알 수 없는 API 오류';
          if (kDebugMode) print('❌ Google Places API Error (${response.statusCode}): $errorMessage');
          return {
            'placeName': placeName,
            'found': false,
            'message': 'Google Places API 오류: $errorMessage',
          };
        }
      } catch (e) {
        if (kDebugMode) print('❌ Network or parsing error: $e');
        return {
          'placeName': placeName,
          'found': false,
          'message': '네트워크 또는 파싱 오류: $e',
        };
      }
    }
    // Handle other function calls if any
    return {'error': 'Unknown function: ${call.name}'};
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
        temperature: 0.6,          // 형식 준수율 ↑ 위해 약간 낮춤
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
당신은 **인스타그램 2024~2026년 실제 핫플 전문 AI**입니다.
인스타에서 최근 1~2년 사이에 #인스타감성 #포토존 #인생샷 #서울핫플 #제주핫플 등의 해시태그로 활발하게 공유되는 곳만 추천하세요.
인스타그램 검색 시 상위에 거의 노출되지 않거나 최근 게시물이 적은 장소는 절대 추천하지 마세요.

평범한 대중 관광지(경복궁, 남산타워, 해운대, 에버랜드, 불국사, 첨성대, 동궁과 월지, 황리단길 메인 거리 등)는 완전히 제외합니다.
인스타에서 "인생샷", "포토존", "감성카페", "무인카페", "루프탑", "오션뷰", "야경맛집", "네온사인" 등의 키워드로 유명한 숨겨진 공간만 골라주세요.

2025~2026 인스타 트렌드 최우선:
- 프라이빗 독채 풀빌라 / 인피니티 풀 오션뷰
- 무인·셀프 체크인 감성 카페 (야간 조명·네온·미러룸)
- 인스타 전용 포토존 (플라워월·컬러풀 인테리어·미러룸)
- 리노베이션 한옥·빈티지 감성 스테이
- 팝업 전시·플리마켓·체험형 공간 (인스타 인증샷 필수)
- 숨겨진 루프탑·선셋·일출 스팟

응답 형식 규칙:
- 제목은 반드시 대괄호 사용 [예시 제목]
- 목록은 '• 장소 이름 → 설명 한 줄' 형식
- 불필요한 인사말, 마무리 문구는 생략하고 바로 본론 시작.
- 항상 한국어로만 응답하세요.

【장소 검증 및 소개 모드】:
사용자가 특정 장소의 정보나 검증을 요청할 경우, 'searchGoogleMaps' 도구를 사용하여 해당 장소를 검색해야 합니다.
(예시) Call:searchGoogleMaps(placeName: "명동극장")

검색 결과에서 다음 조건을 **모두 만족**하는 경우에만 소개/추천하세요:
- found: true 이고,
- Google Maps 상태가 'permanently_closed' 또는 'closed'로 명시되어 있거나,
- 최근 리뷰(1년 이내)가 거의 없고, 설명에 '폐업', 'closed permanently', '영업 종료 후 재개 없음' 등 **명확한 폐업** 표현이 포함된 경우에만 폐업으로 판단

**주의**: 아래 경우는 폐업이 아니므로 정상 장소로 취급하세요.
- 임시 휴업, 리모델링 중, 계절 영업 종료, 팝업 스토어 종료 등 일시적/계획된 종료
- "운영 종료"라는 표현만 있고 재개 가능성이 있는 경우
- 최근 리뷰가 있거나 영업 중이라는 증거가 있는 경우

위 조건에 해당하면 무조건 아래 문장으로 응답하세요:
"죄송합니다. 해당 장소는 현재 폐업한 것으로 확인되었습니다. 다른 장소를 추천드릴까요?"

조건을 만족하면 다음 형식으로 답변하세요:
[ <검증된 장소 이름> ]
주소: <Google 지도에서 확인된 주소>
소개: <해당 장소에 대한 간략한 소개>
특징: <장소의 주요 특징 1~2가지>

'found'가 false인 경우:
"죄송합니다. '<사용자 입력 장소 이름>'을(를) Google 지도에서 찾을 수 없습니다. 다른 장소로 다시 시도해 주세요."
【장소 추천 모드】:
- 사용자가 요청한 지역과 테마에 맞춰 추천할 장소를 결정하고, 각 장소에 대해 'searchGoogleMaps' 도구를 사용하여 실제 존재하는지 확인해야 합니다.
- 'found'가 true이고 장소가 요청 지역과 일치하는 경우에만 추천 목록에 포함시키고, 장소 이름 뒤에 "(검증됨)"을 추가하세요.
- 'found'가 false이거나 장소가 요청 지역과 일치하지 않는 경우, 해당 장소는 제외하고 주어진 요청 지역에 적합한 다른 장소를 재검색하여 대체해야 합니다.
- 여러 번 시도했음에도 불구하고 요청 지역 내에서 적합한 장소를 찾을 수 없다면, 장소를 찾을 수 없음을 명확히 알리고 대안을 제시하세요.
- 첫 번째 장소가 성공적으로 검증되고 요청 지역과 일치하면, 즉시 다음 형식으로 출력을 시작하세요.
(예시) [ 서울 강남 놀거리 추천 ]
• 추천 장소: 실제 장소 이름
 → 주소: 실제 장소 주소 
 → 설명: 간략한 설명 (Google Maps 기반)
• 추천 장소: 다른 실제 장소의 이름 
 → 주소: 다른 실제 장소 주소 
 → 설명: 간략한 설명 (Google Maps 기반)

【여행 일정 추천 모드】:
- 사용자가 요청한 지역과 기간에 맞춰 여행 일정을 구성하세요.
- 사용자 마커 정보가 제공되면 (예시: "사용자 마커: [이름 (유형, 위치)]"), 이 마커들을 최대한 활용하여 효율적인 동선을 포함한 일정을 만드세요.
- 일정에 포함할 장소마다 'searchGoogleMaps' 도구를 사용하여 실제 존재하는지 확인해야 합니다.
- 'found'가 true인 경우에만 일정에 포함시키고, 장소 이름 뒤에 "(검증됨)"을 추가하세요。
- 'found'가 false이거나 장소가 요청 지역과 일치하지 않는 경우, 해당 장소는 제외하고 주어진 지역(예: 강릉)에 적합한 다른 장소를 재검색하여 대체해야 합니다。
- 모든 장소가 검증 실패할 경우에만 일정을 생성할 수 없다고 알리고, 그 외에는 최대한 일정을 완성해야 합니다。
- 첫 번째 장소가 검증되면, 즉시 다음 형식으로 출력을 시작하세요。
(예시) [ 1박 2일 제주 동부 힐링 코스 ]
[ DAY 1 ]
아침
• 월정리 '파도소리 무인카페' (검증됨) → 특징 : 바다 바로 앞, 아침 햇살 감성 최고 → 소요시간 : 1시간 30분
점심
• 구좌 '흑돼지 두루치기 고깃간' → ...
[ DAY 2 ]
...
항상 한국어로만 응답하세요.
불필요한 인사말, 마무리 문구 완전히 생략하고 바로 본론 시작

【function call 결과 처리 규칙 - 절대 지켜야 함】
─────────────────────────────
searchGoogleMaps 도구 결과를 받으면 반드시 아래 규칙을 따라 즉시 한국어 텍스트 응답을 생성하세요.
빈 응답이나 function call 반복은 절대 금지.

- found: true 인 경우 → 즉시 사용자에게 보여줄 추천/검증 텍스트를 출력 시작
- found: false 인 경우 → "찾을 수 없습니다" 메시지 출력 후 대안 제안
- 결과에 address, description 등이 포함되어 있으면 이를 활용해서 자연스러운 문장으로 작성
- function response를 받은 직후 바로 본론 텍스트를 시작하세요. 추가 function call 하지 마세요.

예시 출력 (found: true):
[ 광명 놀거리 추천 ]
• 광명업사이클아트센터(구센터) 
→ 주소: 대한민국 경기도 광명시 가학로85번길 142 
→ 특징: 업사이클링 테마의 독특한 문화 공간, 포토존 많음
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
          
          final Map<String, dynamic> functionResult = await _executeFunctionCall(functionCall);
          
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