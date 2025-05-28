import 'package:flutter/material.dart';
import '../services/user_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  Map<String, int>? _stats;
  Map<String, int>? get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 사용자 통계 불러오기
  Future<void> fetchUserStats(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _userService.getUserStats(userId);
    } catch (e) {
      _errorMessage = "사용자 데이터를 불러오는 중 오류 발생";
    }

    _isLoading = false;
    notifyListeners();
  }
}
