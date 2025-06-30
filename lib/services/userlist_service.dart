import 'package:fluttertrip/services/user_service.dart';

// UserListService: 사용자 리스트 조회
class UserListService {
  Future<List<Map<String, dynamic>>> fetchUserLists(String userId) async {
    final response = await supabase
        .from('lists')
        .select()
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }
}