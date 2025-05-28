import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 자동 로그인 기능을 위한 SharedPreferences 저장/로드
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

  Future<Map<String, dynamic>> loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'rememberMe': prefs.getBool('remember_me') ?? false,
      'email': prefs.getString('email') ?? '',
      'password': prefs.getString('password') ?? '',
    };
  }

  /// Firebase 로그인 처리
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      throw e.toString();
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      throw "이메일을 입력해주세요.";
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw "비밀번호 재설정 이메일 전송 실패: ${e.toString()}";
    }
  }

  /// 회원가입 처리 및 Firestore 저장
  Future<String?> signUp(String email, String password, String confirmPassword) async {
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return "모든 필드를 입력해주세요.";
    }
    if (password != confirmPassword) {
      return "비밀번호가 일치하지 않습니다.";
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);
        await userDocRef.set({
          'email': email,
          'createdAt': Timestamp.now(),
        });

        // 사용자의 마커 정보 초기화
        await userDocRef.collection('user_markers').doc('init').set({
          'initialized': true,
        });

        return null; // 성공 시 에러 메시지 없음
      }
      return "회원가입 중 문제가 발생했습니다.";
    } catch (e) {
      return "회원가입 실패: ${e.toString()}";
    }
  }
}
