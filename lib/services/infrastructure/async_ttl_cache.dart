/// 크기가 제한된 조회 캐시입니다. 동시 요청을 합치며 실패는 캐시하지 않습니다.
class AsyncTtlCache<K, V> {
  AsyncTtlCache(
      {required this.ttl,
      this.emptyTtl = const Duration(seconds: 30),
      this.isEmpty,
      DateTime Function()? clock,
      this.maxEntries = 128})
      : assert(maxEntries > 0),
        _clock = clock ?? DateTime.now;
  final Duration ttl, emptyTtl;
  final bool Function(V)? isEmpty;
  final DateTime Function() _clock;
  final int maxEntries;
  final _values = <K, (DateTime, V)>{};
  final _pending = <K, Future<V>>{};

  Future<V> get(K key, Future<V> Function() load) {
    final cached = _values[key];
    if (cached != null && _clock().isBefore(cached.$1)) {
      return Future.value(cached.$2);
    }
    _values.remove(key);
    final pending = _pending[key];
    if (pending != null) return pending;
    late final Future<V> request;
    request = Future<V>.sync(load).then((value) {
      if (identical(_pending[key], request)) {
        _pending.remove(key);
        if (_values.length >= maxEntries) _values.remove(_values.keys.first);
        _values[key] = (
          _clock().add(isEmpty?.call(value) == true ? emptyTtl : ttl),
          value
        );
      }
      return value;
    }, onError: (Object error, StackTrace stack) {
      if (identical(_pending[key], request)) _pending.remove(key);
      Error.throwWithStackTrace(error, stack);
    });
    _pending[key] = request;
    return request;
  }

  void invalidate(K key) {
    _values.remove(key);
    _pending.remove(key);
  }

  void clear() {
    _values.clear();
    _pending.clear();
  }
}
