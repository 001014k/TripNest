import '../infrastructure/server_api_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../infrastructure/async_ttl_cache.dart';

/// 지도 UI 상태와 독립적으로 네트워크 검색과 결과 중복 제거를 처리합니다.
class MapSearchService {
  MapSearchService(
      {http.Client? client,
      String? apiKey,
      this.timeout = const Duration(seconds: 12),
      DateTime Function()? clock})
      : _client = client ?? ServerApiClient(),
        _apiKey = apiKey ?? 'server-managed',
        _cache = AsyncTtlCache(
            ttl: const Duration(minutes: 5),
            isEmpty: (List<Map<String, dynamic>> value) => value.isEmpty,
            clock: clock);
  final http.Client _client;
  final String _apiKey;
  final Duration timeout;
  final AsyncTtlCache<String, List<Map<String, dynamic>>> _cache;

  Future<List<Map<String, dynamic>>> search(
      String query, double lat, double lng) {
    query = query.trim();
    if (query.isEmpty) return Future.value([]);
    final key =
        '${query.toLowerCase()}|${lat.toStringAsFixed(4)}|${lng.toStringAsFixed(4)}';
    return _cache.get(key, () async {
      final response = await _client
          .post(
            Uri.https('places.googleapis.com', '/v1/places:searchText'),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
              'X-Goog-FieldMask':
                  'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.primaryTypeDisplayName'
            },
            body: jsonEncode({
              'textQuery': query,
              'languageCode': 'ko',
              'maxResultCount': 20,
              'rankPreference': 'DISTANCE',
              'locationBias': {
                'circle': {
                  'center': {'latitude': lat, 'longitude': lng},
                  'radius': 5000.0
                }
              }
            }),
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw StateError('장소 검색 실패 (HTTP ${response.statusCode})');
      }
      final places = (jsonDecode(response.body)['places'] as List?) ?? [];
      final unique = <String, Map<String, dynamic>>{};
      for (final raw in places) {
        final place = Map<String, dynamic>.from(raw as Map);
        final lat = (place['location']?['latitude'] as num?)?.toDouble();
        final lng = (place['location']?['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null || !lat.isFinite || !lng.isFinite) {
          continue;
        }
        unique.putIfAbsent(
            '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}', () => place);
      }
      return unique.values.take(10).toList();
    });
  }
}
