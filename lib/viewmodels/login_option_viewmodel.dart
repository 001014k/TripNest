import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

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

  /// 이메일/비밀번호 로그인
  Future<String?> login() async {
    if (_email.isEmpty || _password.isEmpty) {
      return "이메일과 비밀번호를 입력하세요.";
    }

    _isLoading = true;
    notifyListeners();

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _email,
        password: _password,
      );

      if (res.user != null) {
        await _authService.saveUserCredentials(_email, _password, _rememberMe);
        return null;
      } else {
        return "로그인 실패";
      }
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 저장된 로그인 정보 불러오기
  Future<void> loadUserPreferences() async {
    final data = await _authService.loadUserCredentials();
    _rememberMe = data['rememberMe'];
    _email = data['email'];
    _password = data['password'];
    notifyListeners();
  }

  // 구글 로그인
  Future<void> signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google, // ✅ 여기 수정
        redirectTo: 'io.supabase.flutter://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication, // 브라우저로 안전하게 열기
      );
    } catch (e) {
      debugPrint('구글 로그인 실패: $e');
      rethrow;
    }
  }


  // 카카오톡 로그인
  Future<void> signInWithKakao() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.kakao, // ✅ 여기 수정!
        redirectTo: 'io.supabase.flutter://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('카카오 로그인 실패: $e');
      rethrow;
    }
  }
}
