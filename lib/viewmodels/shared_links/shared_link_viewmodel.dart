import 'dart:async';
import '../../services/shared_links/threads_place_extractor_service.dart';
import '../../services/shared_links/shared_link_platform.dart';
import '../../services/shared_links/portal_place_extractor_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/shared_links/link_place_preview_model.dart';
import '../../models/shared_links/link_preview_data.dart';
import '../../models/shared_links/shared_link_model.dart';
import '../../services/shared_links/link_place_extractor_service.dart';
import '../../services/shared_links/link_preview_service.dart';
import '../../services/shared_links/shared_link_service.dart';
import '../../services/shared_links/apify_service.dart';
import '../../services/ai/gemini_service.dart';

class PendingSharedLink {
  final String url;
  final String? sharedText;

  const PendingSharedLink({
    required this.url,
    this.sharedText,
  });
}

class SharedLinkViewModel extends ChangeNotifier {
  List<String> extractUrls(String text) => RegExp(r'https?://[^\s]+')
      .allMatches(text)
      .map((match) => match.group(0)!)
      .toList();

  Future<LinkPreviewData> loadPreview(String url) =>
      const LinkPreviewService().load(url);
  SharedLinkViewModel({SharedLinkService? service})
      : _service = service ?? SharedLinkService();

  final SharedLinkService _service;
  int _loadRevision = 0;
  bool _disposed = false;
  bool _mutating = false;
  Future<void> _mutationTail = Future<void>.value();
  final Map<String, Future<void>> _pendingMutations = {};

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> _mutate(String key, Future<void> Function() action) {
    if (_disposed) return Future<void>.value();
    final pending = _pendingMutations[key];
    if (pending != null) return pending;
    final result = _mutationTail.then((_) async {
      if (_disposed) return;
      _mutating = true;
      _loadRevision++;
      isLoadingLinks = false;
      try {
        await action();
      } finally {
        _mutating = false;
        if (!_disposed) notifyListeners();
      }
    });
    _pendingMutations[key] = result;
    _mutationTail =
        result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    unawaited(_mutationTail.then((_) => _pendingMutations.remove(key)));
    return result;
  }

  Future<void> saveLink(String url, {LinkPlacePreview? placePreview}) =>
      _mutate('save:$url', () => _saveLink(url, placePreview: placePreview));
  Future<void> saveMultiplePlaces(
          String url, List<LinkPlacePreview> previews) =>
      _mutate('places:$url', () => _saveMultiplePlaces(url, previews));
  Future<void> deleteLink(String id) =>
      _mutate('delete:$id', () => _deleteLink(id));
  Future<void> deleteLinkGroup(String url) =>
      _mutate('group:$url', () => _deleteLinkGroup(url));

  final LinkPlaceExtractorService _placeExtractor =
      const LinkPlaceExtractorService();
  final ApifyService _apifyService = ApifyService();
  List<SharedLinkModel> sharedLinks = [];
  String? errorMessage;
  bool isLoadingLinks = false;
  bool hasMoreLinks = true;
  bool loadingMoreLinks = false;
  SharedLinkModel? _linkCursor;
  String search = '';
  String? platform;
  Future<void> filterLinks(String value, String? source) {
    search = value.trim();
    platform = source;
    return loadSharedLinks();
  }

  Future<void> loadMoreLinks() async {
    if (_disposed ||
        _mutating ||
        isLoadingLinks ||
        loadingMoreLinks ||
        !hasMoreLinks) {
      return;
    }
    final revision = _loadRevision;
    loadingMoreLinks = true;
    notifyListeners();
    try {
      final page = await _service.loadSharedLinksPage(
          before: _linkCursor, search: search, platform: platform);
      if (_disposed || revision != _loadRevision) return;
      if (page.isNotEmpty) _linkCursor = page.last;
      hasMoreLinks = page.length == 40;
      final ids = sharedLinks.map((link) => link.id).toSet();
      sharedLinks.addAll(page.where((link) => ids.add(link.id)));
      errorMessage = null;
    } catch (_) {
      if (!_disposed && revision == _loadRevision) {
        errorMessage = '이전 링크를 불러오지 못했어요. 다시 시도해주세요.';
      }
    } finally {
      if (!_disposed && revision == _loadRevision) {
        loadingMoreLinks = false;
        notifyListeners();
      }
    }
  }

  String? _lastSavedUrl;
  RealtimeChannel? _realtimeChannel;
  String? _realtimeUserId;
  PendingSharedLink? _pendingSharedLink;
  bool get hasPendingSharedUrl => _pendingSharedLink != null;

  void queueIncomingLink(
    String url, {
    String? sharedText,
  }) {
    debugPrint('📥 [queueIncomingLink] URL 수신: $url');
    debugPrint('📄 [queueIncomingLink] 공유 원문: $sharedText');

    _pendingSharedLink = PendingSharedLink(
      url: url,
      sharedText: sharedText,
    );

    debugPrint(
      '📌 [queueIncomingLink] pending 상태: ' '${_pendingSharedLink != null}',
    );
    notifyListeners();
  }

  PendingSharedLink? consumePendingSharedLink() {
    final pending = _pendingSharedLink;
    debugPrint(
      '📤 [consumePendingSharedLink] URL 소비: ${pending?.url}',
    );
    debugPrint(
      '📄 [consumePendingSharedLink] 원문 소비: ${pending?.sharedText}',
    );
    _pendingSharedLink = null;
    notifyListeners();
    return pending;
  }

  Future<LinkPlacePreview> extractPlacePreview(
    String url, {
    String? sharedText,
  }) async {
    final preview = await _placeExtractor.extract(url, sharedText: sharedText);
    return LinkPlacePreview(
      url: url,
      title: preview.title,
      address: preview.address,
      latitude: preview.latitude,
      longitude: preview.longitude,
    );
  }

  Future<List<LinkPlacePreview>> findPlacePreviews(String query) {
    return _placeExtractor.search(query);
  }

  void subscribeToChanges() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _realtimeUserId == user.id) return;

    _realtimeChannel?.unsubscribe();
    _realtimeUserId = user.id;
    _realtimeChannel = Supabase.instance.client
        .channel('shared-links-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shared_links',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => loadSharedLinks(),
        )
        .subscribe();
  }

  String detectPlatformFromUrl(String url) => SharedLinkPlatform.detect(url);

  Future<List<LinkPlacePreview>> extractThreadsPlaces(String url) async {
    errorMessage = null;
    try {
      return await ThreadsPlaceExtractorService().extract(url);
    } catch (e) {
      errorMessage = e is FormatException
          ? e.message
          : 'Threads 분석에 실패했습니다. 잠시 후 다시 시도해주세요.';
      notifyListeners();
      return [];
    }
  }

  Future<List<LinkPlacePreview>> extractPortalPlaces(String url,
          {String? sharedText}) =>
      PortalPlaceExtractorService().extract(url, sharedText: sharedText);

  // ✅ 공유 링크 저장
  Future<void> _saveLink(String url, {LinkPlacePreview? placePreview}) async {
    debugPrint('🔹 [saveLink] 호출됨: $url');
    errorMessage = null;

    if (_lastSavedUrl == url) {
      debugPrint('⚠️ [saveLink] 동일한 URL이 이미 방금 저장됨 → 저장 스킵');
      return;
    }

    try {
      debugPrint('🔍 [saveLink] 중복 여부 확인 중...');
      final alreadyExists = await _service.doesLinkExist(url);
      if (alreadyExists) {
        debugPrint('⚠️ [saveLink] 이미 Supabase에 존재하는 URL입니다.');
        return;
      }

      if (_disposed) return;
      final platform = detectPlatformFromUrl(url);
      debugPrint('🧭 [saveLink] 플랫폼 감지됨: $platform');

      await _service.saveSharedLink(
        url,
        platform,
        placePreview: placePreview,
      );
      debugPrint('✅ [saveLink] 링크 저장 성공');

      if (_disposed) return;
      _lastSavedUrl = url;
      await _loadSharedLinks(afterMutation: true);
    } catch (e) {
      if (_disposed) return;
      errorMessage = '링크 저장 실패: $e';
      debugPrint('❌ [saveLink] 오류 발생: $e');
    }

    notifyListeners();
  }

  Future<void> _saveMultiplePlaces(
    String url,
    List<LinkPlacePreview> previews,
  ) async {
    debugPrint(
      '🔹 [saveMultiplePlaces] 호출됨: '
      'url=$url, places=${previews.length}',
    );

    errorMessage = null;

    if (previews.isEmpty) {
      errorMessage = '저장할 장소가 없습니다.';
      notifyListeners();
      return;
    }

    try {
      if (_disposed) return;
      final platform = detectPlatformFromUrl(url);

      await _service.saveSharedLinkPlaces(url, platform, previews);

      debugPrint(
        '✅ [saveMultiplePlaces] '
        '${previews.length}개 장소 처리 완료',
      );

      if (_disposed) return;
      await _loadSharedLinks(afterMutation: true);
    } catch (e) {
      if (_disposed) return;
      errorMessage = '장소 저장 실패: $e';

      debugPrint(
        '❌ [saveMultiplePlaces] 오류: $e',
      );
    }

    notifyListeners();
  }

  Future<List<LinkPlacePreview>> extractInstagramPlaces(
    String url, {
    String? sharedText,
  }) async {
    errorMessage = null;
    try {
      debugPrint('📸 [Instagram] Apify 분석 시작');
      debugPrint('🔗 URL: $url');
      debugPrint('📄 공유 텍스트: $sharedText');

      // 1. Apify Actor 실행
      final result = await _apifyService.fetchInstagramData(
        instagramUrl: url,
      );

      debugPrint('✅ [Instagram] Apify 분석 완료');
      debugPrint('📦 결과 개수: ${result.length}');

      for (final item in result) {
        debugPrint('📦 Apify 결과: $item');
      }

      if (result.isEmpty) {
        debugPrint('⚠️ [Instagram] Apify 결과가 없습니다.');
        return const [];
      }

      // 2. caption이 존재하는 결과 찾기
      Map<String, dynamic>? instagramResult;

      for (final item in result) {
        if (item is Map) {
          final caption = item['caption']?.toString().trim();

          if (caption != null && caption.isNotEmpty) {
            instagramResult = Map<String, dynamic>.from(item);
            break;
          }
        }
      }

      if (instagramResult == null) {
        debugPrint('⚠️ [Instagram] caption을 찾지 못했습니다.');
        return const [];
      }

      final caption = instagramResult['caption']?.toString().trim() ?? '';

      debugPrint('📝 [Instagram] caption 확보');
      debugPrint('📝 [Instagram] caption 길이: ${caption.length}');

      // 3. Gemini로 장소 추출
      debugPrint('🤖 [Instagram] Gemini 장소 분석 시작');

      final sources = await GeminiService().extractInstagramPlaces(caption);

      debugPrint(
        '🤖 [Instagram] Gemini 장소 분석 완료: '
        '${sources.length}개',
      );

      if (sources.isEmpty) {
        debugPrint('⚠️ [Instagram] Gemini가 장소를 찾지 못했습니다.');
        return const [];
      }

      // 4. Gemini가 추출한 장소를 Google Places에서 검색
      final previews = <LinkPlacePreview>[];

      for (final source in sources) {
        debugPrint(
          '🔎 [Instagram] Google Places 검색: '
          '${source.name}'
          '${source.address != null ? ' | ${source.address}' : ''}',
        );

        final query =
            source.address != null && source.address!.trim().isNotEmpty
                ? '${source.name} ${source.address}'
                : source.name;

        try {
          final places = await _placeExtractor.search(query);

          if (places.isEmpty) {
            debugPrint(
              '⚠️ [Instagram] Google Places 검색 결과 없음: '
              '${source.name}',
            );
            continue;
          }

          // 가장 첫 번째 검색 결과 사용
          final best = places.first;

          previews.add(
            LinkPlacePreview(
              url: url,
              title: source.name,
              address: best.address,
              latitude: best.latitude,
              longitude: best.longitude,
            ),
          );

          debugPrint(
            '✅ [Instagram] 장소 매칭 성공: '
            '${source.name} → ${best.address}',
          );
        } catch (e) {
          debugPrint(
            '⚠️ [Instagram] 장소 검색 실패: '
            '${source.name} → $e',
          );
        }
      }

      debugPrint(
        '🎯 [Instagram] 최종 장소 미리보기: '
        '${previews.length}개',
      );

      return previews;
    } catch (e) {
      debugPrint('❌ [Instagram] 분석 실패: $e');

      errorMessage =
          e is InstagramAccessException ? e.message : 'Instagram 분석 실패: $e';
      notifyListeners();

      return const [];
    }
  }

  // ✅ 공유 링크 불러오기
  Future<void> loadSharedLinks() => _loadSharedLinks();

  Future<void> _loadSharedLinks({bool afterMutation = false}) async {
    if (_disposed || (_mutating && !afterMutation)) return;
    final revision = ++_loadRevision;
    loadingMoreLinks = false;
    debugPrint('🔹 [loadSharedLinks] 호출됨');
    errorMessage = null;
    isLoadingLinks = true;
    notifyListeners();

    try {
      final loaded = search.isEmpty && platform == null
          ? await _service.loadSharedLinks()
          : await _service.loadSharedLinksPage(
              search: search, platform: platform);
      if (_disposed || revision != _loadRevision) return;
      sharedLinks = loaded;
      _linkCursor = loaded.isEmpty ? null : loaded.last;
      hasMoreLinks = loaded.length == 40;
      debugPrint('✅ [loadSharedLinks] 불러온 링크 개수: ${sharedLinks.length}');
      for (final link in sharedLinks) {
        debugPrint('   ↳ ${link.platform} | ${link.url}');
      }
    } catch (e) {
      if (_disposed || revision != _loadRevision) return;
      errorMessage = '공유 링크 불러오기 실패: $e';
      debugPrint('❌ [loadSharedLinks] 오류 발생: $e');
    }

    isLoadingLinks = false;
    notifyListeners();
  }

  // ✅ 공유 링크 삭제
  Future<void> _deleteLink(String id) async {
    debugPrint('🔹 [deleteLink] 호출됨: id=$id');
    errorMessage = null;
    final previousLinks = List<SharedLinkModel>.of(sharedLinks);
    SharedLinkModel? deletedLink;
    for (final link in sharedLinks) {
      if (link.id == id) {
        deletedLink = link;
        break;
      }
    }
    sharedLinks.removeWhere((link) => link.id == id);
    notifyListeners();

    try {
      await _service.deleteSharedLink(id);
      if (_disposed) return;
      if (_lastSavedUrl == deletedLink?.url) _lastSavedUrl = null;
      debugPrint('✅ [deleteLink] 링크 삭제 성공');
      if (_disposed) return;
      await _loadSharedLinks(afterMutation: true);
    } catch (e) {
      if (_disposed) return;
      sharedLinks = previousLinks;
      errorMessage = '링크 삭제 실패: $e';
      debugPrint('❌ [deleteLink] 오류 발생: $e');
    }

    notifyListeners();
  }

  /// 원본 링크와 해당 링크에서 추출된 모든 장소를 함께 삭제합니다.
  Future<void> _deleteLinkGroup(String url) async {
    errorMessage = null;
    final previousLinks = List<SharedLinkModel>.of(sharedLinks);
    sharedLinks.removeWhere((link) => link.url == url);
    notifyListeners();

    try {
      await _service.deleteSharedLinkGroup(url);
      if (_disposed) return;
      if (_lastSavedUrl == url) _lastSavedUrl = null;
      if (_disposed) return;
      await _loadSharedLinks(afterMutation: true);
    } catch (e) {
      if (_disposed) return;
      sharedLinks = previousLinks;
      errorMessage = '링크 삭제 실패: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadRevision++;
    _pendingMutations.clear();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
