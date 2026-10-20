import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/reference_design.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../viewmodels/splash_viewmodel.dart';
import '../viewmodels/mapsample_viewmodel.dart';
import '../viewmodels/list_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'shared_address_handler.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView>
    with TickerProviderStateMixin {
  late final AnimationController _dotsController;
  bool _alreadyNavigated = false;
  SplashViewModel? _splashViewModel;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MediaQuery.disableAnimationsOf(context)) {
        _dotsController.repeat();
      }
      // 3️⃣ SplashViewModel startSplash 호출
      final splashVM = context.read<SplashViewModel>();
      _splashViewModel = splashVM;
      splashVM.startSplash(prepareAuthenticatedUser: _prepareAuthenticatedUser);
    });
  }

  Future<void> _prepareAuthenticatedUser(String userId) async {
    if (!mounted) return;
    try {
      await handleIncomingSharedAddress(
        context,
        navigateToSharedLink: false,
      ).timeout(const Duration(seconds: 3));
    } on TimeoutException {
      debugPrint('⚠️ Splash 공유 주소 확인 시간 초과');
    }
    if (!mounted) return;

    // 현재 위치는 홈 진입에 필수 데이터가 아니므로 Splash를 막지 않는다.
    unawaited(
      context.read<MapSampleViewModel>().checkLocationPermissionAndFetch(),
    );

    await Future.wait([
      context
          .read<ListViewModel>()
          .loadLists()
          .timeout(const Duration(seconds: 8)),
      context
          .read<ProfileViewModel>()
          .fetchUserStats(userId)
          .timeout(const Duration(seconds: 8)),
    ]);
  }

  void _initializeAnimations() {
    _dotsController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
  }

  @override
  void dispose() {
    _splashViewModel?.stopWatchingAuth();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Consumer<SplashViewModel>(builder: (context, vm, _) {
              if (!_alreadyNavigated && vm.nextRoute != null) {
                _alreadyNavigated = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  navigatorKey.currentState?.pushNamedAndRemoveUntil(
                      vm.nextRoute!, (route) => false,
                      arguments: vm.arguments);
                });
              }
              return LayoutBuilder(
                  builder: (context, constraints) => Stack(
                        fit: StackFit.expand,
                        children: [
                          Align(
                            alignment: const Alignment(0, -.03),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                        width: 80,
                                        height: 66,
                                        child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: ReferenceLogo())),
                                    const SizedBox(height: 16),
                                    const Text('TripNest',
                                        style: TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -1.5,
                                            color: Colors.black,
                                            height: 1.15)),
                                    const SizedBox(height: 20),
                                    const Text('나만의 여행 지도를 만드는 중',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF696D76),
                                            height: 1.5)),
                                  ]),
                            ),
                          ),
                          Positioned(
                            bottom: constraints.maxHeight * .17,
                            left: 0,
                            right: 0,
                            child: Semantics(
                              label: '앱을 준비하고 있어요',
                              child: AnimatedBuilder(
                                  animation: _dotsController,
                                  builder: (context, _) {
                                    final active = (_dotsController.value * 3)
                                        .floor()
                                        .clamp(0, 2);
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                          3,
                                          (index) => Container(
                                                width: 8,
                                                height: 8,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: index == active
                                                        ? const Color(
                                                            0xFF171717)
                                                        : const Color(
                                                            0xFFD3D4D7)),
                                              )),
                                    );
                                  }),
                            ),
                          ),
                          const Positioned(
                              left: 24,
                              right: 24,
                              bottom: 28,
                              child: Text('여행을 더 쉽게',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13, color: Color(0xFF696D76)))),
                        ],
                      ));
            }),
          ),
        ),
      );
}
