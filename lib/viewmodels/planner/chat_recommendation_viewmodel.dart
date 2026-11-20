import '../../models/planner/trip_history_controller.dart';
import 'dart:convert';
import '../../services/ai/trip_draft_store.dart';
import 'package:uuid/uuid.dart';
import '../../services/ai/trip_history_repository.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart'; // 위치 정보 사용 시 필요
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ai/gemini_service.dart';
import '../../services/places/places_service.dart';

class ChatRecommendationViewModel extends ChangeNotifier {
  final GeminiService _geminiService;
  final SupabaseClient? _client;
  final TripDraftStore _draftStore;
  SupabaseClient get _db => _client ?? Supabase.instance.client;

  late final _tripRepository = TripHistoryRepository(_db);
  TripHistoryController? _tripHistory;
  TripHistoryController get tripHistory =>
      _tripHistory ??= TripHistoryController(
        loadPage: _tripRepository.list,
        deleteRecord: (id) async {
          await _tripRepository.delete(id);
          await loadRecentRecommendations();
        },
      );
  Future<TripRecord> fetchTripRecord(Object id) => _tripRepository.detail(id);

  bool _disposed = false;
  String _usageMenu = 'freeform';
  int _requestVersion = 0;
  String _sessionId = const Uuid().v4();
  int _sessionRevision = 0;
  String? _sessionOwner;
  String? _pendingOwner;
  bool saveConflict = false;
  List<Map<String, dynamic>> _recoveredDrafts = [];
  List<Map<String, dynamic>> get recoveredDrafts => _recoveredDrafts
      .where((draft) => draft['owner'] == _db.auth.currentUser?.id)
      .toList(growable: false);
  String? recoveryError;
  String? saveError;
  final Map<String, Map<String, dynamic>> _cleanupPending = {};
  bool saving = false;
  Map<String, dynamic>? _pendingSave;
  String? _selectedCategory;
  String get _category =>
      _selectedCategory ??
      switch (_usageMenu) {
        'stay' => '스테이',
        'theme' || 'nearby' || 'companion' => '여행',
        _ => '기타',
      };
  List<Map<String, dynamic>> get usageHistory => _geminiService.usageHistory;

  void _resetAiSession() {
    _requestVersion++;
    _sessionId = const Uuid().v4();
    _pendingSave = null;
    _pendingOwner = null;
    _sessionOwner = null;
    _sessionRevision = 0;
    saveConflict = false;
    _selectedCategory = null;
    saveError = null;
    saving = false;
    isLoading = false;
    _usageMenu = 'freeform';
    _geminiService.resetChat();
  }

  @override
  void dispose() {
    _disposed = true;
    _tripHistory?.dispose();
    _resetAiSession();
    super.dispose();
  }

  // 채팅 내역 및 상태 초기화
  void resetChat() {
    _resetAiSession();
    _placesByMessage.clear();
    messages.clear(); // 대화 내역 삭제
    pendingPlaces.clear(); // 추천 대기 장소 삭제
    currentMode = ''; // 선택된 모드 초기화
    notifyListeners(); // UI 갱신 (Stage 1으로 복귀)
  }

  ChatRecommendationViewModel(
      {GeminiService? geminiService,
      SupabaseClient? client,
      TripDraftStore? draftStore})
      : _client = client,
        _draftStore = draftStore ?? TripDraftStore.shared,
        _geminiService = geminiService ?? GeminiService();

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  String currentMode = ''; // 'place', 'itinerary', ''
  List<Map<String, dynamic>> pendingPlaces = []; // 아직 저장 안 한 추천 장소들
  List<Map<String, dynamic>> recentRecommendations = [];
  String _lastUserQuery = "";
  final Map<Map<String, String>, List<Map<String, dynamic>>> _placesByMessage =
      Map.identity();

  List<Map<String, dynamic>> placesForMessage(int index) =>
      index >= 0 && index < messages.length
          ? List.unmodifiable(_placesByMessage[messages[index]] ?? [])
          : const [];

  // 히스토리 길이 제한 (최근 12턴 = 24 메시지)
  static const int _maxHistoryLength = 24;

  // 초기화 시 호출하거나 사용자가 진입할 때 호출
  Future<void> loadRecentRecommendations() async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    try {
      final response =
          await _tripRepository.list(const TripHistoryQuery(), limit: 5);

      if (_disposed) return;
      recentRecommendations = List<Map<String, dynamic>>.from(response);
      notifyListeners(); // UI에 데이터 로드 알림
    } catch (e) {
      if (kDebugMode) print('❌ 최근 추천 불러오기 실패: $e');
    }
  }

  // 특정 과거 이력을 클릭했을 때 화면에 즉시 뿌려주는 메서드
  void loadRecentRecommendation(Map<String, dynamic> record) {
    _resetAiSession();
    _usageMenu = 'history';
    _sessionId = record['id'].toString();
    _sessionOwner = _db.auth.currentUser?.id;
    _sessionRevision = (record['revision'] as num?)?.toInt() ?? 1;
    _restoredCategory = record['category']?.toString() ?? '기타';
    // 1. 화면 초기화 (Stage 1 -> Stage 2 전환 준비)
    _placesByMessage.clear();
    messages.clear();
    pendingPlaces.clear();

    // 2. 데이터 추출 (DB 컬럼명에 맞춰 가져오기)
    final String title = record['title'] ?? '과거 추천';
    final List<dynamic> savedPlaces = record['recommendation_data'] ?? [];

    final conversation = record['conversation'];
    if (conversation is List && conversation.isNotEmpty) {
      for (final entry in conversation.whereType<Map>()) {
        final message = <String, String>{
          'role': entry['role'].toString(),
          'text': entry['text'].toString()
        };
        messages.add(message);
        _placesByMessage[message] =
            List<Map<String, dynamic>>.from(entry['places'] as List? ?? []);
      }
    } else {
      messages.add({'role': 'user', 'text': title});
      messages.add({
        'role': 'bot',
        'text': savedPlaces
            .map((p) => "📍 ${p['title']}\n${p['snippet'] ?? ''}")
            .join('\n\n')
      });
      _placesByMessage[messages.last] =
          List<Map<String, dynamic>>.from(savedPlaces);
    }
    _geminiService.resetChat(
        history: messages
            .map((m) => m['role'] == 'user'
                ? Content.text(m['text']!)
                : Content.model([TextPart(m['text']!)]))
            .toList());
    pendingPlaces = List<Map<String, dynamic>>.from(savedPlaces);

    // 5. UI 갱신 (vm.messages.isEmpty가 false가 되어 채팅창 Stage로 자동 전환됨)
    notifyListeners();
  }

  Future<void> _handleAiResponse(String fullResponse) async {
    final requestVersion = _requestVersion;
    if (kDebugMode) {
      print("--- AI's Full Response ---");
      print(fullResponse);
      print("--------------------------");
    }

    // 1. AI 응답에서 장소 데이터 파싱
    final parsedPlacesData = parsePlaceDetailsFromResponse(fullResponse);
    if (parsedPlacesData.isEmpty) {
      if (kDebugMode) print('⚠️ 파싱된 장소 데이터가 없습니다.');
      await _saveRecommendation(_lastUserQuery, pendingPlaces);
      return;
    }

    // 2. Google Maps API를 통한 좌표 검증 및 데이터 생성
    final placesService = PlacesService();
    final List<Map<String, dynamic>> verifiedPlacesWithCoords = [];

    for (final parsedPlace in parsedPlacesData.take(5)) {
      final placeTitle = parsedPlace['title'] as String;
      final verified = _geminiService.verifiedPlace(
          placeTitle, parsedPlace['address'] as String? ?? '');
      final placeDetailsList = verified?['location'] != null
          ? <Map<String, dynamic>>[
              {'location': verified!['location'], 'rating': verified['rating']}
            ]
          : await placesService.searchPlacesByKeyword(
              '$placeTitle ${parsedPlace['address'] ?? ''}');
      if (requestVersion != _requestVersion) return;

      if (placeDetailsList.isNotEmpty) {
        final placeDetails = placeDetailsList.first;
        final location = placeDetails['location'];
        if (location != null) {
          verifiedPlacesWithCoords.add({
            'title': parsedPlace['title'],
            'address': parsedPlace['address'],
            'snippet': parsedPlace['snippet'],
            'rating': placeDetails['rating'],
            'lat': location['latitude'],
            'lng': location['longitude'],
            'keyword': parsedPlace['title'],
          });
        }
      }
    }

    if (requestVersion != _requestVersion) return;

    // 3. 뷰모델 상태 업데이트 (UI 표시용)
    pendingPlaces = verifiedPlacesWithCoords;
    _placesByMessage[messages.last] = List.of(pendingPlaces);
    notifyListeners();

    // 4. DB 저장 (lastUserMessage 대신 _lastUserQuery 사용)
    await _saveRecommendation(_lastUserQuery, pendingPlaces);
  }

  @visibleForTesting
  List<Map<String, dynamic>> parsePlaceDetailsFromResponse(String text) {
    final List<Map<String, dynamic>> places = [];
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? currentName;
    String? currentAddress;
    List<String> currentDescLines = [];

    // 1. 검증 모드 패턴 (이번 로그처럼 나올 때)
    final RegExp verifyModeRegex = RegExp(
      r'\[(.+?)\]\s*' // [ 장소 이름 ]
      r'주소:\s*(.+?)(?:\n|$)' // 주소: ...
      r'(?:설명:\s*(.+?))?', // 설명: ...
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
          'snippet': snippet.isNotEmpty ? snippet : '추천 장소',
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
          final desc =
              currentDescLines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
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
        String addr =
            line.replaceAll(RegExp(r'^[-→>]*\s*주소\s*[:：]?\s*'), '').trim();
        // 다음 줄이 주소 이어질 수 있음
        if (i + 1 < lines.length &&
            !lines[i + 1].contains('설명') &&
            !lines[i + 1].startsWith('•')) {
          addr += ' ${lines[i + 1].trim()}';
          i++; // 다음 줄 건너뜀
        }
        currentAddress = addr.replaceAll(RegExp(r'[\uFEFF﻿]'), '').trim();
        continue;
      }

      // 설명 라인 감지
      if (line.contains('설명') ||
          currentDescLines.isNotEmpty ||
          line.startsWith('->') ||
          line.startsWith('→')) {
        String descPart =
            line.replaceAll(RegExp(r'^[-→>]*\s*설명\s*[:：]?\s*'), '').trim();
        if (descPart.isNotEmpty) {
          currentDescLines.add(descPart);
        }
      }
    }

    // 마지막 장소 저장
    if (currentName != null && currentAddress != null) {
      final desc =
          currentDescLines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
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

  void markPlaceSaved(Map<String, dynamic> place) {
    pendingPlaces.remove(place);
    for (final places in _placesByMessage.values) {
      places.remove(place);
    }
    notifyListeners();
  }

  void startNewSession(String mode,
      {String menu = 'freeform', String? category}) {
    _resetAiSession();
    _usageMenu = menu;
    _selectedCategory = category;
    _placesByMessage.clear();
    messages.clear();
    pendingPlaces.clear();
    currentMode = mode;

    const welcomeMsg = '선택한 조건에 맞춰 여행을 추천해드릴게요. 추가로 원하는 조건은 채팅으로 알려주세요.';

    messages.add({'role': 'bot', 'text': welcomeMsg});
    notifyListeners();
  }

  Future<void> _saveRecommendation(
      String title, List<Map<String, dynamic>> places) async {
    final owner = _db.auth.currentUser?.id;
    if (owner == null || owner != _sessionOwner) return;
    _pendingOwner = owner;
    final successfulMessages =
        messages.where((message) => message['failed'] != 'true').toList();
    final savedMessages = successfulMessages
        .skip(successfulMessages.length > _maxHistoryLength
            ? successfulMessages.length - _maxHistoryLength
            : 0)
        .skipWhile((m) => m['role'] != 'user')
        .toList();
    final previousPlaces = savedMessages.reversed
        .map((m) => _placesByMessage[m] ?? <Map<String, dynamic>>[])
        .where((p) => p.isNotEmpty);
    _pendingSave = {
      'p_id': _sessionId,
      'p_expected_revision': _sessionRevision,
      'p_write_id': const Uuid().v4(),
      'p_title': title,
      'p_places': places.isNotEmpty
          ? places
          : (previousPlaces.isEmpty ? [] : previousPlaces.first),
      'p_category': _usageMenu == 'history' ? _restoredCategory : _category,
      'p_conversation': [
        for (final m in savedMessages)
          {...m, 'places': _placesByMessage[m] ?? []}
      ],
    };
    await retrySave();
  }

  String _restoredCategory = '기타';
  Future<void> loadPendingDrafts() async {
    final owner = _db.auth.currentUser?.id;
    if (owner == null) return;
    try {
      for (final entry in _cleanupPending.entries.toList()) {
        if (entry.value['owner'] != owner) continue;
        await _draftStore.markSaved(
            owner, entry.value['payload'] as Map<String, dynamic>);
        await _draftStore.removeIfSaved(
            owner, entry.value['payload'] as Map<String, dynamic>);
        _cleanupPending.remove(entry.key);
      }
      final drafts = await _draftStore.list(owner);
      if (_disposed || _db.auth.currentUser?.id != owner) return;
      _recoveredDrafts = drafts;
      recoveryError = null;
    } catch (_) {
      if (!_disposed && _db.auth.currentUser?.id == owner) {
        recoveryError = _cleanupPending.isNotEmpty
            ? '서버 저장은 완료됐어요. 기기의 임시 기록 정리를 다시 시도해주세요.'
            : '기기의 미저장 기록을 확인하지 못했어요.';
      }
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> restoreDraft(Map<String, dynamic> draft) async {
    if (saving || isLoading || draft['owner'] != _db.auth.currentUser?.id) {
      return;
    }
    final payload = Map<String, dynamic>.from(draft['payload'] as Map);
    loadRecentRecommendation({
      'id': payload['p_id'],
      'title': payload['p_title'],
      'category': payload['p_category'],
      'recommendation_data': payload['p_places'],
      'conversation': payload['p_conversation'],
      'revision': payload['p_expected_revision'],
    });
    _pendingOwner = draft['owner'] as String;
    _pendingSave = payload;
    await retrySave();
  }

  Future<void> showLatestConflict() async {
    final payload = _pendingSave;
    if (payload == null ||
        !saveConflict ||
        _pendingOwner != _db.auth.currentUser?.id) {
      return;
    }
    final version = _requestVersion;
    try {
      final latest = await _tripRepository.detail(payload['p_id']);
      if (_disposed || version != _requestVersion) return;
      loadRecentRecommendation(latest);
      await loadPendingDrafts();
    } catch (_) {
      if (!_disposed && version == _requestVersion) {
        saveError = '최신 기록을 열 수 없어요. 내 답변은 별도 기록으로 저장할 수 있어요.';
        notifyListeners();
      }
    }
  }

  Future<void> saveConflictAsCopy() async {
    final previous = _pendingSave;
    final owner = _pendingOwner;
    if (previous == null ||
        owner == null ||
        owner != _db.auth.currentUser?.id ||
        saving ||
        !saveConflict) {
      return;
    }
    _sessionId = const Uuid().v4();
    final copyId = _sessionId;
    final version = _requestVersion;
    _sessionRevision = 0;
    _pendingSave = {
      ...previous,
      'p_id': _sessionId,
      'p_expected_revision': 0,
      'p_write_id': const Uuid().v4()
    };
    saveConflict = false;
    await retrySave();
    if (!_disposed &&
        version == _requestVersion &&
        _sessionId == copyId &&
        _sessionRevision > 0 &&
        _pendingSave == null) {
      await _cleanupSavedDraft(owner, previous);
      await loadPendingDrafts();
    }
  }

  Future<void> retrySave() async {
    final original = _pendingSave;
    final owner = _pendingOwner;
    if (original == null ||
        owner == null ||
        owner != _db.auth.currentUser?.id ||
        saving) {
      return;
    }
    final payload =
        Map<String, dynamic>.from(jsonDecode(jsonEncode(original)) as Map);
    final version = _requestVersion;
    saving = true;
    saveError = null;
    saveConflict = false;
    notifyListeners();
    var localSaved = false;
    var serverSaved = false;
    try {
      await _draftStore.put(owner, payload);
      localSaved = true;
      await loadPendingDrafts();
      if (_disposed ||
          version != _requestVersion ||
          owner != _db.auth.currentUser?.id) {
        return;
      }
      final result = await _db.rpc('save_trip_session_v2', params: payload);
      final savedRevision = (result['revision'] as num).toInt();
      serverSaved = true;
      if (!_disposed &&
          version == _requestVersion &&
          owner == _db.auth.currentUser?.id) {
        _sessionRevision = savedRevision;
        _pendingSave = null;
      }
      // 다른 화면으로 이동했더라도 확인된 쓰기만 임시 저장에서 제거합니다.
      await _cleanupSavedDraft(owner, payload);
      if (!_disposed && owner == _db.auth.currentUser?.id) {
        await loadPendingDrafts();
      }
      if (_disposed ||
          version != _requestVersion ||
          owner != _db.auth.currentUser?.id) {
        return;
      }
      _sessionRevision = savedRevision;
      _pendingSave = null;
      await loadPendingDrafts();
      await loadRecentRecommendations();
      if (!_disposed && version == _requestVersion && _tripHistory != null) {
        await _tripHistory!.refresh(since: _tripHistory!.since);
      }
    } catch (error) {
      if (!_disposed &&
          version == _requestVersion &&
          owner == _db.auth.currentUser?.id) {
        if (serverSaved) {
          recoveryError = '서버 저장은 완료됐어요. 기록 목록을 다시 불러와주세요.';
          return;
        }
        saveConflict = error is PostgrestException &&
            error.message.contains('TRIP_SESSION_CONFLICT');
        saveError = saveConflict
            ? '다른 기기에서 변경되었거나 삭제된 기록이에요. 내 답변은 기기에 보관했어요.'
            : localSaved
                ? '서버에 저장하지 못했어요. 답변은 이 기기에 보관했어요.'
                : '기기에 임시 저장하지 못했어요. 화면을 닫기 전에 다시 시도해주세요.';
      }
    } finally {
      if (!_disposed && version == _requestVersion) {
        saving = false;
        notifyListeners();
      }
    }
  }

  Future<void> sendMessage(String userInput,
      {bool isNearbySearch = false}) async {
    if (userInput.trim().isEmpty || isLoading || saving) return;
    _sessionOwner ??= _db.auth.currentUser?.id;
    if (_sessionOwner != _db.auth.currentUser?.id) return;
    final requestVersion = _requestVersion;
    if (_pendingSave != null) {
      if (!await prepareNextMessage() ||
          requestVersion != _requestVersion ||
          _disposed) {
        return;
      }
    }
    if (isLoading || saving) return;

    // 사용자 질문 저장 (DB 타이틀용)
    _lastUserQuery = userInput;

    // 새 턴이 시작되면 이전 답변에 연결된 추천 카드만 즉시 숨깁니다.
    // 대화 메시지 기록은 유지하며, 새 AI 답변 완료 후 새 추천 장소로 채워집니다.
    pendingPlaces.clear();

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

      if (requestVersion != _requestVersion) return;

      // 3. 봇의 빈 메시지 추가
      final botMessageIndex = messages.length;
      messages.add({'role': 'bot', 'text': ''});
      // 첫 응답 조각을 기다리는 동안에도 준비 중 UI가 바로 표시되도록 알립니다.
      notifyListeners();

      // 4. 스트림 구독 및 실시간 업데이트
      String fullResponse = "";
      final stream =
          _geminiService.sendMessageStream(finalInput, menu: _usageMenu);

      await for (final chunk in stream) {
        if (requestVersion != _requestVersion) return;
        fullResponse += chunk;
        messages[botMessageIndex]['text'] = fullResponse;
        notifyListeners();
      }

      if (requestVersion != _requestVersion) return;

      // 5. 답변 완료 후 추천 장소 추출 및 DB 저장
      pendingPlaces.clear();
      await _handleAiResponse(fullResponse);
    } catch (e) {
      if (requestVersion != _requestVersion) return;
      final userIndex = messages.lastIndexWhere((m) => m['role'] == 'user');
      for (var i = userIndex; i >= 0 && i < messages.length; i++) {
        messages[i]['failed'] = 'true';
      }
      if (messages.isNotEmpty && messages.last['role'] == 'bot') {
        messages.last['text'] = '답변을 완료하지 못했어요. 다시 질문해주세요.';
      } else {
        messages.add({
          'role': 'bot',
          'text': '답변을 완료하지 못했어요. 다시 질문해주세요.',
          'failed': 'true'
        });
      }
    } finally {
      if (requestVersion == _requestVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // 히스토리 길이 제한
  Future<bool> prepareNextMessage() async {
    if (_disposed || isLoading || saving) return false;
    final version = _requestVersion;
    if (_pendingSave != null) {
      if (saveConflict) return false;
      await retrySave();
    }
    return !_disposed && version == _requestVersion && _pendingSave == null;
  }

  Future<void> _cleanupSavedDraft(
      String owner, Map<String, dynamic> payload) async {
    final key = '$owner:${payload['p_write_id']}';
    _cleanupPending[key] = {'owner': owner, 'payload': payload};
    try {
      await _draftStore.markSaved(owner, payload);
      await _draftStore.removeIfSaved(owner, payload);
      _cleanupPending.remove(key);
    } catch (_) {
      recoveryError = '서버 저장은 완료됐어요. 기기의 임시 기록 정리를 다시 시도해주세요.';
    }
  }

  void _trimHistory() {
    if (messages.length > _maxHistoryLength) {
      messages.removeRange(0, messages.length - _maxHistoryLength);
      _placesByMessage.removeWhere((message, _) => !messages.contains(message));
    }
  }

  Future<String?> getPlannerLocation() async {
    final location = await _getCurrentLocationContext();
    return location.startsWith('현재 위치:') ? location : null;
  }

  Future<String> _getCurrentLocationContext() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return '사용자 현재 위치 (위치 서비스 꺼짐)';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return '사용자 현재 위치 (권한 거부됨)';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return '사용자 현재 위치 (권한 영구 거부됨)';
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return "현재 위치: 위도 ${position.latitude.toStringAsFixed(6)}, 경도 ${position.longitude.toStringAsFixed(6)}";
    } catch (e) {
      if (kDebugMode) print('위치 정보 획득 실패: $e');
      return '사용자 현재 위치 (정보를 가져올 수 없음)';
    }
  }

  void reset() {
    _resetAiSession();
    _placesByMessage.clear();
    messages.clear();
    pendingPlaces.clear();
    currentMode = '';
    notifyListeners();
  }
}
