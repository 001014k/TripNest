import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shared_link_model.dart';

class SharedLinkService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> saveSharedLink(String url) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다");

    final model = SharedLinkModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.id,
      url: url,
      createdAt: DateTime.now(),
    );

    await _client.from('shared_links').insert(model.toMap());
  }
}
