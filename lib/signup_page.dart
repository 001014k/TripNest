import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isPasswordVisible = false;

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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Firebase에 사용자 데이터 저장
        DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);
        await userDocRef.set({
          'email': email,
          'createdAt': Timestamp.now(),
        });

        final userMarkersCollection = userDocRef.collection('user_markers');
        await userMarkersCollection.doc('init').set({
          'initialized': true,
        });

        // 회원가입 성공 시 로그인 페이지로 이동
        Navigator.pushReplacementNamed(context, '/login');
      }
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
                prefixIcon: const Icon(Icons.email_outlined,color: Colors.white,),
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              style: TextStyle(color: Colors.white),
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: '비밀번호',
                prefixIcon: const Icon(Icons.lock_outline_rounded,color: Colors.white,),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white,),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              style: TextStyle(color: Colors.white),
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: '비밀번호 재입력',
                prefixIcon: const Icon(Icons.lock_outline_rounded,color: Colors.white,),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility,
                  color: Colors.white,),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible =!_isPasswordVisible;
                    });
                  },
                ),
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () => _signup(context),
              child: Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
