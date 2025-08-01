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

  Future<void> saveLink(String url) async {
    errorMessage = null;

    // ✅ 중복 URL 방지
    if (_lastSavedUrl == url) {
      debugPrint('중복된 링크입니다. 저장하지 않습니다.');
      return;
    }

    try {
      final alreadyExists = await _service.doesLinkExist(url);
      if (alreadyExists) {
        debugPrint('이미 저장된 링크입니다.');
        return;
      }

      final platform = detectPlatformFromUrl(url);

      await _service.saveSharedLink(url, platform);

      _lastSavedUrl = url; // ✅ 저장한 URL 기록
      await loadSharedLinks(); // 저장 후 최신 목록 다시 불러오기
    } catch (e) {
      errorMessage = '링크 저장 실패: $e';
    }

    notifyListeners();
  }

  Future<void> loadSharedLinks() async {
    errorMessage = null;
    try {
      sharedLinks = await _service.loadSharedLinks();
    } catch (e) {
      errorMessage = '공유 링크 불러오기 실패: $e';
      sharedLinks = [];
    }
    notifyListeners();
  }

  Future<void> deleteLink(String id) async {
    errorMessage = null;
    try {
      await _service.deleteSharedLink(id);
      await loadSharedLinks(); // 삭제 후 목록 갱신
    } catch (e) {
      errorMessage = '링크 삭제 실패: $e';
    }
    notifyListeners();
  }
}
