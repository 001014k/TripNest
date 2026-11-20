import 'package:flutter/material.dart';
import '../../services/notifications/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsViewModel extends ChangeNotifier {
  NotificationSettingsViewModel(
      {SupabaseClient? client, Future<bool> Function()? connectPush})
      : _client = client ?? Supabase.instance.client,
        _connectPush = connectPush ??
            (() => NotificationService().initializePushNotifications());
  final SupabaseClient _client;
  final Future<bool> Function() _connectPush;
  bool _disposed = false;
  int _revision = 0;
  final Set<String> pending = {};
  String? errorMessage;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? pushConnectionMessage;

  // 푸시 설정
  bool pushNewMarker = true;
  bool pushListUpdate = true;
  bool pushFriendRequest = true;

  // 이메일 설정
  bool emailSecurity = true;
  String? get securityEmail => _client.auth.currentUser?.email;
  String get securityEmailDescription {
    final email = securityEmail?.trim();
    if (email == null || email.isEmpty) {
      return '로그인 계정에 이메일이 없어 보안 알림을 받을 수 없어요.';
    }
    return '로그인·비밀번호·이메일 변경 알림\n받는 주소: $email';
  }

  Future<void> loadSettings() async {
    if (_disposed || _isLoading || pending.isNotEmpty) return;
    final revision = ++_revision;
    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _client
          .from('user_notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (_disposed ||
          revision != _revision ||
          _client.auth.currentUser?.id != userId ||
          data == null) {
        return;
      }

      pushNewMarker = data['push_new_marker'] ?? true;
      pushListUpdate = data['push_list_update'] ?? true;
      pushFriendRequest = data['push_friend_request'] ?? true;
      emailSecurity = data['email_security'] ?? true;
    } catch (e) {
      if (!_disposed && revision == _revision) {
        errorMessage = '알림 설정을 불러오지 못했어요. 다시 시도해주세요.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePushSetting(String key, bool value) =>
      _update(key, value, push: true);
  Future<void> updateEmailSetting(String key, bool value) =>
      _update(key, value, push: false);

  Future<void> _update(String key, bool value, {required bool push}) async {
    final owner = _client.auth.currentUser?.id;
    if (_disposed || _isLoading || owner == null || !pending.add(key)) return;
    errorMessage = null;
    notifyListeners();
    try {
      await _client.from('user_notification_settings').upsert({
        'user_id': owner,
        'updated_at': DateTime.now().toIso8601String(),
        _getColumnName(key): value,
      }, onConflict: 'user_id');
      if (_disposed || _client.auth.currentUser?.id != owner) return;
      switch (key) {
        case 'new_marker':
          pushNewMarker = value;
        case 'list_update':
          pushListUpdate = value;
        case 'friend_request':
          pushFriendRequest = value;
        case 'security':
          emailSecurity = value;
      }
      if (push && value) {
        bool connected;
        try {
          connected = await _connectPush();
        } catch (_) {
          connected = false;
        }
        if (_disposed || _client.auth.currentUser?.id != owner) return;
        pushConnectionMessage = connected
            ? '이 기기에서 푸시 알림을 받을 수 있어요.'
            : '설정은 저장했지만 기기 알림 연결을 확인하지 못했어요. 알림 권한을 확인해주세요.';
      }
    } catch (_) {
      if (!_disposed && _client.auth.currentUser?.id == owner) {
        errorMessage = '설정을 저장하지 못했어요. 다시 변경해주세요.';
      }
    } finally {
      pending.remove(key);
      notifyListeners();
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
