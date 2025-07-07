import 'package:flutter/material.dart';
import '../services/user_service.dart';

class NicknameDialogViewModel extends ChangeNotifier {
  final UserService _userService;
  final String userId;

  NicknameDialogViewModel({required this.userId, UserService? userService})
      : _userService = userService ?? UserService();

  String _nickname = '';
  String get nickname => _nickname;
  set nickname(String val) {
    _nickname = val;
    _error = null;
    _nicknameStatusMessage = null;
    notifyListeners();
  }

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  bool _isNicknameAvailable = false;
  bool get isNicknameAvailable => _isNicknameAvailable;

  String? _nicknameStatusMessage;
  String? get nicknameStatusMessage => _nicknameStatusMessage;

  Future<void> checkNicknameAvailability() async {
    if (_nickname.trim().isEmpty) {
      _error = '닉네임을 입력해주세요.';
      _nicknameStatusMessage = null;
      notifyListeners();
      return;
    }

    _isChecking = true;
    _error = null;
    _nicknameStatusMessage = null;
    notifyListeners();

    try {
      final available = await _userService.isNicknameAvailable(_nickname.trim());
      _isNicknameAvailable = available;
      _nicknameStatusMessage = available ? '사용 가능한 닉네임입니다.' : '이미 사용 중인 닉네임입니다.';
    } catch (e) {
      _error = '닉네임 확인 중 오류가 발생했습니다.';
      _nicknameStatusMessage = null;
      _isNicknameAvailable = false;
    }

    _isChecking = false;
    notifyListeners();
  }

  Future<bool> saveNickname() async {
    if (_nickname.trim().isEmpty) {
      _error = '닉네임을 입력해주세요.';
      notifyListeners();
      return false;
    }

    if (!_isNicknameAvailable) {
      _error = '이미 사용 중인 닉네임입니다.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.updateNickname(userId, _nickname.trim());
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '저장 실패: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
