import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'viewmodels/mapsample_viewmodel.dart';
import 'viewmodels/bookmark_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/forgot_password_viewmodel.dart';
import 'viewmodels/friend_management_viewmodel.dart';
import '../viewmodels/Imageview_viewmodel.dart';
import '../viewmodels/list_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/signup_viewmodel.dart';
import '../viewmodels/splash_viewmodel.dart';
import 'firebase_options.dart';
import 'services/marker_service.dart';
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
  // Flutter 프레임워크 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 앱이 시작될 때 동기화 작업을 수행
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await MarkerService().syncOfflineMarkers();
  } catch (e) {
    // 에러 처리 로직 (로그 출력 등)
    print('Error during initialization: $e');
  }
  runApp(
      MultiProvider(
        providers: [
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

class MyApp extends StatelessWidget {
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
      },
    );
  }
}