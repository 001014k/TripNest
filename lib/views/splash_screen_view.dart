import 'package:flutter/material.dart';
import '../design/app_design.dart'; // 디자인 시스템 import
import '../main.dart';
import 'package:provider/provider.dart';
import '../viewmodels/splash_viewmodel.dart';

class SplashScreenView extends StatefulWidget {
  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatingAnimation;
  bool _alreadyNavigated = false;


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
      // 3️⃣ SplashViewModel startSplash 호출
      final splashVM = context.read<SplashViewModel>();
      splashVM.startSplash();
    });
  }

  void _initializeAnimations() {
    // 페이드 인 애니메이션
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // 스케일 애니메이션
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // 플로팅 애니메이션
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _floatingAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _floatingController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDesign.backgroundGradient,
        ),
        child: Stack(
          children: [
            // 백그라운드 장식 요소들
            _buildBackgroundDecorations(),

            // 메인 콘텐츠
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Consumer<SplashViewModel>(
                  builder: (context, vm, child) {
                    // 화면 이동 처리
                    if (!_alreadyNavigated && vm.nextRoute != null) {
                      _alreadyNavigated = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        navigatorKey.currentState?.pushNamedAndRemoveUntil(
                          vm.nextRoute!,
                              (route) => false,
                          arguments: vm.arguments,
                        );
                      });
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogoSection(),
                        const SizedBox(height: AppDesign.spacing40),
                        _buildBrandName(),
                        const SizedBox(height: AppDesign.spacing16),
                        _buildSubtitle(),
                        const SizedBox(height: AppDesign.spacing80),
                        _buildLoadingIndicator(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // 상단 우측 장식
        Positioned(
          top: 100,
          right: 30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppDesign.travelBlue.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // 하단 좌측 장식
        Positioned(
          bottom: 150,
          left: 20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppDesign.travelPurple.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // 중앙 우측 장식
        Positioned(
          top: 300,
          right: 80,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppDesign.travelOrange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: AppDesign.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppDesign.travelBlue.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -10,
                  ),
                  BoxShadow(
                    color: AppDesign.travelPurple.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('assets/kmj.png'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandName() {
    return ShaderMask(
      shaderCallback: (bounds) => AppDesign.primaryGradient.createShader(bounds),
      child: Text(
        'TripNest',
        style: AppDesign.headingXL.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -1.5,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing20,
        vertical: AppDesign.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppDesign.travelBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(
          color: AppDesign.travelBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flight_takeoff,
            color: AppDesign.travelBlue,
            size: 16,
          ),
          const SizedBox(width: AppDesign.spacing8),
          Text(
            '새로운 여행이 시작됩니다',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.travelBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDesign.spacing16),
          decoration: BoxDecoration(
            color: AppDesign.cardBg,
            shape: BoxShape.circle,
            boxShadow: AppDesign.softShadow,
          ),
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
              backgroundColor: AppDesign.borderColor,
            ),
          ),
        ),
        const SizedBox(height: AppDesign.spacing16),
        Text(
          '앱을 준비하고 있어요...',
          style: AppDesign.bodyMedium.copyWith(
            color: AppDesign.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}