import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginViewModel()..loadUserPreferences(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(title: Text('FlutterTrip')),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.black,
                    backgroundImage: AssetImage('assets/kmj.png'),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: '이메일',
                      hintText: '이메일을 입력하세요',
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.white),
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    onChanged: viewModel.setEmail,
                    controller: TextEditingController(text: viewModel.email),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    style: TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      hintText: '비밀번호를 입력하세요',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.white),
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    onChanged: viewModel.setPassword,
                    controller: TextEditingController(text: viewModel.password),
                  ),
                  SizedBox(height: 20),
                  CheckboxListTile(
                    checkColor: Colors.white,
                    value: viewModel.rememberMe,
                    onChanged: (value) => viewModel.setRememberMe(value ?? false),
                    title: Text('Remeber Me', style: TextStyle(color: Colors.white)),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(
                    width: 400,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        String? errorMessage = await viewModel.login();
                        if (errorMessage == null) {
                          // 로그인 성공
                          String route = viewModel.email == 'hm4854@gmail.com' ? '/user_list' : '/home';
                          Navigator.pushReplacementNamed(context, route);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage)),
                          );
                        }
                      },
                      child: viewModel.isLoading
                          ? CircularProgressIndicator(color: Colors.black)
                          : Text('로그인'),
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: Text('회원가입'),
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                      child: Text('비밀번호 찾기'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
