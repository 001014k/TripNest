import 'package:flutter/material.dart';
import 'package:fluttertrip/services/user_service.dart';
import 'package:fluttertrip/services/supabase_manager.dart';
import 'package:fluttertrip/views/login_option_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

// ViewModel imports...
import 'viewmodels/mapsample_viewmodel.dart';
import 'viewmodels/bookmark_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/forgot_password_viewmodel.dart';
import 'viewmodels/friend_management_viewmodel.dart';
import 'viewmodels/Imageview_viewmodel.dart';
import 'viewmodels/list_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/signup_viewmodel.dart';
import 'viewmodels/splash_viewmodel.dart';
import 'viewmodels/add_markers_to_list_viewmodel.dart';

// Service imports...
import 'services/marker_service.dart';

// View imports...
import 'views/bookmark_view.dart';
import 'views/forgot_password_view.dart';
import 'views/friend_management_view.dart';
import 'views/login_view.dart';
import 'views/mapsample_view.dart';
import 'views/BookmarkListTab_view.dart';
import 'views/signup_view.dart';
import 'views/splash_screen_view.dart';
import 'views/user_list_view.dart';
import 'views/dashboard_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  KakaoSdk.init(
    nativeAppKey: 'eff3cb029a3acf98d819ee87f77f8274', // 카카오 네이티브 앱 키
  );
  try {
    await SupabaseManager.initialize();
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
  StreamSubscription<Uri?>? _sub;

  @override
  void initState() {
    super.initState();

    _sub = uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        // 리디렉션 URL에서 세션을 받아옴
        final response = await Supabase.instance.client.auth.getSessionFromUrl(uri);

        if (response.session != null) {
          // 로그인 성공 시 홈 화면으로 이동
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        } else {
          // 로그인 실패 처리 (선택사항)
          debugPrint('로그인 세션 파싱 실패');
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/friend_management' : (context) => FriendManagementView(),
        '/page_view' : (context) => BookmarklisttabView(),
        '/bookmark' : (context) => BookmarkView(),
        '/splash': (context) => SplashScreenView(),
        '/login': (context) => LoginView(),
        '/signup': (context) => SignupPage(),
        '/forgot_password': (context) => ForgotPasswordView(),
        '/user_list': (context) => UserListView(),
        '/home': (context) => MapSampleView(),
        '/dashboard': (context) => DashboardView(),
        '/login_option': (context) => LoginOptionView(),
      },
    );
  }
}
