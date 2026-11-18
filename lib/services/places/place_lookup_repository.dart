import 'dart:convert';
import 'package:http/http.dart' as http;
import '../infrastructure/server_api_client.dart';

/// 앱 전체에서 장소 식별자 캐시와 진행 중인 요청을 공유합니다.
/// 완료된 장소 정보는 보관하지 않고, 캐시 제한 예외인 Place ID만 유지합니다.
class PlaceLookupRepository {
  PlaceLookupRepository({http.Client? client, this.apiKey = 'server-managed'})
      : _client = client ?? ServerApiClient();
  static final shared = PlaceLookupRepository();
  final http.Client _client;
  final String apiKey;
  final _ids = <String, String>{};
  final _pending = <String, Future<Map<String, dynamic>?>>{};
  final calls = <String, int>{'search': 0, 'details': 0};

  static String queryKey(String query) => query
      .trim()
      .toLowerCase()
      .replaceAll(',', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  void rememberId(String query, String id) {
    final key = queryKey(query);
    if (key.isEmpty || id.isEmpty) return;
    if (_ids.length >= 256 && !_ids.containsKey(key)) {
      _ids.remove(_ids.keys.first);
    }
    _ids[key] = id;
  }

  Future<Map<String, dynamic>?> _share(
      String key, Future<Map<String, dynamic>?> Function() load) {
    final existing = _pending[key];
    if (existing != null) return existing;
    late final Future<Map<String, dynamic>?> future;
    future = Future<Map<String, dynamic>?>.sync(load).whenComplete(() {
      if (identical(_pending[key], future)) _pending.remove(key);
    });
    _pending[key] = future;
    return future;
  }

  Future<Map<String, dynamic>?> find(String query) {
    final key = queryKey(query);
    if (key.isEmpty) return Future.value(null);
    return _share('search:$key', () async {
      calls['search'] = calls['search']! + 1;
      final response = await _client
          .post(
            Uri.https('places.googleapis.com', '/v1/places:searchText'),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': apiKey,
              'X-Goog-FieldMask':
                  'places.id,places.displayName,places.formattedAddress,places.photos'
            },
            body: jsonEncode({
              'textQuery': query,
              'maxResultCount': 5,
              'languageCode': 'ko',
              'regionCode': 'KR'
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw PlacesLookupException(response.statusCode);
      }
      final places = (jsonDecode(response.body)['places'] as List?) ?? [];
      if (places.isEmpty) return null;
      // 입력한 이름·주소의 단어와 가장 많이 일치하는 후보를 우선합니다.
      final words = key.split(' ');
      Map<String, dynamic>? best;
      var bestScore = -1;
      for (final raw in places.whereType<Map>()) {
        final place = Map<String, dynamic>.from(raw);
        final text = queryKey(
            '${place['displayName']?['text'] ?? ''} ${place['formattedAddress'] ?? ''}');
        final score = words.where(text.contains).length;
        if (score > bestScore) {
          best = place;
          bestScore = score;
        }
      }
      final id = best?['id'];
      if (id is String) rememberId(query, id);
      return best;
    });
  }

  Future<Map<String, dynamic>?> lookup(String query, String fields) async {
    final key = queryKey(query);
    if (key.isEmpty) return null;
    var id = _ids[key];
    Map<String, dynamic>? found;
    if (id == null) {
      found = await find(query);
      id = found?['id'] as String?;
      // 최초 사진 검색 결과에 요청한 메타데이터가 이미 포함되어 있습니다.
      if (fields == photoFields) return found;
    }
    if (id == null) return null;
    // 전체 상세 응답에는 사진도 포함되므로 진행 중인 요청이 있으면 공유합니다.
    if (fields == photoFields) {
      final full = _pending['details:$id:$detailFields:ko'];
      if (full != null) return full;
    }
    try {
      return await _details(id, fields);
    } on PlacesLookupException catch (error) {
      if (error.statusCode != 404) rethrow;
      // 더 이상 유효하지 않은 ID는 한 번만 다시 검색하며 무한 재시도하지 않습니다.
      _ids.remove(key);
      found = await find(query);
      final replacement = found?['id'] as String?;
      if (fields == photoFields) return found;
      if (replacement == null || replacement == id) return null;
      return _details(replacement, fields);
    }
  }

  static const photoFields = 'id,photos';
  static const detailFields =
      'id,photos,currentOpeningHours,regularOpeningHours,rating,userRatingCount,internationalPhoneNumber,nationalPhoneNumber,formattedAddress,googleMapsUri';

  Future<Map<String, dynamic>?> _details(String id, String fields) =>
      _share('details:$id:$fields:ko', () async {
        calls['details'] = calls['details']! + 1;
        final response = await _client
            .get(
              Uri.https('places.googleapis.com', '/v1/places/$id',
                  {'fields': fields, 'languageCode': 'ko', 'key': apiKey}),
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          throw PlacesLookupException(response.statusCode);
        }
        return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      });

  static List<String> photoUrls(Map<String, dynamic>? place,
          {int width = 600}) =>
      ((place?['photos'] as List?) ?? [])
          .whereType<Map>()
          .map((photo) => photo['name'])
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .toSet()
          .take(5)
          .map((name) =>
              'https://places.googleapis.com/v1/$name/media?key=server-managed&maxWidthPx=$width')
          .toList();
}

class PlacesLookupException implements Exception {
  const PlacesLookupException(this.statusCode);
  final int statusCode;
  @override
  String toString() => '장소 정보 조회 실패 (HTTP $statusCode)';
}
