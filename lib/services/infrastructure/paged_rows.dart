import 'package:supabase_flutter/supabase_flutter.dart';

/// 화면에서 전체 장소가 필요한 경우에도 한 요청의 크기와 URL 길이를 제한합니다.
Future<List<Map<String, dynamic>>> loadRowsById(
  PostgrestFilterBuilder<List<Map<String, dynamic>>> Function() query, {
  bool Function()? isCancelled,
}) async {
  final rows = <Map<String, dynamic>>[];
  String? cursor;
  while (true) {
    if (isCancelled?.call() == true) return [];
    var pageQuery = query();
    if (cursor != null) pageQuery = pageQuery.gt('id', cursor);
    final page = await pageQuery.order('id').limit(200);
    if (isCancelled?.call() == true) return [];
    rows.addAll(page);
    if (page.length < 200) return rows;
    cursor = page.last['id'].toString();
  }
}
