import 'package:flutter/material.dart';
import '../../services/auth/provider_disconnect_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/profile/user_model.dart';
import '../../services/profile/user_service.dart';

class ProfileViewModel extends ChangeNotifier {
  bool _accountDisposed = false;
  @override
  void notifyListeners() {
    if (!_accountDisposed) super.notifyListeners();
  }

  final UserService _userService;

  ProfileViewModel({UserService? userService})
      : _userService = userService ?? UserService();

  Future<bool> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, int>? _stats;
  Map<String, int>? get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _nickname; // 닉네임 필드 추가
  String? get nickname => _nickname;

  List<UserModel> _searchResults = [];
  List<UserModel> get searchResults => _searchResults;

  final Set<String> _followingIds = {};
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
      debugPrint('fetchUserStats 오류: $e');
      debugPrint(st.toString());
      _errorMessage = "사용자 데이터를 불러오는 중 오류 발생: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  String? deletionNotice;
  Future<bool> deleteAccount() async {
    if (_isLoading) return false;
    deletionNotice = null;
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

      final session = Supabase.instance.client.auth.currentSession;
      final providerToken = session?.providerToken;
      final providers =
          (user.identities ?? []).map((identity) => identity.provider).toList();

      // Edge Function 호출
      final response = await Supabase.instance.client.functions.invoke(
        'delete-account',
        body: {},
        headers: {
          'Authorization':
              'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken ?? ''}',
        },
      );

      debugPrint("Edge Function Status: ${response.status}");
      debugPrint("Edge Function Response Data: ${response.data}");
      debugPrint("Response Data Type: ${response.data.runtimeType}");

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
        // 앱 계정 삭제가 확정된 뒤 공급자 토큰만 사용합니다.
        final disconnect = ProviderDisconnectService();
        try {
          final complete = await disconnect.disconnect(
              providers: providers, providerToken: providerToken);
          if (!complete) {
            deletionNotice =
                '앱 계정은 삭제되었습니다. 외부 로그인 연결은 Google·카카오 등 해당 계정의 연결된 앱 설정에서 확인해주세요.';
          }
        } finally {
          disconnect.dispose();
        }
        try {
          await Supabase.instance.client.auth
              .signOut(scope: SignOutScope.local);
        } catch (_) {
          // 서버에서 확정된 삭제를 실패로 되돌리지 않습니다.
          deletionNotice ??= '앱 계정은 삭제되었습니다. 앱을 다시 실행해주세요.';
        }
        debugPrint("회원탈퇴 성공!");
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorMsg =
            (data is Map) ? (data['error'] ?? '알 수 없는 오류') : '탈퇴 처리 실패';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("탈퇴 실패 상세: $e");
      _errorMessage = "탈퇴 처리 중 오류가 발생했습니다. 다시 시도해주세요.";
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

  @override
  void dispose() {
    _accountDisposed = true;
    super.dispose();
  }
}
