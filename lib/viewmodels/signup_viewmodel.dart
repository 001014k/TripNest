import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String?> signUp(String email, String password, String confirmPassword) async {
    _isLoading = true;
    notifyListeners();

    String? errorMessage = await _authService.signUp(email, password, confirmPassword);

    _isLoading = false;
    notifyListeners();

    return errorMessage;
  }
}
