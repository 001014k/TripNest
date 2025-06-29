import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
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
      final res = await supa.Supabase.instance.client.auth.signInWithPassword(
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

  /// Supabase Google OAuth 로그인 (웹 리디렉션 방식)
  Future<void> signInWithGoogle() async {
    try {
      await supa.Supabase.instance.client.auth.signInWithOAuth(
        supa.OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
      // 로그인 결과 확인은 호출 후 앱 복귀 시점에서 해야 함
    } catch (e) {
      debugPrint('구글 로그인 실패: $e');
      rethrow;
    }
  }

  Future<void> signInWithKakao() async {
    try {
      await supa.Supabase.instance.client.auth.signInWithOAuth(
        supa.OAuthProvider.kakao, // ✅ 핵심 변경 포인트
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      print('카카오 로그인 실패: $e');
      rethrow;
    }
  }
}
