import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../env.dart';
import '../models/link_place_preview_model.dart';
import '../models/instagram_place_source_model.dart';
import 'package:flutter/foundation.dart';
import '../services/apify_service.dart';
import '../services/gemini_service.dart';

class LinkPlaceExtractorService {
  const LinkPlaceExtractorService();

  static final RegExp _koreanAddressPattern = RegExp(
    r'(?:서울(?:특별시|시)?|부산(?:광역시|시)?|대구(?:광역시|시)?|인천(?:광역시|시)?|광주(?:광역시|시)?|대전(?:광역시|시)?|울산(?:광역시|시)?|세종(?:특별자치시)?|경기(?:도)?|강원(?:특별자치도|도)?|충청(?:북|남)도|충북|충남|전라(?:북|남)도|전북|전남|경상(?:북|남)도|경북|경남|제주(?:특별자치도)?)[가-힣0-9\s-]{0,80}(?:(?:로\s*\d+번길|[가-힣]+길|[가-힣]+로)\s*\d+(?:-\d+)?|(?:동|읍|면|리)\s*\d*)(?:\s*(?:지하\s*\d+층|\d+층|\d+호))?',
  );

  static final RegExp _streetAddressPattern = RegExp(
    r'\b(?:[가-힣]+로\s*\d+번길|[가-힣]+길|[가-힣]+로)\s*\d+(?:-\d+)?(?:\s*(?:지하\s*\d+층|\d+층|\d+호))?',
  );

  static final RegExp _unitPattern = RegExp(
    r'(?:지하\s*\d+층|\d+층|\d+호)',
  );

  Future<List<LinkPlacePreview>> search(String query) async {
    final matches = await _searchPlaces(query);
    matches.sort((a, b) => b.score.compareTo(a.score));

    final seen = <String>{};
    return matches
        .map((match) => match.preview)
        .where((preview) => seen.add('${preview.title}|${preview.address}'))
        .take(5)
        .toList();
  }

  Future<LinkPlacePreview> extract(String url, {String? sharedText}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw const FormatException('유효한 링크가 아닙니다.');
    }

    final linkCandidates = _queryCandidates(uri).toList();

    final isInstagram = _isInstagramUrl(uri);
    // Instagram 캡션은 Meta 권한 없이는 안정적으로 읽을 수 없습니다.
    // 링크만 공유된 경우에는 수동 확인 화면에서 원본을 열어 입력받습니다.
    final pageCandidates =
        isInstagram ? const <String>[] : await _pageCandidates(uri);

    final sourcePlaceName = _extractSourcePlaceName(
      sharedText: sharedText,
      pageCandidates: pageCandidates,
      linkCandidates: linkCandidates,
    );

    final explicitAddressCandidates = <String>{
      ...linkCandidates,
      ..._addressCandidates([sharedText ?? '', ...pageCandidates]),
    };
    if (explicitAddressCandidates.isEmpty) {
      final placeOnlyCandidates = <String>{
        if (sourcePlaceName != null) sourcePlaceName,
        ...linkCandidates,
        ..._sharedTextCandidates(sharedText),
        ...pageCandidates,
      };
      final matches = <_PlaceMatch>[];
      for (final candidate in placeOnlyCandidates.take(10)) {
        matches.addAll(await _searchPlaces(candidate));
      }
      if (matches.isNotEmpty) {
        matches.sort((a, b) => b.score.compareTo(a.score));
        final preview = matches.first.preview;
        return preview.copyWith(title: sourcePlaceName ?? preview.title);
      }
      throw const FormatException(
        '링크에서 주소 또는 장소명을 찾지 못했습니다. 장소 정보가 포함된 링크만 저장할 수 있어요.',
      );
    }

    final candidates = <String>{
      ...explicitAddressCandidates,
      ..._sharedTextCandidates(sharedText),
      ...pageCandidates,
    };

    final matches = <_PlaceMatch>[];
    for (final candidate in candidates.take(10)) {
      matches.addAll(await _searchPlaces(candidate));
    }

    if (matches.isNotEmpty) {
      matches.sort((a, b) => b.score.compareTo(a.score));
      final sourceAddress = _mostDetailedAddress(explicitAddressCandidates);
      final preview = await _localizePreview(
        matches.first.preview,
        sourceAddress: sourceAddress,
      );
      final detailedPreview = _preserveAddressUnit(
        preview,
        explicitAddressCandidates,
      );
      // The place name must come from the shared link, not a reverse lookup
      // based on the address or map coordinates.
      return detailedPreview.copyWith(title: sourcePlaceName ?? '');
    }

    throw const FormatException('링크에서 장소 주소를 찾지 못했습니다.');
  }

  Future<List<LinkPlacePreview>> extractInstagramPlaces(
      String url, {
        String? sharedText,
      }) async {
    debugPrint('📸 [Instagram] 장소 분석 시작');
    debugPrint('🔗 URL: $url');
    debugPrint('📄 sharedText: $sharedText');

    try {
      // 1. Apify로 Instagram 원본 데이터 가져오기
      final apifyService = ApifyService();

      debugPrint('📡 [Instagram] Apify 분석 요청');

      final results = await apifyService.fetchInstagramData(
        instagramUrl: url,
      );

      debugPrint(
        '📦 [Instagram] Apify 결과 개수: ${results.length}',
      );

      if (results.isEmpty) {
        debugPrint('⚠️ [Instagram] Apify 결과가 없습니다.');
        return const [];
      }

      // caption이 존재하는 결과 찾기
      Map<String, dynamic>? instagramData;

      for (final result in results) {
        if (result is Map<String, dynamic>) {
          final caption = result['caption']?.toString().trim();

          if (caption != null && caption.isNotEmpty) {
            instagramData = result;
            break;
          }
        }
      }

      if (instagramData == null) {
        debugPrint('⚠️ [Instagram] caption을 찾지 못했습니다.');
        return const [];
      }

      final caption = instagramData['caption']?.toString().trim();

      if (caption == null || caption.isEmpty) {
        debugPrint('⚠️ [Instagram] caption이 비어 있습니다.');
        return const [];
      }

      debugPrint('📝 [Instagram] caption 확보');
      debugPrint(caption);

      // 2. Gemini로 장소 추출
      debugPrint('🤖 [Instagram] Gemini 장소 분석 요청');

      final geminiService = GeminiService();

      final placeSources =
      await geminiService.extractInstagramPlaces(caption);

      debugPrint(
        '📍 [Instagram] Gemini에서 장소 '
            '${placeSources.length}개 추출',
      );

      for (final source in placeSources) {
        debugPrint(
          '📍 [Instagram] 추출된 장소: '
              '${source.name} | ${source.address}',
        );
      }

      if (placeSources.isEmpty) {
        debugPrint('⚠️ [Instagram] 추출된 장소가 없습니다.');
        return const [];
      }

      // 3. Google Places에서 실제 장소 확인
      final resultsByPlace = await Future.wait(
        placeSources.map((source) async {
          try {
            debugPrint(
              '🔎 [Instagram] Google Places 검색: '
                  '${source.name} | ${source.address}',
            );

            final query = [
              source.name,
              if (source.address != null &&
                  source.address!.trim().isNotEmpty)
                source.address!,
            ].join(' ');

            final matches = await _searchPlaces(query);

            if (matches.isEmpty) {
              debugPrint(
                '⚠️ [Instagram] Google 검색 결과 없음: '
                    '${source.name}',
              );
              return null;
            }

            matches.sort(
                  (a, b) => b.score.compareTo(a.score),
            );

            final best = matches.first;
            final preview = best.preview;

            debugPrint(
              '✅ [Instagram] 장소 확인: '
                  '${source.name} → '
                  '${preview.title} | '
                  '${preview.address} | '
                  '${preview.latitude}, '
                  '${preview.longitude}',
            );

            return LinkPlacePreview(
              url: url,
              title: source.name,
              address: preview.address,
              latitude: preview.latitude,
              longitude: preview.longitude,
            );
          } catch (e) {
            debugPrint(
              '❌ [Instagram] 장소 검색 실패: '
                  '${source.name} | $e',
            );
            return null;
          }
        }),
      );

      // 4. 검색 실패 제거
      final previews = resultsByPlace
          .whereType<LinkPlacePreview>()
          .toList();

      // 5. 동일 장소 중복 제거
      final unique = <String, LinkPlacePreview>{};

      for (final preview in previews) {
        final key = [
          preview.title.trim().toLowerCase(),
          preview.address?.trim().toLowerCase() ?? '',
        ].join('|');

        unique[key] = preview;
      }

      final finalResults = unique.values.toList();

      debugPrint(
        '🎯 [Instagram] 최종 장소 ${finalResults.length}개',
      );

      for (var i = 0; i < finalResults.length; i++) {
        final preview = finalResults[i];

        debugPrint(
          '   📍 ${i + 1}. '
              '${preview.title} | '
              '${preview.address} | '
              '${preview.latitude}, '
              '${preview.longitude}',
        );
      }

      return finalResults;
    } catch (e, stackTrace) {
      debugPrint(
        '❌ [Instagram] 장소 분석 실패: $e',
      );
      debugPrint('$stackTrace');

      return const [];
    }
  }

  Iterable<String> _addressCandidates(Iterable<String> values) sync* {
    for (final value in values) {
      for (final match in _koreanAddressPattern.allMatches(value)) {
        yield match.group(0)!;
      }
      for (final match in _streetAddressPattern.allMatches(value)) {
        yield match.group(0)!;
      }
    }
  }

  bool _isInstagramUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'instagram.com' || host.endsWith('.instagram.com');
  }

  String _mostDetailedAddress(Iterable<String> addresses) {
    return addresses.reduce(
      (current, next) => current.length >= next.length ? current : next,
    );
  }

  String? _extractSourcePlaceName({
    required String? sharedText,
    required Iterable<String> pageCandidates,
    required Iterable<String> linkCandidates,
  }) {
    final sources = <String>[
      ...linkCandidates,
      ...pageCandidates,
      if (sharedText != null) ...sharedText.split(RegExp(r'[\n|]')),
    ];

    for (final source in sources) {
      final candidate = _normalizeSourcePlaceName(source);
      if (candidate != null) return candidate;
    }
    return null;
  }

  String? _normalizeSourcePlaceName(String source) {
    var value = source
        .replaceAll(RegExp(r'https?://[^\s]+'), '')
        .replaceAll(RegExp(r'@[\w.]+'), '')
        .replaceAll('#', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (value.isEmpty || _koreanAddressPattern.hasMatch(value)) return null;

    value = value
        .replaceFirst(
          RegExp(r'^(?:장소명?|상호명?|매장명?|가게명?|카페명?|식당명?)\s*[:：]\s*'),
          '',
        )
        .replaceAll(
            RegExp(r'\s*[-|]\s*(Instagram|인스타그램).*$', caseSensitive: false), '')
        .split(RegExp(r'[:|·]'))
        .first
        .trim();

    const genericTitles = {
      'instagram',
      '인스타그램',
      '맛집',
      '카페',
      '여행',
      '릴스',
      'reels',
    };
    if (value.length < 2 ||
        value.length > 40 ||
        genericTitles.contains(value.toLowerCase())) {
      return null;
    }
    return value;
  }

  LinkPlacePreview _preserveAddressUnit(
    LinkPlacePreview preview,
    Iterable<String> sourceAddresses,
  ) {
    String? unit;
    for (final sourceAddress in sourceAddresses) {
      unit = _unitPattern.firstMatch(sourceAddress)?.group(0);
      if (unit != null) break;
    }
    if (unit == null || preview.address.contains(unit)) return preview;
    return preview.copyWith(address: '${preview.address} $unit');
  }

  Iterable<String> _sharedTextCandidates(String? sharedText) sync* {
    if (sharedText == null || sharedText.trim().isEmpty) return;

    final cleanText = sharedText
        .replaceAll(RegExp(r'https?://[^\s]+'), ' ')
        .replaceAll('#', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleanText.isNotEmpty) {
      yield cleanText.length > 240 ? cleanText.substring(0, 240) : cleanText;
    }

    for (final line in sharedText.split(RegExp(r'[\n|]'))) {
      final candidate = line
          .replaceAll(RegExp(r'https?://[^\s]+'), '')
          .replaceAll('#', '')
          .trim();
      if (candidate.length >= 2 && candidate.length <= 160) {
        yield candidate;
      }
    }

    const genericTags = {'맛집', '카페', '여행', '데이트', '서울', '릴스', 'reels'};
    for (final match in RegExp(r'#([^\s#]+)').allMatches(sharedText)) {
      final tag = match.group(1)!.replaceAll('_', ' ').trim();
      if (tag.length >= 2 && !genericTags.contains(tag.toLowerCase())) {
        yield tag;
      }
    }
  }

  Iterable<String> _queryCandidates(Uri uri) sync* {
    for (final key in ['q', 'query', 'destination', 'address', 'place']) {
      final value = uri.queryParameters[key]?.trim();
      if (value != null && value.isNotEmpty) yield value;
    }

    final segments = uri.pathSegments;
    final placeIndex = segments.indexOf('place');
    if (placeIndex >= 0 && placeIndex + 1 < segments.length) {
      final value = Uri.decodeComponent(segments[placeIndex + 1]).trim();
      if (value.isNotEmpty) yield value.replaceAll('+', ' ');
    }
  }

  Future<Iterable<String>> _pageCandidates(Uri uri) async {
    try {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Safari/604.1',
          'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
        },
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        return const [];
      }

      final document = html_parser.parse(response.body);
      String? meta(String key) {
        return document
            .querySelector('meta[property="$key"], meta[name="$key"]')
            ?.attributes['content']
            ?.trim();
      }

      final candidates = <String?>[
        meta('og:title'),
        meta('og:description'),
        meta('twitter:title'),
        meta('twitter:description'),
        meta('description'),
        document.querySelector('title')?.text.trim(),
        ...document
            .querySelectorAll('script[type="application/ld+json"]')
            .expand((script) => _jsonLdCandidates(script.text)),
      ];
      return candidates
          .whereType<String>()
          .map(_normalizeCandidate)
          .where((value) => value.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String _normalizeCandidate(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
            RegExp(r'\s*[-|]\s*(Instagram|인스타그램).*$', caseSensitive: false), '')
        .trim();
  }

  Iterable<String> _jsonLdCandidates(String source) sync* {
    try {
      final yieldValues = <String>[];

      void visit(Object? value) {
        if (value is List) {
          for (final item in value) {
            visit(item);
          }
          return;
        }
        if (value is! Map) return;

        final map = Map<String, dynamic>.from(value);
        for (final key in ['name', 'location', 'contentLocation']) {
          final candidate = map[key];
          if (candidate is String && candidate.trim().isNotEmpty) {
            yieldValues.add(candidate);
          }
        }

        final address = map['address'];
        if (address is String && address.trim().isNotEmpty) {
          yieldValues.add(address);
        } else if (address is Map) {
          final parts = [
            address['streetAddress'],
            address['addressLocality'],
            address['addressRegion'],
            address['addressCountry'],
          ].whereType<String>().where((part) => part.trim().isNotEmpty);
          final formattedAddress = parts.join(' ').trim();
          if (formattedAddress.isNotEmpty) {
            yieldValues.add(formattedAddress);
          }
        }

        for (final child in map.values) {
          if (child is Map || child is List) visit(child);
        }
      }

      visit(jsonDecode(source));
      yield* yieldValues;
    } catch (_) {
      return;
    }
  }

  Future<List<_PlaceMatch>> _searchPlaces(String query) async {
    final response = await http
        .post(
          Uri.https('places.googleapis.com', '/v1/places:searchText'),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': Env.googleMapsApiKey,
            'X-Goog-FieldMask':
                'places.displayName,places.formattedAddress,places.location',
          },
          body: jsonEncode({
            'textQuery': query,
            'maxResultCount': 3,
            'languageCode': 'ko',
            'regionCode': 'KR',
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      return const [];
    }

    final places = (jsonDecode(response.body)['places'] as List?) ?? const [];
    if (places.isEmpty) {
      return const [];
    }
    final matches = <_PlaceMatch>[];
    for (var index = 0; index < places.length; index++) {
      final place = places[index] as Map<String, dynamic>;
      final address = place['formattedAddress']?.toString().trim();
      final title = (place['displayName'] as Map?)?['text']?.toString().trim();
      if (address == null ||
          address.isEmpty ||
          title == null ||
          title.isEmpty) {
        continue;
      }

      final location = place['location'] as Map?;
      final preview = LinkPlacePreview(
        url: '',
        title: title,
        address: address,
        latitude: (location?['latitude'] as num?)?.toDouble(),
        longitude: (location?['longitude'] as num?)?.toDouble(),
      );
      matches.add(_PlaceMatch(
        preview: preview,
        score: _matchScore(query, preview, index),
      ));
    }
    return matches;
  }

  Future<LinkPlacePreview> _localizePreview(
    LinkPlacePreview preview, {
    required String sourceAddress,
  }) async {
    try {
      final response = await http.get(
        Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
          'address': sourceAddress,
          'language': 'ko',
          'region': 'kr',
          'key': Env.googleMapsApiKey,
        }),
      );
      if (response.statusCode != 200) {
        return _resolveNearbyPlaceName(
          _normalizePlaceTitle(preview),
          fallbackToEmptyName: true,
        );
      }

      final results =
          (jsonDecode(response.body)['results'] as List?) ?? const [];
      final localizedAddress = results.isEmpty
          ? preview.address
          : (results.first as Map)['formatted_address']?.toString() ??
              preview.address;
      final location = results.isEmpty
          ? null
          : ((results.first as Map)['geometry']?['location'] as Map?);
      final localizedPreview = _normalizePlaceTitle(
        LinkPlacePreview(
          url: preview.url,
          title: preview.title,
          address: localizedAddress,
          latitude: (location?['lat'] as num?)?.toDouble() ?? preview.latitude,
          longitude:
              (location?['lng'] as num?)?.toDouble() ?? preview.longitude,
        ),
      );
      return _resolveNearbyPlaceName(
        localizedPreview,
        fallbackToEmptyName: true,
      );
    } catch (_) {
      return _resolveNearbyPlaceName(
        _normalizePlaceTitle(preview),
        fallbackToEmptyName: true,
      );
    }
  }

  LinkPlacePreview _normalizePlaceTitle(LinkPlacePreview preview) {
    final title = preview.title.trim();
    final isAddressNumber = RegExp(r'^\d+[\s-]*$').hasMatch(title);
    if (!isAddressNumber) return preview;

    return preview.copyWith(title: '');
  }

  Future<LinkPlacePreview> _resolveNearbyPlaceName(
    LinkPlacePreview preview, {
    required bool fallbackToEmptyName,
  }) async {
    if (preview.latitude == null || preview.longitude == null) return preview;

    try {
      final response = await http
          .post(
            Uri.https('places.googleapis.com', '/v1/places:searchNearby'),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': Env.googleMapsApiKey,
              'X-Goog-FieldMask':
                  'places.displayName,places.formattedAddress,places.location',
            },
            body: jsonEncode({
              'languageCode': 'ko',
              'regionCode': 'KR',
              'maxResultCount': 5,
              'rankPreference': 'DISTANCE',
              'locationRestriction': {
                'circle': {
                  'center': {
                    'latitude': preview.latitude,
                    'longitude': preview.longitude,
                  },
                  'radius': 35.0,
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return fallbackToEmptyName ? preview.copyWith(title: '') : preview;
      }

      final places = (jsonDecode(response.body)['places'] as List?) ?? const [];
      for (final place in places) {
        final name = (place as Map)['displayName']?['text']?.toString().trim();
        if (name != null && !_isAddressBasedTitle(name)) {
          return preview.copyWith(title: name);
        }
      }
    } catch (_) {
      // 주변 장소를 찾지 못하면 주소 기반 이름을 그대로 사용합니다.
    }
    return fallbackToEmptyName ? preview.copyWith(title: '') : preview;
  }

  bool _isAddressBasedTitle(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ||
        RegExp(r'^\d+[\s-]*$').hasMatch(normalized) ||
        _streetAddressPattern.hasMatch(normalized);
  }

  double _matchScore(String query, LinkPlacePreview preview, int resultIndex) {
    final normalizedQuery = query.toLowerCase();
    final normalizedTitle = preview.title.toLowerCase();
    final normalizedAddress = preview.address.toLowerCase();
    final queryTokens = _tokens(normalizedQuery);
    final titleTokens = _tokens(normalizedTitle);
    final addressTokens = _tokens(normalizedAddress);

    var score = resultIndex == 0 ? 0.14 : 0.06;
    if (normalizedQuery.contains(normalizedTitle) ||
        normalizedTitle.contains(normalizedQuery)) {
      score += 0.8;
    }
    for (final token in queryTokens) {
      if (titleTokens.contains(token)) score += 0.24;
      if (addressTokens.contains(token)) score += 0.08;
    }
    if (queryTokens.length > 6) score -= 0.12;
    return score;
  }

  Set<String> _tokens(String value) {
    return RegExp(r'[가-힣a-z0-9]{2,}', caseSensitive: false)
        .allMatches(value)
        .map((match) => match.group(0)!)
        .toSet();
  }
}

class _PlaceMatch {
  const _PlaceMatch({
    required this.preview,
    required this.score,
  });

  final LinkPlacePreview preview;
  final double score;
}
