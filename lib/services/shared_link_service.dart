import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shared_link_model.dart';

class SharedLinkService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> saveSharedLink(String url) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다");

    try {
      final existing = await _client
          .from('shared_links')
          .select()
          .eq('user_id', user.id)
          .eq('url', url)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        print('이미 저장된 링크입니다: $url');
        return;
      }

      final data = {
        'user_id': user.id,
        'url': url,
        'created_at': DateTime.now().toIso8601String(),
      };

      final res = await _client.from('shared_links').insert(data).select();

      if (res == null || (res is List && res.isEmpty)) {
        throw Exception('링크 저장에 실패했습니다.');
      }
      print('링크 저장 성공: $url');
    } catch (e) {
      print('링크 저장 중 예외 발생: $e');
      rethrow;
    }
  }


  Future<List<SharedLinkModel>> loadSharedLinks() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다");

    final response = await _client
        .from('shared_links')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (response == null) {
      return [];
    }

    final list = (response as List)
        .map((e) => SharedLinkModel.fromMap(e))
        .toList();

    return list;
  }

  Future<void> deleteSharedLink(String id) async {
    final res = await _client.from('shared_links').delete().eq('id', id).select();

    if (res == null || (res is List && res.isEmpty)) {
      throw Exception('링크 삭제에 실패했습니다.');
    }
  }


  Future<bool> doesLinkExist(String url) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final response = await Supabase.instance.client
        .from('shared_links')
        .select('id')
        .eq('user_id', user.id)
        .eq('url', url)
        .limit(1);

    return response.isNotEmpty;
  }
}
