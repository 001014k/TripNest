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
    _isLoading = true;
    notifyListeners();

    // 1️⃣ 최소 3초 대기
    await Future.delayed(const Duration(seconds: 3));

    final context = navigatorKey.currentContext;

    if (context != null) {
      // 2️⃣ 공유 주소 처리
      SharedAppGroupHandler.checkAndHandleSharedAddress(context);

      // 3️⃣ 위치 권한 요청 및 현재 위치 fetch
      await context.read<MapSampleViewModel>().checkLocationPermissionAndFetch();
    }

    // 4️⃣ 딥링크 구독
    _deepLinkSub = AppLinks().uriLinkStream.listen((uri) {
      if (uri != null) {
        Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });

    // 5️⃣ 현재 인증 상태 확인 → 기본 이동 결정
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final userId = session.user.id;

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
          // 로그인 + 닉네임 있음
          if (context != null) {
            await context.read<ListViewModel>().loadLists();
            await context.read<ProfileViewModel>().fetchUserStats(userId);
          }
          _nextRoute = '/home';
        }
      } catch (e) {
        debugPrint("❌ 닉네임 조회 실패: $e");
        _nextRoute = '/home';
      }
    } else {
      // 로그인 안 되어 있음
      _nextRoute = '/login_option';
    }

    _isLoading = false;
    notifyListeners();

    // 6️⃣ Auth 이벤트 구독 (덮어쓰기용)
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (_alreadyNavigated) return;
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _alreadyNavigated = true;
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
            await context.read<ListViewModel>().loadLists();
            await context.read<ProfileViewModel>().fetchUserStats(userId);
            _nextRoute = '/home';
          }
          notifyListeners();
        } catch (e) {
          debugPrint("❌ Auth 이벤트 닉네임 조회 실패: $e");
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }
}
