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
  @override
  void initState() {
    super.initState();

    // 1. 기존 로그인 세션이 있는 경우 → 바로 홈으로 이동
    final session = supa.Supabase.instance.client.auth.currentSession;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }

    // 2. 이후 로그인 시도 성공 시 리디렉션
    supa.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == supa.AuthChangeEvent.signedIn && session != null) {
        debugPrint('✅ 구글 로그인 성공! 홈으로 이동');
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
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
                    // Google 로그인 이미지 버튼
                    GestureDetector(
                      onTap: () async {
                        try {
                          await viewModel.signInWithGoogle();

                          // 콜백에서 자동 로그인 되면 onAuthStateChange에서 감지됨
                          supa.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
                            final event = data.event;
                            final session = data.session;

                            if (event == supa.AuthChangeEvent.signedIn && session != null) {
                              debugPrint('✅ 구글 로그인 성공 - 홈으로 이동');
                              Navigator.pushReplacementNamed(context, '/home');
                            } else {
                              debugPrint('❌ 로그인 실패 또는 취소');
                            }
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Google 로그인 실패: $e')),
                          );
                        }
                      },
                      child: Image.asset(
                        'assets/google_signin_button.png',
                        width: 260,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Kakao 로그인 이미지 버튼
                    GestureDetector(
                      onTap: () async {
                        try {
                          await viewModel.signInWithKakao();

                          // 콜백에서 자동 로그인 되면 onAuthStateChange에서 감지됨
                          supa.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
                            final event = data.event;
                            final session = data.session;

                            if (event == supa.AuthChangeEvent.signedIn && session != null) {
                              debugPrint('✅ 카카오 로그인 성공 - 홈으로 이동');
                              Navigator.pushReplacementNamed(context, '/home');
                            } else {
                              debugPrint('❌ 카카오 로그인 실패 또는 취소');
                            }
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Kakao 로그인 실패: $e')),
                          );
                        }
                      },
                      child: Image.asset(
                        'assets/kakao_icon.png',
                        width: 260,
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
