import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String?> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) return "이메일을 입력해주세요.";

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      return null; // 성공하면 null 반환
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
