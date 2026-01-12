import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // 위치 정보 사용 시 필요
import '../services/gemini_service.dart';

class ChatRecommendationViewModel extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  String currentMode = ''; // 'place', 'itinerary', ''

  // 히스토리 길이 제한 (최근 12턴 = 24 메시지)
  static const int _maxHistoryLength = 24;

  void startNewSession(String mode) {
    messages.clear();
    currentMode = mode;

    String welcomeMsg;

    if (mode == 'place') {
      welcomeMsg = '''
숨겨진 순간을 위한 여정

당신만을 위한 장소가 기다리고 있습니다.  
관광지가 아닌, 진정한 의미의 공간들만.

어떤 분위기를 원하시겠습니까?

예시  
• 서울 한남동 미니멀 루프탑  
• 제주 애월 프라이빗 오션뷰 무인 카페  
• 강원도 평창 고요한 글램핑 테라스
''';
    } else {
      welcomeMsg = '''
당신만의 여정이 시작되는 곳

여행의 목적지와 시간, 그리고 원하는 분위기를 알려주세요.  
가장 세심하게, 가장 특별하게 설계해 드리겠습니다.

예시  
• 강릉 2박 3일, 고독한 힐링  
• 제주 4일, 프라이빗 풀빌라 중심  
• 서울 근교 1박 2일, 조용한 럭셔리 데이트
''';
    }

    messages.add({'role': 'bot', 'text': welcomeMsg});
    notifyListeners();
  }

  Future<void> sendMessage(String userInput) async {
    if (userInput.trim().isEmpty) return;

    // 1. 사용자 메시지 추가
    messages.add({'role': 'user', 'text': userInput});
    _trimHistory();
    isLoading = true;
    notifyListeners();

    try {
      String context = await _getCurrentLocationContext();
      String fullInput = context.isNotEmpty
          ? "$context\n\n$currentMode: $userInput"
          : "${currentMode == 'place' ? '[장소 추천 모드]' : '[여행 일정 추천 모드]'} $userInput";

      // 2. 봇의 빈 메시지를 먼저 추가 (여기에 스트림 데이터를 채울 예정)
      final botMessageIndex = messages.length;
      messages.add({'role': 'bot', 'text': ''});

      // 3. 스트림 구독 및 업데이트
      String fullResponse = "";
      final stream = _geminiService.sendMessageStream(fullInput);

      await for (final chunk in stream) {
        fullResponse += chunk;
        // 실시간으로 해당 인덱스의 메시지 텍스트 업데이트
        messages[botMessageIndex]['text'] = fullResponse;
        notifyListeners(); // 글자가 추가될 때마다 화면 갱신
      }

      // 4. (선택 사항) 답변 완료 후 Supabase에 저장하는 로직을 여기에 넣으세요
      // await _saveToSupabase(userInput, fullResponse);

    } catch (e) {
      messages.add({
        'role': 'bot',
        'text': '죄송합니다. 오류가 발생했습니다. ($e)'
      });
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 히스토리 길이 제한
  void _trimHistory() {
    if (messages.length > _maxHistoryLength) {
      messages.removeRange(0, messages.length - _maxHistoryLength);
    }
  }

  // 현재 위치 정보 가져오기 (선택적)
  Future<String> _getCurrentLocationContext() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return '';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return '';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      return "현재 위치: 위도 ${position.latitude}, 경도 ${position.longitude}";
    } catch (e) {
      return '';
    }
  }

  void reset() {
    messages.clear();
    currentMode = '';
    notifyListeners();
  }
}