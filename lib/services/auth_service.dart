import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 자동 로그인 정보 저장
  Future<void> saveUserCredentials(String email, String password, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      prefs.setBool('remember_me', true);
      prefs.setString('email', email);
      prefs.setString('password', password);
    } else {
      prefs.remove('remember_me');
      prefs.remove('email');
      prefs.remove('password');
    }
  }

  /// 자동 로그인 정보 로드
  Future<Map<String, dynamic>> loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'rememberMe': prefs.getBool('remember_me') ?? false,
      'email': prefs.getString('email') ?? '',
      'password': prefs.getString('password') ?? '',
    };
  }

  /// Supabase 로그인
  Future<User?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      throw "로그인 실패: ${e.toString()}";
    }
  }

  /// 비밀번호 재설정 이메일 보내기
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      throw "이메일을 입력해주세요.";
    }

    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw "비밀번호 재설정 이메일 전송 실패: ${e.toString()}";
    }
  }

  /// 회원가입
  Future<String?> signUp(String email, String password, String confirmPassword) async {
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return "모든 필드를 입력해주세요.";
    }
    if (password != confirmPassword) {
      return "비밀번호가 일치하지 않습니다.";
    }

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Supabase의 profiles 테이블에 추가
        await _supabase.from('profiles').insert({
          'id': user.id,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });

        // 마커 초기화용 필드 추가 (선택)
        await _supabase.from('user_markers').insert({
          'user_id': user.id,
          'initialized': true,
          'title': 'init',
          'lat': 0.0,
          'lng': 0.0,
        });

        return null;
      }

      return "회원가입 실패: 사용자 생성 실패";
    } catch (e) {
      return "회원가입 실패: ${e.toString()}";
    }
  }
}
