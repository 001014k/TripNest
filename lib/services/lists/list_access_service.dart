import 'package:supabase_flutter/supabase_flutter.dart';

class ListAccessService {
  static Future<String?> role(String listId) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;
    final list =
        await client.from('lists').select('user_id').eq('id', listId).single();
    if (list['user_id'] == user.id) return 'owner';
    final member = await client
        .from('list_members')
        .select('role')
        .eq('list_id', listId)
        .eq('user_id', user.id)
        .maybeSingle();
    return member?['role'] as String?;
  }

  static Future<bool> canEditPlaces(String listId) async =>
      const ['owner', 'editor'].contains(await role(listId));
}
