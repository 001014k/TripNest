import 'package:flutter/material.dart';
import '../models/shared_link_model.dart';
import '../services/shared_link_service.dart';

class SharedLinkViewModel extends ChangeNotifier {
  final SharedLinkService _service = SharedLinkService();
  List<SharedLinkModel> sharedLinks = [];
  String? errorMessage;
  String? _lastSavedUrl;

  String detectPlatformFromUrl(String url) {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    if (host.contains('instagram.com')) return 'Instagram';
    if (host.contains('youtube.com') || host.contains('youtu.be')) return 'YouTube';
    if (host.contains('naver.com')) return 'Naver';
    if (host.contains('tiktok.com')) return 'TikTok';
    if (host.contains('facebook.com')) return 'Facebook';
    if (host.contains('twitter.com') || host.contains('x.com')) return 'Twitter';
    if (host.contains('daum.net')) return 'Daum';
    if (host.contains('kakao.com')) return 'Kakao';
    if (host.contains('google.com/maps')) return 'Google Maps';
    return '기타';
  }

  // ✅ 공유 링크 저장
  Future<void> saveLink(String url) async {
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

      await _service.saveSharedLink(url, platform);
      debugPrint('✅ [saveLink] 링크 저장 성공');

      _lastSavedUrl = url;
      await loadSharedLinks();
    } catch (e) {
      errorMessage = '링크 저장 실패: $e';
      debugPrint('❌ [saveLink] 오류 발생: $e');
    }

    notifyListeners();
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

    try {
      await _service.deleteSharedLink(id);
      debugPrint('✅ [deleteLink] 링크 삭제 성공');
      await loadSharedLinks();
    } catch (e) {
      errorMessage = '링크 삭제 실패: $e';
      debugPrint('❌ [deleteLink] 오류 발생: $e');
    }

    notifyListeners();
  }
}
