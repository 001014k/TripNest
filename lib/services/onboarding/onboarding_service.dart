import 'package:shared_preferences/shared_preferences.dart';

/// 기기에만 저장하는 버전별 환경설정이며, 계정이나 위치 정보는 저장하지 않습니다.
class OnboardingService {
  static const introKey = 'tripnest.intro.v1';
  static const sharedLinkKey = 'tripnest.guide.shared_link.v1';
  Future<bool> hasSeen(String key) async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;
  Future<void> markSeen(String key) async {
    final saved =
        await (await SharedPreferences.getInstance()).setBool(key, true);
    if (!saved) throw StateError('안내 기록을 저장하지 못했습니다.');
  }
}
