import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 푸시 설정
  bool pushNewMarker = true;
  bool pushListUpdate = true;
  bool pushFriendRequest = true;

  // 이메일 설정
  bool emailSecurity = true;
  String? get securityEmail => Supabase.instance.client.auth.currentUser?.email;
  String get securityEmailDescription {
    final email = securityEmail?.trim();
    if (email == null || email.isEmpty) {
      return '로그인 계정에 이메일이 없어 보안 알림을 받을 수 없어요.';
    }
    return '로그인·비밀번호·이메일 변경 알림\n받는 주소: $email';
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('user_notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return;

      pushNewMarker = data['push_new_marker'] ?? true;
      pushListUpdate = data['push_list_update'] ?? true;
      pushFriendRequest = data['push_friend_request'] ?? true;
      emailSecurity = data['email_security'] ?? true;
    } catch (e) {
      debugPrint('알림 설정 로드 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePushSetting(String key, bool value) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('user_notification_settings').upsert({
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
        _getColumnName(key): value,
      }, onConflict: 'user_id');

      // 로컬 상태 업데이트
      switch (key) {
        case 'new_marker':
          pushNewMarker = value;
          break;
        case 'list_update':
          pushListUpdate = value;
          break;
        case 'friend_request':
          pushFriendRequest = value;
          break;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('푸시 설정 업데이트 실패: $e');
    }
  }

  Future<void> updateEmailSetting(String key, bool value) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('user_notification_settings').upsert({
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
        _getColumnName(key): value,
      }, onConflict: 'user_id');

      if (key == 'security') emailSecurity = value;

      notifyListeners();
    } catch (e) {
      debugPrint('이메일 설정 업데이트 실패: $e');
    }
  }

  String _getColumnName(String key) {
    switch (key) {
      case 'new_marker':
        return 'push_new_marker';
      case 'list_update':
        return 'push_list_update';
      case 'friend_request':
        return 'push_friend_request';
      case 'security':
        return 'email_security';
      default:
        return key;
    }
  }
}
