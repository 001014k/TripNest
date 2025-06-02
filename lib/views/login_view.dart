import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<LoginViewModel>();
      _emailController.text = viewModel.email;
      _passwordController.text = viewModel.password;

      // 컨트롤러 텍스트 변경 시 뷰모델에 반영
      _emailController.addListener(() {
        viewModel.setEmail(_emailController.text);
      });
      _passwordController.addListener(() {
        viewModel.setPassword(_passwordController.text);
      });
    });
  }

  @override
  void initstate() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginViewModel()..loadUserPreferences(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, child) {

          // 텍스트필드 값과 viewmodel 상태 동기화
          _emailController.text = viewModel.email;
          _passwordController.text = viewModel.password;

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
                    controller: _emailController,
                    onChanged: viewModel.setEmail,
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
                    controller: _passwordController,
                    onChanged: viewModel.setPassword,
                    //obscureText: true,
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
