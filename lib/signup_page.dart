import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _signup(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      // 비밀번호와 비밀번호 확인이 일치하지 않으면 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      // Firebase Auth를 사용하여 회원가입 처리
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Firebase에 사용자 데이터 저장
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': Timestamp.now(),
        // 추가로 저장할 사용자 데이터
      });

      // 회원가입 성공 시 로그인 페이지로 이동
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // 회원가입 실패 시 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '패스워드',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.white),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '패스워드 재입력',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.white),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _signup(context),
              child: Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
