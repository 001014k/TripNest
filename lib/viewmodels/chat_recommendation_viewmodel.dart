import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertrip/views/markercreationscreen_view.dart';
import 'package:geolocator/geolocator.dart'; // 위치 정보 사용 시 필요
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/gemini_service.dart';
import '../services/places_service.dart';
import '../viewmodels/mapsample_viewmodel.dart';

class ChatRecommendationViewModel extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final MapSampleViewModel? mapSampleViewModel;

  // 채팅 내역 및 상태 초기화
  void resetChat() {
    messages.clear();           // 대화 내역 삭제
    pendingPlaces.clear();      // 추천 대기 장소 삭제
    currentMode = '';           // 선택된 모드 초기화
    _geminiService.resetChat(); // Gemini 세션 초기화 (gemini_service에 정의됨)
    notifyListeners();          // UI 갱신 (Stage 1으로 복귀)
  }

  ChatRecommendationViewModel({this.mapSampleViewModel});

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  String currentMode = ''; // 'place', 'itinerary', ''
  List<Map<String, dynamic>> pendingPlaces = []; // 아직 저장 안 한 추천 장소들
  List<Map<String, dynamic>> recentRecommendations = [];
  String _lastUserQuery = "";

  // 히스토리 길이 제한 (최근 12턴 = 24 메시지)
  static const int _maxHistoryLength = 24;

  // 초기화 시 호출하거나 사용자가 진입할 때 호출
  Future<void> loadRecentRecommendations() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('ai_recommendations')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);

      recentRecommendations = List<Map<String, dynamic>>.from(response);
      notifyListeners(); // UI에 데이터 로드 알림
    } catch (e) {
      if (kDebugMode) print('❌ 최근 추천 불러오기 실패: $e');
    }
  }

  // 특정 과거 이력을 클릭했을 때 화면에 즉시 뿌려주는 메서드
  void loadRecentRecommendation(Map<String, dynamic> record) {
    // 1. 화면 초기화 (Stage 1 -> Stage 2 전환 준비)
    messages.clear();
    pendingPlaces.clear();

    // 2. 데이터 추출 (DB 컬럼명에 맞춰 가져오기)
    final String title = record['title'] ?? '과거 추천';
    final List<dynamic> savedPlaces = record['recommendation_data'] ?? [];

    // 3. 메시지 스택 복구
    // 사용자가 했던 질문 복구
    messages.add({'role': 'user', 'text': title});

    // AI가 했던 답변 형식으로 다시 구성 (또는 저장된 요약문이 있다면 그것을 사용)
    String restoredResponse = "'$title'에 대한 이전 추천 결과입니다.\n\n";
    for (var place in savedPlaces) {
      restoredResponse += "📍 ${place['title']}\n${place['snippet'] ?? ''}\n\n";
    }

    messages.add({
      'role': 'bot',
      'text': restoredResponse
    });

    // 4. 지도 마커 데이터 즉시 복구 (이게 핵심!)
    // 이미 verifiedPlacesWithCoords 형태로 저장되어 있으므로 다시 API 호출할 필요 없음
    pendingPlaces = List<Map<String, dynamic>>.from(savedPlaces);

    // 5. UI 갱신 (vm.messages.isEmpty가 false가 되어 채팅창 Stage로 자동 전환됨)
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchRecentRecommendations() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('ai_recommendations')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(5);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _handleAiResponse(String fullResponse) async {
    if (kDebugMode) {
      print("--- AI's Full Response ---");
      print(fullResponse);
      print("--------------------------");
    }

    // 1. AI 응답에서 장소 데이터 파싱
    final parsedPlacesData = _parsePlaceDetailsFromResponse(fullResponse);
    if (parsedPlacesData.isEmpty) {
      if (kDebugMode) print('⚠️ 파싱된 장소 데이터가 없습니다.');
      return;
    }

    // 2. Google Maps API를 통한 좌표 검증 및 데이터 생성
    final placesService = PlacesService();
    final List<Map<String, dynamic>> verifiedPlacesWithCoords = [];

    for (final parsedPlace in parsedPlacesData) {
      final placeTitle = parsedPlace['title'] as String;
      final placeDetailsList = await placesService.searchPlacesByKeyword(placeTitle);

      if (placeDetailsList.isNotEmpty) {
        final placeDetails = placeDetailsList.first;
        final location = placeDetails['location'];
        if (location != null) {
          verifiedPlacesWithCoords.add({
            'title': parsedPlace['title'],
            'address': parsedPlace['address'],
            'snippet': parsedPlace['snippet'],
            'lat': location['latitude'],
            'lng': location['longitude'],
            'keyword': parsedPlace['title'],
          });
        }
      }
    }

    // 3. 뷰모델 상태 업데이트 (UI 표시용)
    pendingPlaces = verifiedPlacesWithCoords;
    notifyListeners();

    // 4. DB 저장 (lastUserMessage 대신 _lastUserQuery 사용)
    if (pendingPlaces.isNotEmpty) {
      await _saveRecommendation(_lastUserQuery, pendingPlaces);
    }
  }

  List<Map<String, dynamic>> _parsePlaceDetailsFromResponse(String text) {
    final List<Map<String, dynamic>> places = [];
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    String? currentName;
    String? currentAddress;
    List<String> currentDescLines = [];

    // 1. 검증 모드 패턴 (이번 로그처럼 나올 때)
    final RegExp verifyModeRegex = RegExp(
      r'\[(.+?)\]\s*'                             // [ 장소 이름 ]
      r'주소:\s*(.+?)(?:\n|$)'                    // 주소: ...
      r'(?:설명:\s*(.+?))?',                      // 설명: ...
      multiLine: true,
      dotAll: true,
    );

    final verifyMatches = verifyModeRegex.allMatches(text);

    for (final match in verifyMatches) {
      final name = match.group(1)?.replaceAll('(검증됨)', '').trim();
      final address = match.group(2)?.trim();
      final snippet = match.group(3)?.trim() ?? '';

      if (name != null && address != null) {
        places.add({
          'title': name,
          'address': address,
          'snippet': snippet.isNotEmpty ? snippet : '인스타 감성 장소',
        });
        if (kDebugMode) {
          print('검증 모드 파싱 성공: $name → $address');
        }
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 장소 이름 감지 (•, *, - 등 다양한 시작 기호 허용 + (검증됨) 포함)
      if (RegExp(r'^[•\*\-]\s*.+\(검증됨\)').hasMatch(line)) {
        // 이전 장소 저장
        if (currentName != null && currentAddress != null) {
          final desc = currentDescLines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
          places.add({
            'title': currentName.replaceAll(RegExp(r'[\uFEFF﻿]'), '').trim(),
            'address': currentAddress,
            'snippet': desc.isNotEmpty ? desc : '설명 없음',
          });
        }

        // 새 장소 시작
        currentName = line
            .replaceAll(RegExp(r'^[•\*\-]\s*'), '')
            .replaceAll('(검증됨)', '')
            .trim();
        currentAddress = null;
        currentDescLines = [];
        continue;
      }

      // 주소 라인 감지 (주소:, 주소 : , >주소 등)
      if (line.contains('주소') || line.contains('address')) {
        String addr = line.replaceAll(RegExp(r'^[-→>]*\s*주소\s*[:：]?\s*'), '').trim();
        // 다음 줄이 주소 이어질 수 있음
        if (i + 1 < lines.length && !lines[i + 1].contains('설명') && !lines[i + 1].startsWith('•')) {
          addr += ' ${lines[i + 1].trim()}';
          i++; // 다음 줄 건너뜀
        }
        currentAddress = addr.replaceAll(RegExp(r'[\uFEFF﻿]'), '').trim();
        continue;
      }

      // 설명 라인 감지
      if (line.contains('설명') || currentDescLines.isNotEmpty || line.startsWith('->') || line.startsWith('→')) {
        String descPart = line.replaceAll(RegExp(r'^[-→>]*\s*설명\s*[:：]?\s*'), '').trim();
        if (descPart.isNotEmpty) {
          currentDescLines.add(descPart);
        }
      }
    }

    // 마지막 장소 저장
    if (currentName != null && currentAddress != null) {
      final desc = currentDescLines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      places.add({
        'title': currentName.replaceAll(RegExp(r'[\uFEFF﻿]'), '').trim(),
        'address': currentAddress,
        'snippet': desc.isNotEmpty ? desc : '설명 없음',
      });
    }

    if (kDebugMode) {
      print('파싱 결과: ${places.length}개 장소 발견');
    }
    if (places.isNotEmpty) {
      if (kDebugMode) {
        print('첫 번째 장소: ${places.first}');
      }
    } else {
      if (kDebugMode) {
        print('파싱 실패 - 원본 텍스트:\n$text');
      }
    }

    return places;
  }

  Future<void> savePlaceToMap(
      Map<String, dynamic> place, {
        required BuildContext context,
      }) async {
    try {
      if (context.mounted) {
        final double lat = (place['lat'] as num).toDouble();
        final double lng = (place['lng'] as num).toDouble();

        // 마커 생성 창으로 이동
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MarkerCreationScreen(
            initialTitle: place['name'] ?? place['title'] ?? '',
            initialAddress: place['address'] ?? '',
            initialLatLng: LatLng(lat, lng),
          ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${place['title']}이(가) 지도에 추가되었습니다."),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      pendingPlaces.remove(place);
      notifyListeners();

    } catch (e) {
      if(kDebugMode) print('화면 이동 중 오류 발생: $e');
    }
  }

  void startNewSession(String mode) {
    messages.clear();
    pendingPlaces.clear();
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

  Future<void> _saveRecommendation(String title, List<Map<String, dynamic>> places) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || places.isEmpty) return;

    try {
      await Supabase.instance.client.from('ai_recommendations').insert({
        'user_id': user.id,
        'title': title, // 예: userInput 또는 AI가 요약한 제목
        'recommendation_data': places, // JSON 데이터로 저장
      });
      if (kDebugMode) print('✅ 추천 내역이 DB에 저장되었습니다.');
    } catch (e) {
      if (kDebugMode) print('❌ DB 저장 실패: $e');
    }
    await loadRecentRecommendations();
  }

  Future<void> sendMessage(String userInput, {bool isNearbySearch = false}) async {
    if (userInput.trim().isEmpty) return;

    // 사용자 질문 저장 (DB 타이틀용)
    _lastUserQuery = userInput;

    // 1. 사용자 메시지 추가
    messages.add({'role': 'user', 'text': userInput});
    _trimHistory();
    isLoading = true;
    notifyListeners();

    try {
      // 2. 프롬프트 구성 (위치 정보는 근처 명소 검색일 때만 포함하도록 설정하셨던 의도 반영)
      String finalInput = userInput;
      if (isNearbySearch) {
        String location = await _getCurrentLocationContext();
        finalInput = "$location 인근의 장소를 추천해줘: $userInput";
      }

      // 3. 봇의 빈 메시지 추가
      final botMessageIndex = messages.length;
      messages.add({'role': 'bot', 'text': ''});

      // 4. 스트림 구독 및 실시간 업데이트
      String fullResponse = "";
      final stream = _geminiService.sendMessageStream(finalInput);

      await for (final chunk in stream) {
        fullResponse += chunk;
        messages[botMessageIndex]['text'] = fullResponse;
        notifyListeners();
      }

      // 5. 답변 완료 후 추천 장소 추출 및 DB 저장
      pendingPlaces.clear();
      await _handleAiResponse(fullResponse);

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
    pendingPlaces.clear();
    currentMode = '';
    notifyListeners();
  }
}