import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _errorMessage = "로그인 상태가 아닙니다.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userId = user.id;  // UUID 추출
      final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;

      // 1. 소셜 연결 완전 해제 (카카오/구글 unlink/revoke – 그대로 유지)
      final identities = user.identities ?? [];
      for (final identity in identities) {
        final provider = identity.provider;
        if (provider == 'kakao' && accessToken != null) {
          await _unlinkKakao(accessToken);
        }
        if (provider == 'google' && accessToken != null) {
          await _revokeGoogleToken(accessToken);
        }
      }

      // 2. RPC 직접 호출 → profiles 논리적 + 나머지 물리적 + auth.users hard delete
      // (클라이언트에서 직접 처리 – Edge Function 불필요)
      final response = await Supabase.instance.client.rpc(
        'delete_user_data',
        params: {'p_user_id': userId},
      );

      print("RPC response: $response");  // 디버깅 로그 추가

      if (response['success'] != true) {
        throw Exception('탈퇴 실패: ${response['message'] ?? '알 수 없는 오류'}');
      }

      // 3. 로그아웃 (auth.users 이미 삭제됐으므로 세션 무효화)
      await Supabase.instance.client.auth.signOut();

      print("진짜 완전 탈퇴 성공! 모든 데이터 삭제 완료");
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = "탈퇴 처리 중 오류가 발생했습니다: $e";
      print("탈퇴 실패: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _unlinkKakao(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://kapi.kakao.com/v1/user/unlink'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        print("카카오 앱 완전 연동 해제 성공!");
      }
    } catch (e) {
      print("카카오 unlink 실패: $e");
    }
  }

  Future<void> _revokeGoogleToken(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://accounts.google.com/o/oauth2/revoke?token=$accessToken'),
      );
      if (response.statusCode == 200) {
        print("구글 앱 완전 연동 해제 성공!");
      }
    } catch (e) {
      print("구글 revoke 실패: $e");
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
