import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../viewmodels/login_viewmodel.dart';


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

    final session = supa.Supabase.instance.client.auth.currentSession;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      });
    }

    _authSubscription = supa.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == supa.AuthChangeEvent.signedIn && session != null) {
        debugPrint('✅ 구글 로그인 성공! 홈으로 이동');
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        });
      }
    });
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
                            // onAuthStateChange 리스너는 initState에 이미 있음
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
                          backgroundColor: const Color(0xFFFFE812), // 카카오톡 노랑
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          await viewModel.signInWithKakao();
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

                    // 이메일 로그인으로 이동 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('이메일로 로그인'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
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
