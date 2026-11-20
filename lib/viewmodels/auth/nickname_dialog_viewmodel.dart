import 'package:flutter/material.dart';
import '../../services/profile/user_service.dart';

class NicknameDialogViewModel extends ChangeNotifier {
  final UserService _userService;
  final String userId;

  NicknameDialogViewModel({required this.userId, UserService? userService})
      : _userService = userService ?? UserService();

  bool _disposed = false;
  int _revision = 0;
  String? _checkedNickname;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }

  String _nickname = '';
  String get nickname => _nickname;
  set nickname(String val) {
    _nickname = val;
    _revision++;
    _isChecking = false;
    _isNicknameAvailable = false;
    _checkedNickname = null;
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

    final revision = ++_revision;
    final checked = _nickname.trim();
    _isChecking = true;
    _error = null;
    _nicknameStatusMessage = null;
    notifyListeners();

    try {
      final available = await _userService.isNicknameAvailable(checked);
      if (_disposed || revision != _revision) return;
      _checkedNickname = checked;
      _isNicknameAvailable = available;
      _nicknameStatusMessage =
          available ? '사용 가능한 닉네임입니다.' : '이미 사용 중인 닉네임입니다.';
    } catch (e) {
      if (_disposed || revision != _revision) return;
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

    if (_isSaving ||
        _isChecking ||
        !_isNicknameAvailable ||
        _checkedNickname != _nickname.trim()) {
      _error = '현재 닉네임의 중복 확인을 완료해주세요.';
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
