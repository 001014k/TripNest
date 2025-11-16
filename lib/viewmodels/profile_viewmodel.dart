import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    if (userId.isEmpty) {
      _errorMessage = "유효하지 않은 사용자 ID";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _userService.getUserStats(userId);

      final profile = await _userService.getProfileById(userId);
      if (profile == null) {
        _nickname = null;
        _errorMessage = "사용자 프로필을 찾을 수 없습니다.";
      } else {
        _nickname = profile.nickname;
      }
    } catch (e, st) {
      print('fetchUserStats 오류: $e');
      print(st);
      _errorMessage = "사용자 데이터를 불러오는 중 오류 발생: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. 현재 세션 확인
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        _errorMessage = "로그인 상태가 아닙니다.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Edge Function 호출 (JWT 헤더 필수!)
      final response = await Supabase.instance.client.functions.invoke(
        'delete-account', // ← 함수 이름 (tripnest → delete-account)
        headers: {
          'Authorization': 'Bearer ${session.accessToken}', // JWT 전달
        },
        // body: 생략 → 보안상 userId 직접 전달 금지
      );

      // 3. 응답 처리
      if (response.status == 200) {
        // 성공 → 로그아웃 및 완료
        await Supabase.instance.client.auth.signOut();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // 실패 → 서버에서 보낸 에러 메시지 표시
        final errorMsg = response.data?.toString() ?? '알 수 없는 오류';
        _errorMessage = "계정 삭제 실패: $errorMsg";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // 네트워크, 파싱 등 예외 처리
      _errorMessage = "오류 발생: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
}
