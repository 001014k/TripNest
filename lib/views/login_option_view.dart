import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertrip/views/terms_agreement_view.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/list_viewmodel.dart';
import '../viewmodels/login_option_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'email_login_page.dart';
import '../design/app_design.dart'; // 디자인 시스템 import

class CombinedLoginView extends StatefulWidget {
  const CombinedLoginView({super.key});

  @override
  State<CombinedLoginView> createState() => _CombinedLoginViewState();
}

class _CombinedLoginViewState extends State<CombinedLoginView> {
  late final StreamSubscription<supa.AuthState> _authSubscription;
  bool _navigated = false; // 👈 클래스 상단에 선언 (StatefulWidget 내)

  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (!_navigated && event == AuthChangeEvent.signedIn && session != null) {
        _navigated = true;

        final userId = session.user.id;

        try {
          // 1. profiles 테이블에서 nickname 확인
          final response = await Supabase.instance.client
              .from('profiles')
              .select('nickname')
              .eq('id', userId)
              .maybeSingle();

          final nickname = response?['nickname'] as String?;

          // CombinedLoginView 내부의 _authSubscription 리스너 안
          if (nickname == null || nickname.isEmpty) {
            // 닉네임이 없다면 약관 동의 페이지로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TermsAgreementPage(userId: userId),
              ),
            );
          } else {
            // 닉네임이 있다면 기존 로직 실행 (홈으로 이동)
            await Future.wait([
              context.read<ProfileViewModel>().fetchUserStats(userId),
              context.read<ListViewModel>().loadLists(),
            ]);
            Navigator.pushReplacementNamed(context, '/home');
          }
        } catch (e) {
          debugPrint("Auth 이벤트 처리 실패: $e");
          // 오류나도 일단 홈으로
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 첫 진입이고 플래그 있으면 스낵바 띄우기
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args?['showDeletedMessage'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('계정이 삭제되었습니다. 이용해 주셔서 감사합니다!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel()..loadUserPreferences(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, child) {
          // 컨트롤러와 뷰모델 상태 동기화
          _emailController.text = viewModel.email;
          _passwordController.text = viewModel.password;

          _emailController.addListener(() {
            if (_emailController.text != viewModel.email) {
              viewModel.setEmail(_emailController.text);
            }
          });
          _passwordController.addListener(() {
            if (_passwordController.text != viewModel.password) {
              viewModel.setPassword(_passwordController.text);
            }
          });

          return Scaffold(
            backgroundColor: AppDesign.primaryBg,
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppDesign.backgroundGradient,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDesign.spacing24,
                      vertical: AppDesign.spacing32
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppDesign.spacing40),

                      // 로고 및 타이틀 섹션
                      Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: AppDesign.elevatedShadow,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 58,
                              backgroundImage: AssetImage('assets/kmj.png'),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: AppDesign.spacing24),

                          Text(
                            'TripNest',
                            style: AppDesign.headingXL.copyWith(
                              foreground: Paint()
                                ..shader = AppDesign.primaryGradient
                                    .createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                            ),
                          ),
                          const SizedBox(height: AppDesign.spacing8),

                          Text(
                            '여행의 새로운 시작',
                            style: AppDesign.bodyLarge.copyWith(
                              color: AppDesign.secondaryText,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDesign.spacing80),

                      // 메인 로그인 카드
                      Container(
                        padding: const EdgeInsets.all(AppDesign.spacing32),
                        decoration: BoxDecoration(
                          color: AppDesign.cardBg,
                          borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                          boxShadow: AppDesign.softShadow,
                        ),
                        child: Column(
                          children: [
                            // 이메일 로그인 버튼
                            _primaryLoginButton(),

                            const SizedBox(height: AppDesign.spacing32),

                            // OR 구분선
                            _buildDivider(),

                            const SizedBox(height: AppDesign.spacing32),

                            // 소셜 로그인 버튼들
                            _socialLoginButton(
                              context,
                              label: 'Google로 계속하기',
                              backgroundColor: AppDesign.cardBg,
                              foregroundColor: AppDesign.primaryText,
                              icon: Container(
                                padding: const EdgeInsets.all(2),
                                child: Image.asset('assets/google_signin_button.png', height: 20),
                              ),
                              borderColor: AppDesign.borderColor,
                              onPressed: () => _handleSocialLogin(context, viewModel.signInWithGoogle, 'Google 로그인 실패'),
                            ),

                            const SizedBox(height: AppDesign.spacing16),

                            _socialLoginButton(
                              context,
                              label: 'Kakao로 계속하기',
                              backgroundColor: const Color(0xFFFFE812),
                              foregroundColor: const Color(0xFF3C1E1E),
                              icon: Container(
                                padding: const EdgeInsets.all(2),
                                child: Image.asset('assets/kakao_icon.png', height: 20),
                              ),
                              onPressed: () => _handleSocialLogin(context, viewModel.signInWithKakao, 'Kakao 로그인 실패'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppDesign.spacing32),

                      // 하단 링크들
                      _buildBottomLinks(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _primaryLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: AppDesign.glowShadow,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppDesign.whiteText,
          padding: const EdgeInsets.symmetric(vertical: AppDesign.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmailLoginPage()),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 20),
            const SizedBox(width: AppDesign.spacing8),
            Text(
              '이메일로 로그인',
              style: AppDesign.bodyMedium.copyWith(
                color: AppDesign.whiteText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppDesign.borderColor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDesign.spacing16),
          child: Text(
            '또는 소셜 계정으로 로그인',
            style: AppDesign.caption.copyWith(
              color: AppDesign.subtleText,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppDesign.borderColor,
          ),
        ),
      ],
    );
  }

  Widget _socialLoginButton(
      BuildContext context, {
        required String label,
        required Color backgroundColor,
        required Color foregroundColor,
        required Widget icon,
        required VoidCallback onPressed,
        Color? borderColor,
      }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: AppDesign.spacing12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: AppDesign.spacing12),
            Text(
              label,
              style: AppDesign.bodyMedium.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLinks() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.spacing16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTextButton(
            text: '회원가입',
            onPressed: () => Navigator.pushNamed(context, '/signup'),
          ),
          Container(
            width: 1,
            height: 16,
            color: AppDesign.borderColor,
          ),
          _buildTextButton(
            text: '비밀번호 찾기',
            onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesign.spacing16,
          vertical: AppDesign.spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
        ),
      ),
      child: Text(
        text,
        style: AppDesign.bodyMedium.copyWith(
          color: AppDesign.travelBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _handleSocialLogin(
      BuildContext context,
      Future<void> Function() loginMethod,
      String failMessage,
      ) async {
    if (_navigated) return; // 👈 이미 이동했으면 아무것도 하지 않음

    try {
      await loginMethod();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$failMessage: $e'),
          backgroundColor: AppDesign.sunsetGradientStart,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
          ),
        ),
      );
    }
  }
}