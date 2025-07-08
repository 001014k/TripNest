import 'package:flutter/material.dart';
import 'package:fluttertrip/viewmodels/collaborator_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

// ViewModel imports...
import 'viewmodels/mapsample_viewmodel.dart';
import 'viewmodels/bookmark_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/forgot_password_viewmodel.dart';
import 'viewmodels/friend_management_viewmodel.dart';
import 'viewmodels/Imageview_viewmodel.dart';
import 'viewmodels/list_viewmodel.dart';
import 'viewmodels/login_option_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/signup_viewmodel.dart';
import 'viewmodels/splash_viewmodel.dart';
import 'viewmodels/add_markers_to_list_viewmodel.dart';

// Service imports...
import 'services/marker_service.dart';
import 'services/supabase_manager.dart';

// View imports...
import 'views/bookmark_view.dart';
import 'views/forgot_password_view.dart';
import 'views/friend_management_view.dart';
import 'views/mapsample_view.dart';
import 'views/BookmarkListTab_view.dart';
import 'views/signup_view.dart';
import 'views/splash_screen_view.dart';
import 'views/user_list_view.dart';
import 'views/dashboard_view.dart';
import 'views/login_option_view.dart';

/// ✅ 전역 Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseManager.initialize();
    await Supabase.instance.client.auth.getSessionFromUrl(Uri.base);
    await MarkerService().syncOfflineMarkers();
  } catch (e) {
    print('Error during initialization: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AddMarkersToListViewModel()),
        ChangeNotifierProvider(create: (_) => MapSampleViewModel()),
        ChangeNotifierProvider(create: (_) => BookmarkViewmodel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordViewModel()),
        ChangeNotifierProvider(create: (_) => FriendManagementViewModel()),
        ChangeNotifierProvider(create: (_) => ImageviewViewmodel()),
        ChangeNotifierProvider(create: (_) => ListViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SignupViewModel()),
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => CollaboratorViewModel()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri?>? _sub;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    // 딥링크 수신 처리
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        try {
          debugPrint("✅ 딥링크 URI 수신됨: $uri");
          final response = await Supabase.instance.client.auth.getSessionFromUrl(uri);
          if (response.session != null) {
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
          } else {
            debugPrint('❌ 세션 파싱 실패 (session == null)');
          }
        } catch (e) {
          debugPrint('❌ 딥링크 처리 중 예외 발생: $e');
        }
      }
    });

    // ✅ 인증 상태 변화 리스너 추가
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final userId = session.user.id;
        debugPrint("✅ 로그인 완료: $userId");

        // ViewModel 데이터 초기화
        final context = navigatorKey.currentContext;
        if (context != null) {
          await context.read<ListViewModel>().loadLists();
          await context.read<ProfileViewModel>().fetchUserStats(userId);

          // 필요시 홈 화면으로 이동
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
        }
      }

      if (event == AuthChangeEvent.signedOut) {
        debugPrint("🚪 로그아웃됨");
      }
    });
  }


  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Navigator 키 등록
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreenView(),
        '/login_option': (context) => CombinedLoginView(),
        '/signup': (context) => SignupPage(),
        '/forgot_password': (context) => ForgotPasswordView(),
        '/home': (context) => MapSampleView(),
        '/dashboard': (context) => DashboardView(),
        '/friend_management': (context) => FriendManagementView(),
        '/page_view': (context) => BookmarklisttabView(),
        '/bookmark': (context) => BookmarkView(),
        '/user_list': (context) => UserListView(),
      },
    );
  }
}
