import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static const _androidNotifications =
      MethodChannel('fluttertrip/notifications');
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static Future<bool>? _initializing;

  Future<bool> initializePushNotifications() {
    return _initializing ??= _initializePush().whenComplete(() {
      _initializing = null;
    });
  }

  Future<bool> _initializePush() async {
    if (_supabase.auth.currentUser == null || kIsWeb || Firebase.apps.isEmpty) {
      return false;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _androidNotifications.invokeMethod<void>('initialize');
        _foregroundSubscription ??=
            FirebaseMessaging.onMessage.listen((message) async {
          if (_supabase.auth.currentUser == null ||
              message.notification == null) {
            return;
          }
          try {
            await _androidNotifications.invokeMethod<void>('show', {
              'id': message.messageId ?? DateTime.now().toIso8601String(),
              'title': message.notification?.title,
              'body': message.notification?.body,
            });
          } catch (error) {
            debugPrint('안드로이드 알림 표시 실패: $error');
          }
        });
      }
      final settings = await messaging.requestPermission(
          alert: true, badge: true, sound: true);
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return false;
      }
      await messaging.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true);
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        (token) => unawaited(_savePushToken(token).catchError((Object error) {
          debugPrint('푸시 토큰 저장 실패: $error');
        })),
        onError: (Object error) => debugPrint('푸시 토큰 갱신 실패: $error'),
      );
      // APNs registration can finish after notification permission is granted.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        var ready = false;
        for (var attempt = 0; attempt < 10; attempt++) {
          if (await messaging.getAPNSToken() != null) {
            ready = true;
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        if (!ready) return false;
      }
      final token = await messaging.getToken();
      if (token == null) return false;
      await _savePushToken(token);
      return true;
    } catch (error) {
      debugPrint('푸시 알림 연결 실패: $error');
      return false;
    }
  }

  Future<void> _savePushToken(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    debugPrint('💾 토큰 저장 시도 - User: ${user.id}');

    try {
      // 기존 토큰 삭제 (강제 갱신)
      // Preserve tokens registered on the user’s other devices.

      // 새 토큰 저장
      await _supabase.rpc(
        'save_user_push_token',
        params: {
          'p_token': token,
          'p_platform': defaultTargetPlatform.name,
        },
      );
      debugPrint('✅ 토큰 강제 갱신 및 저장 성공!');
    } catch (e) {
      debugPrint('❌ 토큰 저장 실패: $e');
      rethrow;
    }
  }

  Future<void> refreshPushTokenOnLogin() async {
    await initializePushNotifications();
  }

  // notifyMarkerAddedToList는 그대로 유지
  Future<void> notifyMarkerAddedToList({
    required String listId,
    required String markerId,
    required String markerTitle,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      debugPrint('🔔 notifyMarkerAddedToList 호출 - Sender: ${user.id}');

      final result = await _supabase.rpc(
        'notify_list_marker_added',
        params: {
          'p_list_id': listId,
          'p_marker_id': markerId,
          'p_marker_title': markerTitle,
        },
      );

      final notificationIds = _extractNotificationIds(result);
      debugPrint('📋 생성된 notification_ids: $notificationIds');

      if (notificationIds.isEmpty) {
        debugPrint('⚠️ notification_ids가 비어있음');
        return;
      }

      debugPrint('🚀 send-push-notification 함수 호출 시작');
      await _supabase.functions.invoke(
        'send-push-notification',
        body: {'notification_ids': notificationIds},
      );
      debugPrint('✅ send-push-notification 호출 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ 마커 추가 알림 생성 실패: $e');
      debugPrint('$stackTrace');
    }
  }

  Future<void> notifyFriendRequest(String requestId) =>
      _notify('notify_friend_request', {'p_request_id': requestId});

  Future<void> notifyListUpdated(String listId, String change) =>
      _notify('notify_list_updated', {'p_list_id': listId, 'p_change': change});

  Future<void> _notify(String function, Map<String, dynamic> params) async {
    if (_supabase.auth.currentUser == null) return;
    try {
      final result = await _supabase.rpc(function, params: params);
      final ids = _extractNotificationIds(result);
      if (ids.isEmpty) return;
      await _supabase.functions
          .invoke('send-push-notification', body: {'notification_ids': ids});
    } catch (error) {
      // A notification failure must not undo the already completed user action.
      debugPrint('알림 전송 실패 ($function): $error');
    }
  }

  List<String> _extractNotificationIds(dynamic result) {
    if (result is Map && result['notification_ids'] is List) {
      return (result['notification_ids'] as List)
          .map((id) => id.toString())
          .toList();
    }
    return const [];
  }
}
