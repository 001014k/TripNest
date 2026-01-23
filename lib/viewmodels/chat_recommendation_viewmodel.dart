import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // 위치 정보 사용 시 필요
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/gemini_service.dart';
import '../services/places_service.dart';
import '../services/user_service.dart';
import '../views/mapsample_view.dart';
import '../viewmodels/mapsample_viewmodel.dart';

class ChatRecommendationViewModel extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final MapSampleViewModel? mapSampleViewModel;

  ChatRecommendationViewModel({this.mapSampleViewModel});

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  String currentMode = ''; // 'place', 'itinerary', ''
  List<Map<String, dynamic>> pendingPlaces = []; // 아직 저장 안 한 추천 장소들

  // 히스토리 길이 제한 (최근 12턴 = 24 메시지)
  static const int _maxHistoryLength = 24;

  Future<void> _handleAiResponse(String fullResponse) async {
    print("--- AI's Full Response ---");
    print(fullResponse);
    print("--------------------------");
    
    final parsedPlacesData = _parsePlaceDetailsFromResponse(fullResponse);
    if (parsedPlacesData.isEmpty) {
      if (kDebugMode) print('⚠️ No place details parsed from AI response.');
      return;
    }

    final placesService = PlacesService();
    final List<Map<String, dynamic>> verifiedPlacesWithCoords = [];

    for (final parsedPlace in parsedPlacesData) {
      // Use the name/title from the parsed AI response to search for coordinates
      final placeTitle = parsedPlace['title'] as String;
      final placeDetailsList = await placesService.searchPlacesByKeyword(placeTitle);

      if (placeDetailsList.isNotEmpty) {
        final placeDetails = placeDetailsList.first;
        final location = placeDetails['location']; // This contains lat/lng
        if (location != null) {
          verifiedPlacesWithCoords.add({
            'title': parsedPlace['title'],
            'address': parsedPlace['address'],
            'snippet': parsedPlace['snippet'],
            'lat': location['latitude'],
            'lng': location['longitude'],
            'keyword': parsedPlace['title'], // Use title as keyword
          });
        } else {
          if (kDebugMode) print('⚠️ Location not found for place: $placeTitle');
        }
      } else {
        if (kDebugMode) print('⚠️ Could not find place details for coordinates for: $placeTitle');
      }
    }

    pendingPlaces = verifiedPlacesWithCoords;
    notifyListeners();
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
      r'(?:소개:\s*(.+?))?'                       // 소개: ...
      r'(?:특징:\s*(.+?))?',                      // 특징: ...
      multiLine: true,
      dotAll: true,
    );

    final verifyMatches = verifyModeRegex.allMatches(text);

    for (final match in verifyMatches) {
      final name = match.group(1)?.trim();
      final address = match.group(2)?.trim();
      final intro = match.group(3)?.trim() ?? '';
      final feature = match.group(4)?.trim() ?? '';

      if (name != null && address != null) {
        final snippet = [intro, feature]
            .where((s) => s.isNotEmpty)
            .join(' / ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        places.add({
          'title': name,
          'address': address,
          'snippet': snippet.isNotEmpty ? snippet : '인스타 감성 장소',
        });
        print('검증 모드 파싱 성공: $name → $address');
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
          addr += ' ' + lines[i + 1].trim();
          i++; // 다음 줄 건너뜀
        }
        currentAddress = addr.replaceAll(RegExp(r'[\uFEFF﻿]'), '').trim();
        continue;
      }

      // 설명 라인 감지
      if (line.contains('설명') || currentDescLines.isNotEmpty || line.startsWith('->')) {
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

    print('파싱 결과: ${places.length}개 장소 발견');
    if (places.isNotEmpty) {
      print('첫 번째 장소: ${places.first}');
    } else {
      print('파싱 실패 - 원본 텍스트:\n$text');
    }

    return places;
  }

  Future<void> savePlaceToMap(
      Map<String, dynamic> place, {
        required BuildContext context,
      }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("로그인이 필요합니다");
      }

      final response = await supabase.from('user_markers').insert({
        'user_id': userId,
        'title': place['title'],
        'address': place['address'] ?? '',
        'lat': place['lat'],
        'lng': place['lng'],
        'snippet': place['snippet'] ?? '',
        'keyword': place['keyword'] ?? place['title'],
      }).select('id').single();

      final newMarkerId = (response as Map<String, dynamic>)['id'];

      if (mapSampleViewModel != null) {
        await mapSampleViewModel!.loadMarkers();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${place['title']}이(가) 지도에 추가되었습니다."),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapSampleView(initialMarkerId: MarkerId(newMarkerId.toString())),
          ),
        );
      }

      pendingPlaces.remove(place);
      notifyListeners();

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("저장 실패: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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

      // ★★★★ 여기! 답변 완료 후 추천 장소 추출 & 표시
      pendingPlaces.clear(); // Clear previous places
      await _handleAiResponse(fullResponse);
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
    pendingPlaces.clear();
    currentMode = '';
    notifyListeners();
  }
}