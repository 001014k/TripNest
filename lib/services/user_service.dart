import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/userprofile_model.dart';

final supabase = Supabase.instance.client;

// UserService: 사용자 통계 조회
class UserService {
  /// 사용자 통계 정보 반환 (user_markers, lists, bookmarks)
  Future<Map<String, int>> getUserStats(String userId) async {
    final markers = await supabase
        .from('user_markers')
        .select('id')
        .eq('user_id', userId);
    final lists = await supabase
        .from('lists')
        .select('id')
        .eq('user_id', userId);
    final bookmarks = await supabase
        .from('bookmarks')
        .select('id')
        .eq('user_id', userId);

    return {
      'markers': (markers as List).length,
      'lists': (lists as List).length,
      'bookmarks': (bookmarks as List).length,
    };
  }

  /// 현재 사용자 리스트 가져오기
  Future<List<Map<String, dynamic>>> getUserLists() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('lists')
        .select()
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(response);
  }

  /// 닉네임 설정 여부 확인
  Future<bool> hasNickname(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('nickname')
        .eq('id', userId)
        .maybeSingle();

    final nickname = response != null ? response['nickname'] : null;
    return nickname != null && nickname.toString().trim().isNotEmpty;
  }

  /// 닉네임으로 사용자 검색
  Future<List<UserModel>> searchUsersByNickname(String nickname) async {
    final response = await supabase
        .from('profiles')
        .select()
        .ilike('nickname', '%$nickname%');

    return (response as List).map((item) => UserModel.fromMap(item)).toList();
  }

  Future<UserProfile> getProfileById(String userId) async {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromMap(response);
  }

  /// 닉네임 중복 여부 체크
  Future<bool> isNicknameAvailable(String nickname) async {
    final response = await supabase
        .from('profiles')
        .select('nickname')
        .eq('nickname', nickname.trim())  // trim() 추가 권장
        .limit(1);

    // debug print 추가
    print('닉네임 중복 검사 결과: $response');

    return (response as List).isEmpty;  // 결과가 비어있으면 사용 가능(true)
  }


  /// 닉네임 업데이트
  Future<void> updateNickname(String userId, String nickname) async {
    final existing = await supabase
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing == null) {
      // insert
      await supabase.from('profiles').insert({
        'id': userId,
        'email': supabase.auth.currentUser?.email,
        'created_at': DateTime.now().toIso8601String(),
        'nickname': nickname.trim(),
      });
    } else {
      // update
      await supabase
          .from('profiles')
          .update({'nickname': nickname.trim()})
          .eq('id', userId);
    }
  }
}