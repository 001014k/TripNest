import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_list_page.dart'; // 사용자 리스트 페이지

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      //firebaseauth를 이용해 로그인을 처리하는 기능
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // 어드민 계정 로그인 확인
        if (email == 'hm4854@gmail.com') {
          Navigator.pushReplacementNamed(context, '/user_list');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('FlutterTrip'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/kmj.png'),
            ),
            SizedBox(height: 20),
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
            SizedBox(
              width: 400,
              child: ElevatedButton(
                onPressed: () => _login(context),
                child: Text('로그인'),
              ),
            ),
            SizedBox(
              width: 400,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text('회원가입'),
              ),
            ),
            SizedBox(
              width: 400,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot_password');
                },
                child: Text('비밀번호 찾기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
