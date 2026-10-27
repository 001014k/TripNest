import 'views/notifications/notifications_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'navigation/app_tab_shell.dart';
import 'navigation/app_page_route.dart';
import 'views/community/community_board_view.dart';
import 'views/schedule/schedule_view.dart';
import 'viewmodels/home/home_weather_viewmodel.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertrip/design/app_design.dart';
import 'package:fluttertrip/views/profile/profile_view.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluttertrip/views/shared_links/shared_address_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:fluttertrip/env.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fluttertrip/models/places/cached_photo_url.dart';
import 'models/shared_links/shared_link_model.dart';

// ViewModel imports...
import 'firebase_options.dart';
import 'viewmodels/map/mapsample_viewmodel.dart';
import 'viewmodels/friends/friend_management_viewmodel.dart';
import 'viewmodels/markers/imageview_viewmodel.dart';
import 'viewmodels/lists/list_viewmodel.dart';
import 'viewmodels/profile/profile_viewmodel.dart';
import 'viewmodels/auth/splash_viewmodel.dart';
import 'viewmodels/lists/add_markers_to_list_viewmodel.dart';
import 'viewmodels/markers/markercreationscreen_viewmodel.dart';
import 'viewmodels/shared_links/shared_link_viewmodel.dart';
import 'package:fluttertrip/viewmodels/lists/collaborator_viewmodel.dart';
import 'viewmodels/home/home_viewmodel.dart';
import 'viewmodels/markers/marker_list_screen_viewmodel.dart';

// Service imports...
import 'services/markers/marker_service.dart';
import 'services/notifications/notification_service.dart';

// View imports...
import 'views/auth/forgot_password_view.dart';
import 'views/friends/friend_management_view.dart';
import 'views/map/mapsample_view.dart';
import 'views/auth/signup_view.dart';
import 'views/auth/splash_screen_view.dart';
import 'views/auth/login_option_view.dart';
import 'views/home/home_view.dart';
import 'views/lists/list_view.dart';
import 'views/shared_links/shared_link_view.dart';
import 'views/shared_links/shared_link_detail_view.dart';
import 'views/markers/marker_list_screen_view.dart';
import 'views/auth/nickname_dialog_view.dart';
import 'views/notifications/notification_settings_view.dart';

/// ✅ 전역 Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('백그라운드 메시지 수신: ${message.messageId}');
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
  debugPrint("현재 앱의 프로젝트 ID: ${options.projectId}");
  debugPrint("현재 앱의 Sender ID: ${options.messagingSenderId}");

  // intl + Hive
  await initializeDateFormatting('ko_KR');
  await Hive.initFlutter();
  Hive.registerAdapter(CachedPhotoUrlAdapter());
  await Hive.openBox<CachedPhotoUrl>('photo_urls');

  // ==================== Supabase 초기화 ====================
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
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
    savedLanguage =
        (deviceLang == 'ko' || deviceLang == 'en') ? deviceLang : 'en';
    await prefs.setString('language', savedLanguage);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppTabController()),
        ChangeNotifierProvider(create: (_) => HomeWeatherViewModel()),
        ChangeNotifierProvider(create: (_) => AddMarkersToListViewModel()),
        ChangeNotifierProvider(create: (_) => MapSampleViewModel()),
        ChangeNotifierProvider(create: (_) => SharedLinkViewModel()),
        ChangeNotifierProvider(
          create: (_) => FriendManagementViewModel()..subscribeToPresence(),
        ),
        ChangeNotifierProvider(create: (_) => ImageviewViewmodel()),
        ChangeNotifierProvider(create: (_) => ListViewModel()..loadLists()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => CollaboratorViewModel()),
        ChangeNotifierProvider(create: (_) => MarkerCreationScreenViewModel()),
        ChangeNotifierProvider(create: (_) => HomeDashboardViewModel()),
        ChangeNotifierProvider(
          create: (_) => MarkerListViewModel(Supabase.instance.client),
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
      }
    });
  }

  // ✅ 앱 생명주기 변경 감지: 포그라운드 전환 시 공유 처리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        handleIncomingSharedAddress(context);
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
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => ShadTheme(
        data: AppDesign.shadTheme,
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          supportedLocales: const [Locale('ko', 'KR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppDesign.lightTheme,
          initialRoute: '/splash',
          onGenerateRoute: (settings) {
            final builders = <String, WidgetBuilder>{
            '/splash': (context) => SplashScreenView(),
            '/login_option': (context) => CombinedLoginView(),
            '/signup': (context) => SignupPage(),
            '/forgot_password': (context) => ForgotPasswordView(),
            '/map': (context) => MapSampleView(),
            '/community': (context) => const CommunityBoardView(),
            '/schedule': (context) => const ScheduleView(),
            '/friend_management': (context) => FriendManagementView(),
            '/home': (context) => HomeDashboardView(),
            '/list': (context) => ListPage(),
            '/shared_link': (context) => SharedLinkView(),
            '/shared_link_detail': (context) {
              final link =
                  ModalRoute.of(context)!.settings.arguments as SharedLinkModel;
              return SharedLinkDetailView(link: link);
            },
            '/marker_list': (context) => MarkerListScreen(),
            '/notifications': (context) => const NotificationsView(),
            '/notification_settings': (context) =>
                const NotificationSettingsView(),
            '/profile': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments as String? ??
                      Supabase.instance.client.auth.currentUser?.id ??
                      '';
              return ProfilePage(userId: args);
            },
            '/nickname_setup': (context) {
              final userId =
                  ModalRoute.of(context)!.settings.arguments as String;
              return NicknameSetupPage(userId: userId);
            },
          };
            if (AppTabController.routes.contains(settings.name)) {
              return AppPageRoute<dynamic>(settings: settings, motion: AppMotion.fade,
                builder: (context) => AppTabShell(
                  controller: context.read<AppTabController>(),
                  initialRoute: settings.name!,
                  builders: {for (final route in AppTabController.routes) route: builders[route]!},
                ));
            }
            final builder = builders[settings.name];
            if (builder == null) return null;
            return AppPageRoute<dynamic>(settings: settings, builder: builder,
                motion: settings.name == '/login_option' || settings.name == '/splash'
                    ? AppMotion.fade
                    : settings.name == '/signup' || settings.name == '/nickname_setup'
                        ? AppMotion.editor : AppMotion.detail);
          },
        ),
      ),
    );
  }
}
