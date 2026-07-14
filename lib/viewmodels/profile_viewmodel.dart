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

      // 소셜 연결 해제
      final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
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

      // Edge Function 호출
      final response = await Supabase.instance.client.functions.invoke(
        'delete-account',
        body: {},
        headers: {
          'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken ?? ''}',
        },
      );

      print("Edge Function Status: ${response.status}");
      print("Edge Function Response Data: ${response.data}");
      print("Response Data Type: ${response.data.runtimeType}");

      final data = response.data;

      // ==================== 개선된 체크 로직 ====================
      bool isSuccess = false;

      if (response.status == 200) {
        if (data is Map) {
          isSuccess = data['success'] == true || data['success'] == 'true';
        } else if (data is String) {
          // JSON이 String으로 올 경우 대비
          isSuccess = data.contains('"success":true');
        }
      }
      // ====================================================

      if (isSuccess) {
        await Supabase.instance.client.auth.signOut();
        print("회원탈퇴 성공!");
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorMsg = (data is Map) ? (data['error'] ?? '알 수 없는 오류') : '탈퇴 처리 실패';
        throw Exception(errorMsg);
      }

    } catch (e) {
      print("탈퇴 실패 상세: $e");
      _errorMessage = "탈퇴 처리 중 오류가 발생했습니다. 다시 시도해주세요.";
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
