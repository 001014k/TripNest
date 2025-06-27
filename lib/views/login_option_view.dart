import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginOptionView extends StatelessWidget {
  const LoginOptionView({super.key});

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
                          Navigator.pushReplacementNamed(context, '/home');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Google 로그인 실패')),
                          );
                        }
                      },
                      child: Image.asset(
                        'assets/google_signin_button.png',
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
                          Navigator.pushNamed(context, '/login'); // 기존 로그인 페이지
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
