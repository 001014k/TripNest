import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shared_link_model.dart';


class SharedLinkViewModel extends ChangeNotifier {
  final _client = Supabase.instance.client;
  String? errorMessage;

  Future<void> saveLink(String url) async {
    errorMessage = null; // 에러 메시지 초기화
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final model = SharedLinkModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.id,
      url: url,
      createdAt: DateTime.now(),
    );

    try {
      await _client.from('shared_links').insert(model.toMap());
      notifyListeners(); // 필요 시
    } catch (e) {
      errorMessage = '링크 저장 실패: $e';
      notifyListeners();
    }
  }


  Future<List<SharedLinkModel>> loadSharedLinks() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final response = await _client
        .from('shared_links')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => SharedLinkModel.fromMap(item))
        .toList();
  }

  Future<void> deleteLink(String id) async {
    await _client.from('shared_links').delete().eq('id', id);
    notifyListeners();
  }
}