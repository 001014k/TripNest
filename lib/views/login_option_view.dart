import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../viewmodels/login_option_viewmodel.dart';
import '../services/user_service.dart';

class CombinedLoginView extends StatefulWidget {
  const CombinedLoginView({super.key});

  @override
  State<CombinedLoginView> createState() => _CombinedLoginViewState();
}

class _CombinedLoginViewState extends State<CombinedLoginView> {
  late final StreamSubscription<supa.AuthState> _authSubscription;

  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _authSubscription =
        supa.Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
          final event = data.event;
          final session = data.session;

          if (event == supa.AuthChangeEvent.signedIn && session != null) {
            final userId = session.user?.id;

            if (!mounted || userId == null) return;

            final hasNickname = await _hasNickname(userId);
            if (hasNickname) {
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              Navigator.pushReplacementNamed(context, '/nickname_setup');
            }
          }
        });
  }

  Future<bool> _hasNickname(String userId) async {
    try {
      return await UserService().hasNickname(userId);
    } catch (e) {
      debugPrint('닉네임 확인 중 오류: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            backgroundColor: const Color(0xFF121212),
            appBar: AppBar(
              title: const Text('FlutterTrip 로그인'),
              backgroundColor: const Color(0xFF121212),
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: AssetImage('assets/kmj.png'),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 24),

                    // 이메일 입력
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '이메일',
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호 입력
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey[900],
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),

                    CheckboxListTile(
                      title: const Text('Remember Me', style: TextStyle(color: Colors.white70)),
                      value: viewModel.rememberMe,
                      onChanged: (v) => viewModel.setRememberMe(v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.cyanAccent,
                      checkColor: Colors.black,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 20),

                    // 이메일 로그인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          String? error = await viewModel.login();
                          if (error == null) {
                            String route = viewModel.email == 'hm4854@gmail.com' ? '/user_list' : '/home';
                            Navigator.pushReplacementNamed(context, route);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        },
                        child: viewModel.isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text('이메일로 로그인', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // OR 구분선
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.white30)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('또는 소셜 계정으로 로그인', style: TextStyle(color: Colors.white54)),
                        ),
                        Expanded(child: Divider(color: Colors.white30)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google 로그인 버튼
                    _socialLoginButton(
                      context,
                      label: 'Google 로그인',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      icon: Image.asset('assets/google_signin_button.png', height: 24),
                      onPressed: () => _handleSocialLogin(context, viewModel.signInWithGoogle, 'Google 로그인 실패'),
                    ),

                    const SizedBox(height: 16),

                    // Kakao 로그인 버튼
                    _socialLoginButton(
                      context,
                      label: 'Kakao 로그인',
                      backgroundColor: const Color(0xFFFFE812),
                      foregroundColor: Colors.black,
                      icon: Image.asset('assets/kakao_icon.png', height: 24),
                      onPressed: () => _handleSocialLogin(context, viewModel.signInWithKakao, 'Kakao 로그인 실패'),
                    ),

                    const SizedBox(height: 24),

                    // 회원가입, 비밀번호 찾기 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text('회원가입', style: TextStyle(color: Colors.cyanAccent)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                          child: const Text('비밀번호 찾기', style: TextStyle(color: Colors.cyanAccent)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _socialLoginButton(
      BuildContext context, {
        required String label,
        required Color backgroundColor,
        required Color foregroundColor,
        required Widget icon,
        required VoidCallback onPressed,
      }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: icon,
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _handleSocialLogin(BuildContext context, Future<void> Function() loginMethod, String failMessage) async {
    try {
      await loginMethod();

      final userId = supa.Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인에 실패했습니다.')));
        return;
      }

      final hasNickname = await _hasNickname(userId);
      if (hasNickname) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/nickname_setup');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$failMessage: $e')));
    }
  }
}
