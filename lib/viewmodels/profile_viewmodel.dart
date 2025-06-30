import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserService _userService;

  ProfileViewModel({UserService? userService})
      : _userService = userService ?? UserService();

  Map<String, int>? _stats;
  Map<String, int>? get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _nickname;       // 닉네임 필드 추가
  String? get nickname => _nickname;

  List<UserModel> _searchResults = [];
  List<UserModel> get searchResults => _searchResults;

  Set<String> _followingIds = {};
  Set<String> get followingIds => _followingIds;

  Future<void> fetchUserStats(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _userService.getUserStats(userId);
      _followingIds = await _userService.getFollowingIds(userId);

      // 닉네임도 같이 가져오기
      final profile = await _userService.getProfileById(userId);
      _nickname = profile.nickname;
    } catch (e) {
      _errorMessage = "사용자 데이터를 불러오는 중 오류 발생";
    }

    _isLoading = false;
    notifyListeners();
  }

  // 닉네임 검색
  Future<void> searchUsers(String nickname, String currentUserId) async {
    if (nickname.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _userService.searchUsersByNickname(nickname);
      // 자기 자신은 제외
      _searchResults = results.where((u) => u.id != currentUserId).toList();
    } catch (e) {
      _errorMessage = "사용자 검색 중 오류 발생";
    }

    _isLoading = false;
    notifyListeners();
  }

  // 팔로우 하기
  Future<void> followUser(String followerId, String followingId) async {
    try {
      await _userService.followUser(followerId, followingId);
      _followingIds.add(followingId);
      notifyListeners();
    } catch (e) {
      _errorMessage = "팔로우 실패: 이미 팔로우했거나 오류 발생";
      notifyListeners();
    }
  }
}
