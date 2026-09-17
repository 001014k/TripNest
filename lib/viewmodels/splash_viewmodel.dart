import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:fluttertrip/viewmodels/list_viewmodel.dart';
import 'package:fluttertrip/viewmodels/profile_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../main.dart';
import '../services/app_group_handler_service.dart';
import 'mapsample_viewmodel.dart';
import 'package:provider/provider.dart';

class SplashViewModel extends ChangeNotifier {
  bool _isLoading = true;
  String? _nextRoute;
  Object? _arguments;

  bool get isLoading => _isLoading;
  String? get nextRoute => _nextRoute;
  Object? get arguments => _arguments;

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<Uri>? _deepLinkSub;
  bool _alreadyNavigated = false;

  Future<void> startSplash() async {
    if (_alreadyNavigated) return;

    _isLoading = true;
    _nextRoute = null;
    _arguments = null;
    notifyListeners();

    // 1. 최소 Splash 표시 시간
    await Future.delayed(const Duration(seconds: 3));

    final context = navigatorKey.currentContext;

    // 2. 현재 로그인 상태를 가장 먼저 확인
    final session = Supabase.instance.client.auth.currentSession;

    debugPrint('🔐 [Splash] currentSession: ${session != null}');

    // ============================================================
    // 로그인하지 않은 경우
    // ============================================================
    if (session == null) {
      debugPrint('🚪 [Splash] 로그인되지 않음 → /login_option');

      _nextRoute = '/login_option';
      _isLoading = false;

      notifyListeners();

      _subscribeAuthState();

      return;
    }

    // ============================================================
    // 로그인된 경우
    // ============================================================

    final userId = session.user.id;

    debugPrint('✅ [Splash] 로그인 상태');
    debugPrint('👤 [Splash] userId: $userId');

    try {
      // 3. 닉네임 확인
      final response = await Supabase.instance.client
          .from('profiles')
          .select('nickname')
          .eq('id', userId)
          .maybeSingle();

      final nickname = response?['nickname'] as String?;

      debugPrint('👤 [Splash] nickname: $nickname');

      // ------------------------------------------------------------
      // 닉네임이 없는 경우
      // ------------------------------------------------------------
      if (nickname == null || nickname.isEmpty) {
        debugPrint('📝 [Splash] 닉네임 없음 → /nickname_setup');

        _nextRoute = '/nickname_setup';
        _arguments = userId;

        _isLoading = false;

        notifyListeners();

        return;
      }

      // ------------------------------------------------------------
      // 로그인 + 닉네임 존재
      // ------------------------------------------------------------

      debugPrint('🏠 [Splash] 정상 사용자 → 앱 초기화 시작');

      if (context != null) {
        // 공유 주소 처리
        await SharedAppGroupHandler.checkAndHandleSharedAddress(
          context,
          navigateToSharedLink: false,
        );

        // 위치 정보
        await context
            .read<MapSampleViewModel>()
            .checkLocationPermissionAndFetch();

        // 리스트
        await context.read<ListViewModel>().loadLists();

        // 프로필 통계
        await context
            .read<ProfileViewModel>()
            .fetchUserStats(userId);
      }

      _nextRoute = '/home';

      debugPrint('🏠 [Splash] → /home');

    } catch (e) {
      debugPrint('❌ [Splash] 초기화 실패: $e');

      // 로그인은 되어 있으므로
      // 초기화 작업 하나가 실패했다고 로그인 화면으로 보내지는 않음
      _nextRoute = '/home';
    }

    _isLoading = false;

    notifyListeners();

    // Auth 이벤트 구독
    _subscribeAuthState();
  }

  void _subscribeAuthState() {
    _authSub?.cancel();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
          (data) async {
        if (_alreadyNavigated) return;

        final event = data.event;
        final session = data.session;

        debugPrint(
          '🔐 [Auth] event=$event, session=${session != null}',
        );

        if (event == AuthChangeEvent.signedIn && session != null) {
          final userId = session.user.id;

          final context = navigatorKey.currentContext;

          if (context == null) return;

          try {
            final response = await Supabase.instance.client
                .from('profiles')
                .select('nickname')
                .eq('id', userId)
                .maybeSingle();

            final nickname = response?['nickname'] as String?;

            if (nickname == null || nickname.isEmpty) {
              _nextRoute = '/nickname_setup';
              _arguments = userId;
            } else {
              await context
                  .read<ListViewModel>()
                  .loadLists();

              await context
                  .read<ProfileViewModel>()
                  .fetchUserStats(userId);

              _nextRoute = '/home';
            }

            notifyListeners();

          } catch (e) {
            debugPrint(
              '❌ [Auth] 닉네임 조회 실패: $e',
            );

            _nextRoute = '/home';
            notifyListeners();
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }
}
