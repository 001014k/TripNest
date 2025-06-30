import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../viewmodels/login_viewmodel.dart';
import '../services/user_service.dart';

class LoginOptionView extends StatefulWidget {
  const LoginOptionView({super.key});

  @override
  State<LoginOptionView> createState() => _LoginOptionViewState();
}

class _LoginOptionViewState extends State<LoginOptionView> {
  late final StreamSubscription<supa.AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    // (선택 사항) auth 상태 변화 리스너 유지 (필요 없으면 삭제 가능)
    _authSubscription = supa.Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const Text('로그인 선택'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google 로그인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          try {
                            await viewModel.signInWithGoogle();

                            final userId = supa.Supabase.instance.client.auth.currentUser?.id;
                            if (userId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('로그인에 실패했습니다.')),
                              );
                              return;
                            }

                            final hasNickname = await _hasNickname(userId);

                            if (hasNickname) {
                              Navigator.pushReplacementNamed(context, '/home');
                            } else {
                              Navigator.pushReplacementNamed(context, '/nickname_setup');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Google 로그인 실패: $e')),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/google_signin_button.png', height: 24),
                            const SizedBox(width: 12),
                            const Text('Google 로그인'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Kakao 로그인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE812),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          try {
                            await viewModel.signInWithKakao();

                            final userId = supa.Supabase.instance.client.auth.currentUser?.id;
                            if (userId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('로그인에 실패했습니다.')),
                              );
                              return;
                            }

                            final hasNickname = await _hasNickname(userId);

                            if (hasNickname) {
                              Navigator.pushReplacementNamed(context, '/home');
                            } else {
                              Navigator.pushReplacementNamed(context, '/nickname_setup');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Kakao 로그인 실패: $e')),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/kakao_icon.png', height: 24),
                            const SizedBox(width: 12),
                            const Text('Kakao 로그인'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 이메일 로그인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text('이메일로 로그인'),
                      ),
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
}
