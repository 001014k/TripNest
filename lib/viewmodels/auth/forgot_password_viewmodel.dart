import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String?> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) return "이메일을 입력해주세요.";

    _isLoading = true;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      return null; // 성공 시 null 반환
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
