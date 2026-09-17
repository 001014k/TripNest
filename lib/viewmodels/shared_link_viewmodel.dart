import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/link_place_preview_model.dart';
import '../models/shared_link_model.dart';
import '../services/link_place_extractor_service.dart';
import '../services/shared_link_service.dart';
import '../services/apify_service.dart';
import '../services/gemini_service.dart';

class PendingSharedLink {
  final String url;
  final String? sharedText;

  const PendingSharedLink({
    required this.url,
    this.sharedText,
  });
}

class SharedLinkViewModel extends ChangeNotifier {
  final SharedLinkService _service = SharedLinkService();
  final LinkPlaceExtractorService _placeExtractor =
      const LinkPlaceExtractorService();
  final ApifyService _apifyService = ApifyService();
  List<SharedLinkModel> sharedLinks = [];
  String? errorMessage;
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

  String detectPlatformFromUrl(String url) {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    if (host.contains('instagram.com')) {
      return 'Instagram';
    }
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return 'YouTube';
    }
    if (host.contains('naver.com')) {
      return 'Naver';
    }
    if (host.contains('tiktok.com')) {
      return 'TikTok';
    }
    if (host.contains('facebook.com')) {
      return 'Facebook';
    }
    if (host.contains('twitter.com') || host.contains('x.com')) {
      return 'Twitter';
    }
    if (host.contains('daum.net')) {
      return 'Daum';
    }
    if (host.contains('kakao.com')) {
      return 'Kakao';
    }
    if (host.contains('google.com') && uri.path.startsWith('/maps')) {
      return 'Google Maps';
    }
    return '기타';
  }

  // ✅ 공유 링크 저장
  Future<void> saveLink(String url, {LinkPlacePreview? placePreview}) async {
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

      final platform = detectPlatformFromUrl(url);
      debugPrint('🧭 [saveLink] 플랫폼 감지됨: $platform');

      await _service.saveSharedLink(
        url,
        platform,
        placePreview: placePreview,
      );
      debugPrint('✅ [saveLink] 링크 저장 성공');

      _lastSavedUrl = url;
      await loadSharedLinks();
    } catch (e) {
      errorMessage = '링크 저장 실패: $e';
      debugPrint('❌ [saveLink] 오류 발생: $e');
    }

    notifyListeners();
  }

  Future<void> saveMultiplePlaces(
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
      final platform = detectPlatformFromUrl(url);

      for (final preview in previews) {
        await _service.saveSharedLinkPlace(
          url,
          platform,
          preview,
        );
      }

      debugPrint(
        '✅ [saveMultiplePlaces] '
        '${previews.length}개 장소 처리 완료',
      );

      await loadSharedLinks();
    } catch (e) {
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

      errorMessage = 'Instagram 분석 실패: $e';
      notifyListeners();

      return const [];
    }
  }

  // ✅ 공유 링크 불러오기
  Future<void> loadSharedLinks() async {
    debugPrint('🔹 [loadSharedLinks] 호출됨');
    errorMessage = null;

    try {
      sharedLinks = await _service.loadSharedLinks();
      debugPrint('✅ [loadSharedLinks] 불러온 링크 개수: ${sharedLinks.length}');
      for (final link in sharedLinks) {
        debugPrint('   ↳ ${link.platform} | ${link.url}');
      }
    } catch (e) {
      errorMessage = '공유 링크 불러오기 실패: $e';
      sharedLinks = [];
      debugPrint('❌ [loadSharedLinks] 오류 발생: $e');
    }

    notifyListeners();
  }

  // ✅ 공유 링크 삭제
  Future<void> deleteLink(String id) async {
    debugPrint('🔹 [deleteLink] 호출됨: id=$id');
    errorMessage = null;
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
      debugPrint('✅ [deleteLink] 링크 삭제 성공');
      await loadSharedLinks();
    } catch (e) {
      if (deletedLink != null) sharedLinks.add(deletedLink);
      errorMessage = '링크 삭제 실패: $e';
      debugPrint('❌ [deleteLink] 오류 발생: $e');
    }

    notifyListeners();
  }

  /// Deletes the source link and all places extracted from it together.
  Future<void> deleteLinkGroup(String url) async {
    errorMessage = null;
    final deletedLinks = sharedLinks.where((link) => link.url == url).toList();
    sharedLinks.removeWhere((link) => link.url == url);
    notifyListeners();

    try {
      await _service.deleteSharedLinkGroup(url);
      await loadSharedLinks();
    } catch (e) {
      sharedLinks.addAll(deletedLinks);
      errorMessage = '링크 삭제 실패: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
