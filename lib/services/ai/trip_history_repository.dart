import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/planner/trip_history_controller.dart';

class TripHistoryRepository {
  TripHistoryRepository(this.client, {String? Function()? userId})
      : _userId = userId ?? (() => client.auth.currentUser?.id);
  final SupabaseClient client;
  final String? Function() _userId;

  String get _owner => _userId() ?? (throw StateError('로그인이 필요합니다.'));

  Future<List<TripRecord>> list(TripHistoryQuery request,
      {int limit = 20}) async {
    var query = client
        .from('ai_recommendations')
        .select(
            'id,title,created_at,category,preview_title:recommendation_data->0->>title,preview_address:recommendation_data->0->>address')
        .eq('user_id', _owner);
    final search = request.search.trim();
    if (search.isNotEmpty) {
      final literal = search
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_')
          .replaceAll('*', r'\*');
      query = query.ilike('title', '%$literal%');
    }
    if (request.since != null) {
      query = query.gte('created_at', request.since!.toUtc().toIso8601String());
    }
    final before = request.before;
    if (before != null) {
      // 커서 값은 서버 응답에서 가져오며 필터 구문용 따옴표로 감쌉니다.
      String quote(Object value) =>
          '"${value.toString().replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
      final date = quote(before['created_at']!);
      final id = quote(before['id']!);
      query =
          query.or('created_at.lt.$date,and(created_at.eq.$date,id.lt.$id)');
    }
    return await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
  }

  Future<TripRecord> detail(Object id) async => await client
      .from('ai_recommendations')
      .select(
          'id,title,created_at,recommendation_data,conversation,category,revision')
      .eq('user_id', _owner)
      .eq('id', id)
      .single();

  Future<void> delete(Object id) async {
    final deleted = await client
        .from('ai_recommendations')
        .delete()
        .eq('user_id', _owner)
        .eq('id', id)
        .select('id');
    if (deleted.isEmpty) throw StateError('기록을 삭제하지 못했습니다.');
  }
}
