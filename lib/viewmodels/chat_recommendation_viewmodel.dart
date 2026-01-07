import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class ChatRecommendationViewModel extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  String currentMode = ''; // 'place', 'itinerary', ''

  void startNewSession(String mode) {
    messages.clear();
    currentMode = mode;

    String welcomeMsg = mode == 'place'
        ? "🗺️ 장소 추천 모드 시작!\n어떤 지역이나 테마의 장소를 알려드릴까요?\n예: 제주도 해변, 서울 야경 명소, 아이와 가기 좋은 카페"
        : "🗓️ 여행 일정 추천 모드 시작!\n여행지, 기간, 인원, 테마를 알려주세요!\n예: 부산 2박3일 커플 여행, 제주도 4일 가족 여행";

    messages.add({'role': 'bot', 'text': welcomeMsg});
    notifyListeners();
  }

  Future<void> sendMessage(String userInput) async {
    if (userInput.trim().isEmpty) return;

    messages.add({'role': 'user', 'text': userInput});
    isLoading = true;
    notifyListeners();

    String prefixedInput = currentMode == 'place'
        ? "[장소 추천 모드] $userInput"
        : "[여행 일정 추천 모드] $userInput";

    final response = await _geminiService.sendMessage(prefixedInput);

    messages.add({'role': 'bot', 'text': response});
    isLoading = false;
    notifyListeners();
  }

  void reset() {
    messages.clear();
    currentMode = '';
    notifyListeners();
  }
}