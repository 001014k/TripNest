import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
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

  // 구글 로그인
  Future<void> signInWithGoogle() async {
    try {
      // 현재 세션 로그아웃
      await supa.Supabase.instance.client.auth.signOut();

      final response = await supa.Supabase.instance.client.auth.getOAuthSignInUrl(
        provider: supa.OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );

      final uri = Uri.parse(response.url);
      debugPrint('Google OAuth URL: $uri');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('외부 브라우저 열기 실패');
        throw 'Could not launch $uri';
      }
    } catch (e) {
      debugPrint('구글 로그인 실패: $e');
      rethrow;
    }
  }

  // 카카오톡 로그인
  Future<void> signInWithKakao() async {
    try {
      // 현재 세션 로그아웃
      await supa.Supabase.instance.client.auth.signOut();

      final response = await supa.Supabase.instance.client.auth.getOAuthSignInUrl(
        provider: supa.OAuthProvider.kakao,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
      final uri = Uri.parse(response.url);

      print('Kakao OAuth URL: $uri');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('카카오 로그인 실패: $e');
      rethrow;
    }
  }
}
