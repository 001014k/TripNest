import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initializePushNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null || kIsWeb) {
      debugPrint('❌ 사용자 없거나 Web 환경');
      return;
    }

    try {
      debugPrint('🔥 FCM 초기화 시작 - User ID: ${user.id}');

      if (Firebase.apps.isEmpty) {
        debugPrint('❌ Firebase App이 초기화되지 않음');
        return;
      }

      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('📱 푸시 권한 상태: ${settings.authorizationStatus}');

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      debugPrint('📌 getToken() 결과: ${token != null ? token.substring(0, 20) + "..." : "null"}');

      if (token != null) {
        await _savePushToken(token);
      }

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
            (newToken) {
          debugPrint('🔄 Token Refresh 발생!');
          unawaited(_savePushToken(newToken));
        },
      );

      debugPrint('✅ FCM 초기화 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ 푸시 알림 초기화 실패: $e');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _savePushToken(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    debugPrint('💾 토큰 저장 시도 - User: ${user.id}');

    try {
      // 기존 토큰 삭제 (강제 갱신)
      await _supabase
          .from('user_push_tokens')
          .delete()
          .eq('user_id', user.id);

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
    }
  }

  // NotificationService 클래스에 추가
  Future<void> refreshPushTokenOnLogin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    debugPrint('🔄 로그인 시 FCM 토큰 리프레쉬 시작');

    try {
      final messaging = FirebaseMessaging.instance;

      // 기존 토큰 삭제 (서버에서)
      await _supabase
          .from('user_push_tokens')
          .delete()
          .eq('user_id', user.id);

      // 새 토큰 발급
      final token = await messaging.getToken();
      if (token != null) {
        await _savePushToken(token);
        debugPrint('✅ 로그인 시 토큰 리프레쉬 완료');
      }
    } catch (e) {
      debugPrint('❌ 로그인 시 토큰 리프레쉬 실패: $e');
    }
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

  List<String> _extractNotificationIds(dynamic result) {
    if (result is Map && result['notification_ids'] is List) {
      return (result['notification_ids'] as List)
          .map((id) => id.toString())
          .toList();
    }
    return const [];
  }
}