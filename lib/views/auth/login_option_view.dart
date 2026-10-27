import '../../navigation/app_page_route.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertrip/views/auth/terms_agreement_view.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth/auth_service.dart';
import '../../viewmodels/lists/list_viewmodel.dart';
import '../../viewmodels/auth/login_option_viewmodel.dart';
import '../../viewmodels/profile/profile_viewmodel.dart';
import '../../widgets/common/reference_design.dart';
import '../../design/app_design.dart'; // 디자인 시스템 import

class CombinedLoginView extends StatefulWidget {
  const CombinedLoginView({super.key});

  @override
  State<CombinedLoginView> createState() => _CombinedLoginViewState();
}

class _CombinedLoginViewState extends State<CombinedLoginView> {
  late final StreamSubscription<AuthState> _authSubscription;
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  late final LoginViewModel _viewModel;
  bool _hidePassword = true;
  bool _socialLoading = false;
  bool _navigated = false; // 👈 클래스 상단에 선언 (StatefulWidget 내)

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();
    _loadPreferences();

    _authSubscription = _authService.authStateChanges.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (!_navigated && event == AuthChangeEvent.signedIn && session != null) {
        _navigated = true;

        final userId = session.user.id;

        try {
          final hasNickname = await _authService.hasNickname(userId);
          if (!mounted) return;

          // CombinedLoginView 내부의 _authSubscription 리스너 안
          if (!hasNickname) {
            // 닉네임이 없다면 약관 동의 페이지로 이동
            Navigator.pushReplacement(
              context,
              AppPageRoute(motion: AppMotion.editor,
                builder: (context) => TermsAgreementPage(userId: userId),
              ),
            );
          } else {
            // 닉네임이 있다면 기존 로직 실행 (홈으로 이동)
            await Future.wait([
              context.read<ProfileViewModel>().fetchUserStats(userId),
              context.read<ListViewModel>().loadLists(),
            ]);
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/home');
          }
        } catch (e) {
          debugPrint("Auth 이벤트 처리 실패: $e");
          // 오류나도 일단 홈으로
          if (!mounted) return;
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
    _passwordFocus.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 첫 진입이고 플래그 있으면 스낵바 띄우기
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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

  Future<void> _loadPreferences() async {
    await _viewModel.loadUserPreferences();
    if (!mounted) return;
    if (_emailController.text.isEmpty) _emailController.text = _viewModel.email;
    if (_passwordController.text.isEmpty) {
      _passwordController.text = _viewModel.password;
    }
  }

  Future<void> _login() async {
    if (_viewModel.isLoading || _socialLoading || _navigated) return;
    FocusScope.of(context).unfocus();
    _viewModel.setEmail(_emailController.text.trim());
    _viewModel.setPassword(_passwordController.text);
    final error = await _viewModel.login();
    // The shared auth listener handles both email and social login navigation.
    if (error != null && mounted && !_navigated) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final busy = _viewModel.isLoading || _socialLoading;
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(top: 28, bottom: 12),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 26),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const ReferenceLogo(),
                                  const SizedBox(width: 10),
                                  Text('TripNest',
                                      style: AppDesign.headingXL
                                          .copyWith(fontSize: 28)),
                                ]),
                                const SizedBox(height: 28),
                                Text('다시 돌아오신 걸 환영해요',
                                    style: AppDesign.headingLarge
                                        .copyWith(fontSize: 25)),
                                const SizedBox(height: 8),
                                Text('저장한 장소와 여행 리스트를 계속 관리해보세요.',
                                    style: AppDesign.bodyMedium.copyWith(
                                        color: AppDesign.secondaryText,
                                        fontWeight: FontWeight.w400)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12)),
                            child: Image.asset('assets/images/login_seoul.png',
                                height: 140,
                                fit: BoxFit.cover,
                                excludeFromSemantics: true),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _emailController,
                                  autofillHints: const [
                                    AutofillHints.username,
                                    AutofillHints.email
                                  ],
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  enabled: !busy,
                                  onSubmitted: (_) =>
                                      _passwordFocus.requestFocus(),
                                  decoration: _decoration('이메일을 입력해주세요',
                                      Icons.mail_outline_rounded),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  autofillHints: const [AutofillHints.password],
                                  obscureText: _hidePassword,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  enabled: !busy,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _login(),
                                  decoration: _decoration('비밀번호를 입력해주세요',
                                          Icons.lock_outline_rounded)
                                      .copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _hidePassword
                                          ? '비밀번호 표시'
                                          : '비밀번호 숨기기',
                                      onPressed: () => setState(
                                          () => _hidePassword = !_hidePassword),
                                      icon: Icon(
                                          _hidePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 21,
                                          color: AppDesign.secondaryText),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: busy
                                        ? null
                                        : () => Navigator.pushNamed(
                                            context, '/forgot_password'),
                                    child: const Text('비밀번호 찾기',
                                        style: TextStyle(
                                            color: AppDesign.secondaryText,
                                            fontSize: 13,
                                            decoration:
                                                TextDecoration.underline)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FilledButton(
                                  onPressed: busy ? null : _login,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppDesign.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(13)),
                                  ),
                                  child: busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Text('로그인',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(height: 20),
                                const Row(children: [
                                  Expanded(
                                      child: Divider(
                                          color: AppDesign.borderColor)),
                                  Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('또는 다른 방법으로 시작하기',
                                          style: AppDesign.bodySmall)),
                                  Expanded(
                                      child: Divider(
                                          color: AppDesign.borderColor)),
                                ]),
                                const SizedBox(height: 16),
                                _socialButton(
                                    'Google로 계속하기',
                                    'assets/google_signin_button.png',
                                    busy
                                        ? null
                                        : () => _socialLogin(
                                            _viewModel.signInWithGoogle)),
                                const SizedBox(height: 12),
                                _socialButton(
                                    '카카오로 계속하기',
                                    'assets/kakao_icon.png',
                                    busy
                                        ? null
                                        : () => _socialLogin(
                                            _viewModel.signInWithKakao)),
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text('아직 계정이 없으신가요?',
                                        style: AppDesign.bodySmall),
                                    TextButton(
                                      onPressed: busy
                                          ? null
                                          : () => Navigator.pushNamed(
                                              context, '/signup'),
                                      child: const Text('회원가입',
                                          style: TextStyle(
                                              color: AppDesign.primaryText,
                                              fontWeight: FontWeight.w700,
                                              decoration:
                                                  TextDecoration.underline)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppDesign.subtleText),
        prefixIcon: Icon(icon, size: 22, color: AppDesign.primaryText),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppDesign.borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppDesign.borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppDesign.primary)),
      );

  Widget _socialButton(String label, String asset, VoidCallback? onPressed) =>
      OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDesign.primaryText,
          backgroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppDesign.borderColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(asset, width: 26, height: 26, fit: BoxFit.contain),
          const SizedBox(width: 12),
          Flexible(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500))),
        ]),
      );

  Future<void> _socialLogin(Future<void> Function() login) async {
    if (_navigated || _socialLoading || _viewModel.isLoading) return;
    setState(() => _socialLoading = true);
    try {
      await login();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인을 시작하지 못했어요. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) setState(() => _socialLoading = false);
    }
  }
}
