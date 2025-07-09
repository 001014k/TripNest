import 'package:flutter/material.dart';
import 'package:fluttertrip/viewmodels/collaborator_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:fluttertrip/env.dart'; // Env 클래스 import

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
import 'viewmodels/markercreationscreen_viewmodel.dart';

// Service imports...
import 'services/marker_service.dart';

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
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );

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
        ChangeNotifierProvider(create: (_) => MarkerCreationScreenViewModel()),
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
  bool _alreadyNavigated = false;

  @override
  void initState() {
    super.initState();

    // ✅ 딥링크 수신 시 Supabase가 처리하도록
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        debugPrint("✅ 딥링크 URI 수신됨: $uri");
        Supabase.instance.client.auth.getSessionFromUrl(uri); // 👉 내부적으로 처리됨
      }
    });

    // ✅ 인증 상태 변화 리스너 (자동 세션 반영)
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (_alreadyNavigated) return;
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _alreadyNavigated = true;
        final userId = session.user.id;
        debugPrint("✅ 로그인 완료: $userId");

        final context = navigatorKey.currentContext;
        if (context != null) {
          await context.read<ListViewModel>().loadLists();
          await context.read<ProfileViewModel>().fetchUserStats(userId);
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
        }
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
