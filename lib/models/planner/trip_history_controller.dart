import 'package:flutter/foundation.dart';

typedef TripRecord = Map<String, dynamic>;

class TripHistoryQuery {
  const TripHistoryQuery({this.before, this.search = '', this.since});
  final TripRecord? before;
  final String search;
  final DateTime? since;
}

typedef TripPageLoader = Future<List<TripRecord>> Function(
    TripHistoryQuery query);

/// 플래너가 열려 있는 동안 요약 목록과 탐색 위치만 유지합니다.
class TripHistoryController extends ChangeNotifier {
  TripHistoryController({required this.loadPage, required this.deleteRecord});
  final TripPageLoader loadPage;
  final Future<void> Function(Object id) deleteRecord;
  final records = <TripRecord>[];
  final _deleted = <Object>{};
  TripRecord? _cursor;
  String search = '';
  DateTime? since;
  double scrollOffset = 0;
  bool loading = false, failed = false, hasMore = true, initialized = false;
  bool _disposed = false;
  int _generation = 0;

  Future<void> refresh({String? search, DateTime? since}) async {
    _generation++;
    this.search = search ?? this.search;
    this.since = since;
    records.clear();
    _cursor = null;
    scrollOffset = 0;
    loading = false;
    hasMore = true;
    initialized = false;
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_disposed || loading || !hasMore) return;
    final generation = _generation;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final page = await loadPage(
          TripHistoryQuery(before: _cursor, search: search, since: since));
      if (_disposed || generation != _generation) return;
      final ids = records.map((r) => r['id']).toSet();
      for (final record in page) {
        if (!_deleted.contains(record['id']) && ids.add(record['id'])) {
          records.add(record);
        }
      }
      // 삭제나 중복 제거 후의 목록 길이가 아닌 서버의 마지막 행을 사용합니다.
      if (page.isNotEmpty) _cursor = page.last;
      hasMore = page.length == 20;
      initialized = true;
    } catch (_) {
      if (!_disposed && generation == _generation) failed = true;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> remove(Object id) async {
    await deleteRecord(id);
    if (_disposed) return;
    _deleted.add(id);
    records.removeWhere((record) => record['id'] == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
