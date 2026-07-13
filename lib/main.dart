import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertrip/views/profile_view.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluttertrip/services/app_group_handler_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:fluttertrip/env.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fluttertrip/models/cached_photo_url.dart';

// ViewModel imports...
import 'firebase_options.dart';
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
import 'services/notification_service.dart';

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
import 'views/notification_settings_view.dart';

/// ✅ 전역 Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<void> saveFcmToken() async {
  final messaging = FirebaseMessaging.instance;

  // 1. 기존 토큰 삭제 후 재발급 강제 (필요시)
  // await messaging.deleteToken();

  final token = await messaging.getToken();

  if (token != null) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await Supabase.instance.client
          .from('user_push_tokens')
          .upsert({
        'user_id': userId,
        'token': token,
      }, onConflict: 'user_id'); // user_id 기준 중복 방지
      debugPrint("✅ 토큰 새로 저장 완료: $token");
    }
  }
}


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('백그라운드 메시지 수신: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==================== Firebase 초기화 ====================
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ Firebase 초기화 성공');
  } catch (e, stack) {
    debugPrint('❌ Firebase 초기화 실패: $e');
    debugPrint('$stack');
    // 여기서 return 하지 말고 Supabase는 계속 초기화
  }
  final options = Firebase.app().options;
  print("현재 앱의 프로젝트 ID: ${options.projectId}");
  print("현재 앱의 Sender ID: ${options.messagingSenderId}");

  // intl + Hive
  await initializeDateFormatting('ko_KR');
  await Hive.initFlutter();
  Hive.registerAdapter(CachedPhotoUrlAdapter());
  await Hive.openBox<CachedPhotoUrl>('photo_urls');

  // ==================== Supabase 초기화 ====================
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    debugPrint('✅ Supabase 초기화 성공');
  } catch (e) {
    debugPrint('❌ Supabase 초기화 실패: $e');
  }

  await NotificationService().initializePushNotifications();
  await MarkerService().syncOfflineMarkers();

  final prefs = await SharedPreferences.getInstance();
  String? savedLanguage = prefs.getString('language');

  if (savedLanguage == null) {
    final deviceLang = PlatformDispatcher.instance.locale.languageCode;
    savedLanguage = (deviceLang == 'ko' || deviceLang == 'en') ? deviceLang : 'en';
    await prefs.setString('language', savedLanguage);
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
        ChangeNotifierProvider(
          create: (_) => MarkerListViewModel(Supabase.instance.client),
        ),
        ChangeNotifierProvider(create: (_) => ChatRecommendationViewModel()),
        ChangeNotifierProvider(
          create: (_) => FriendManagementViewModel()..subscribeToPresence(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _sub;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription? _uriSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        debugPrint('🔐 로그인 감지 - FCM 초기화 시작');

        // FCM 초기화 + 토큰 리프레시
        unawaited(NotificationService().initializePushNotifications());
        unawaited(NotificationService().refreshPushTokenOnLogin());   // ← 강제 리프레시
      }
    });
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
        '/notification_settings': (context) => const NotificationSettingsView(),
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
