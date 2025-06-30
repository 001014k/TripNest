import 'package:flutter/material.dart';
import '../services/user_service.dart';

class NicknameSetupViewModel extends ChangeNotifier {
  final UserService _userService;
  final String userId;  // final로 선언하고 생성자에서 받음

  NicknameSetupViewModel({required this.userId, UserService? userService})
      : _userService = userService ?? UserService();

  String _nickname = '';
  String get nickname => _nickname;

  set nickname(String value) {
    _nickname = value;
    _errorMessage = null; // 닉네임 바뀌면 오류 메시지 초기화
    notifyListeners();
  }

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// 닉네임 중복 체크
  Future<void> checkNicknameAvailability() async {
    if (_nickname.trim().isEmpty) {
      _errorMessage = "닉네임을 입력하세요.";
      notifyListeners();
      return;
    }
    _isChecking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final available = await _userService.isNicknameAvailable(_nickname.trim());
      _isAvailable = available;
      if (!available) {
        _errorMessage = "이미 사용중인 닉네임입니다.";
      }
    } catch (e) {
      _errorMessage = "닉네임 확인 중 오류가 발생했습니다.";
    }

    _isChecking = false;
    notifyListeners();
  }

  /// 닉네임 저장
  Future<bool> saveNickname() async {
    if (userId == null) {
      _errorMessage = "사용자 정보가 없습니다.";
      notifyListeners();
      return false;
    }

    if (_nickname.trim().isEmpty) {
      _errorMessage = "닉네임을 입력하세요.";
      notifyListeners();
      return false;
    }
    if (!_isAvailable) {
      _errorMessage = "사용할 수 없는 닉네임입니다.";
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userService.updateNickname(userId!, _nickname.trim());
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "닉네임 저장 실패: $e";
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
