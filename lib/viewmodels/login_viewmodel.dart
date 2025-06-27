import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _rememberMe = false;
  String _email = '';
  String _password = '';

  bool get isLoading => _isLoading;
  bool get rememberMe => _rememberMe;
  String get email => _email;
  String get password => _password;

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  /// 로그인 처리
  Future<String?> login() async {
    if (_email.isEmpty || _password.isEmpty) {
      return "이메일과 비밀번호를 입력하세요.";
    }

    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.login(_email, _password);
      await _authService.saveUserCredentials(_email, _password, _rememberMe);
      return user != null ? null : "로그인 실패";
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 저장된 로그인 정보 로드
  Future<void> loadUserPreferences() async {
    final data = await _authService.loadUserCredentials();
    _rememberMe = data['rememberMe'];
    _email = data['email'];
    _password = data['password'];
    notifyListeners();
  }


  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // 사용자가 취소한 경우

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('구글 로그인 실패: $e');
      rethrow;
    }
  }
}
