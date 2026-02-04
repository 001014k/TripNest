import 'package:flutter/material.dart';
import 'package:fluttertrip/views/profile_view.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluttertrip/services/app_group_handler_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:fluttertrip/env.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fluttertrip/models/cached_photo_url.dart';

// ViewModel imports...
import 'viewmodels/mapsample_viewmodel.dart';
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
import 'viewmodels/shared_link_viewmodel.dart';
import 'package:fluttertrip/viewmodels/collaborator_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/marker_list_screen_viewmodel.dart';
import 'package:fluttertrip/viewmodels/chat_recommendation_viewmodel.dart';

// Service imports...
import 'services/marker_service.dart';

// View imports...
import 'views/forgot_password_view.dart';
import 'views/friend_management_view.dart';
import 'views/mapsample_view.dart';
import 'views/signup_view.dart';
import 'views/splash_screen_view.dart';
import 'views/user_list_view.dart';
import 'views/dashboard_view.dart';
import 'views/login_option_view.dart';
import 'views/home_view.dart';
import 'views/list_view.dart';
import 'views/shared_link_view.dart';
import 'views/marker_list_screen_view.dart';
import 'views/nickname_dialog_view.dart';

/// ✅ 전역 Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // intl 로케일 데이터 초기화 추가
  await initializeDateFormatting('ko_KR');
  // Hive 초기화(flutter 앱에서는 반드시 initFlutter() 사용)
  await Hive.initFlutter();
  Hive.registerAdapter(CachedPhotoUrlAdapter());

  // 앱 시작 시 바로 Box 열어두기 → ViewModel에서 openBox 호출 불필요
  await Hive.openBox<CachedPhotoUrl>('photo_urls');


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
        ChangeNotifierProvider(create: (_) => SharedLinkViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordViewModel()),
        ChangeNotifierProvider(create: (_) => FriendManagementViewModel()),
        ChangeNotifierProvider(create: (_) => ImageviewViewmodel()),
        ChangeNotifierProvider(create: (_) => ListViewModel()..loadLists()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SignupViewModel()),
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => CollaboratorViewModel()),
        ChangeNotifierProvider(create: (_) => MarkerCreationScreenViewModel()),
        ChangeNotifierProvider(create: (_) => HomeDashboardViewModel()),
        ChangeNotifierProvider(create: (_) => MarkerListViewModel(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => ChatRecommendationViewModel()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri?>? _sub;
  StreamSubscription<AuthState>? _authSub;
  bool _alreadyNavigated = false;
  StreamSubscription? _uriSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 👈 앱 생명주기 감지
  }

  // ✅ 앱 생명주기 변경 감지: 포그라운드 전환 시 공유 처리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        SharedAppGroupHandler.checkAndHandleSharedAddress(context);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
    _uriSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreenView(),
        '/login_option': (context) => CombinedLoginView(),
        '/signup': (context) => SignupPage(),
        '/forgot_password': (context) => ForgotPasswordView(),
        '/map': (context) => MapSampleView(),
        '/dashboard': (context) => DashboardView(),
        '/friend_management': (context) => FriendManagementView(),
        '/user_list': (context) => UserListView(),
        '/home': (context) => HomeDashboardView(),
        '/list': (context) => ListPage(),
        '/shared_link': (context) => SharedLinkView(),
        '/marker_list': (context) => MarkerListScreen(),
        '/profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return ProfilePage(userId: args);
        },
        '/nickname_setup': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return NicknameSetupPage(userId: userId);
        },
      },
    );
  }
}

