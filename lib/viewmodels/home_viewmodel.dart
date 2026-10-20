import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../env.dart';
import '../models/marker_model.dart';
import '../models/link_preview_data.dart';
import '../models/shared_link_model.dart'; // SharedLinkModel 임포트
import '../services/marker_service.dart';
import '../services/link_preview_service.dart';
import '../services/shared_link_service.dart';

class HomeDashboardViewModel extends ChangeNotifier {
  bool _disposed = false;
  final Map<String, LinkPreviewData?> _previewCache = {};
  final Map<String, Future<LinkPreviewData?>> _previewRequests = {};

  // Desktop Naver shells and mobile articles must not share stale shell metadata.
  String _previewKey(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host.toLowerCase() == 'blog.naver.com'
        ? uri!.replace(host: 'm.blog.naver.com').toString()
        : url;
  }

  bool hasPreview(String url) => _previewCache.containsKey(_previewKey(url));
  LinkPreviewData? previewFor(String url) => _previewCache[_previewKey(url)];

  Future<LinkPreviewData?> loadPreview(String url) {
    url = _previewKey(url);
    if (_previewCache.containsKey(url)) {
      return Future.value(_previewCache[url]);
    }
    return _previewRequests.putIfAbsent(url, () async {
      try {
        final preview = await const LinkPreviewService().load(url);
        _previewCache[url] = preview;
        if (!_disposed) notifyListeners();
        return preview;
      } catch (_) {
        _previewCache[url] = null;
        if (!_disposed) notifyListeners();
        return null;
      } finally {
        _previewRequests.remove(url);
      }
    });
  }

  final List<MarkerModel> _recentMarkers = [];
  final List<SharedLinkModel> _sharedLinks = [];

  List<MarkerModel> get recentMarkers => _recentMarkers;
  List<SharedLinkModel> get sharedLinks => _sharedLinks;
  final Map<String, double?> _ratingCache = {};
  RealtimeChannel? _realtimeChannel;
  String? _realtimeUserId;

  void subscribeToChanges() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _realtimeUserId == user.id) return;

    _realtimeChannel?.unsubscribe();
    _realtimeUserId = user.id;
    _realtimeChannel = Supabase.instance.client
        .channel('home-dashboard-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shared_links',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => loadSharedLinks(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_markers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => loadRecentMarkers(),
        )
        .subscribe();
  }

  // Public Getter 추가
  double? getRating(String query) {
    return _ratingCache[query];
  }

  String _getQueryKey(MarkerModel marker) {
    return (marker.title.isNotEmpty)
        ? '${marker.title} ${marker.address}'
        : marker.address;
  }

  // loadRecentMarkers() 안에 _loadRatings() 호출 유지
  Future<void> loadRecentMarkers() async {
    final rawMarkers = await MarkerService().getRecentMarkers(limit: 5);
    _recentMarkers.clear();
    _recentMarkers
        .addAll(rawMarkers.map((e) => MarkerModel.fromMap(e)).toList());

    notifyListeners();
    _loadRatings(); // 평점 로드
  }

  Future<void> _loadRatings() async {
    for (final marker in _recentMarkers) {
      final key = _getQueryKey(marker);
      if (_ratingCache.containsKey(key)) continue;

      final rating = await _getGoogleRating(key);
      _ratingCache[key] = rating;
    }
    notifyListeners();
  }

  Future<double?> _getGoogleRating(String query) async {
    try {
      final searchRes = await http.post(
        Uri.https('places.googleapis.com', '/v1/places:searchText'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': Env.googleMapsApiKey,
          'X-Goog-FieldMask': 'places.id',
        },
        body: jsonEncode({'textQuery': query}),
      );

      if (searchRes.statusCode != 200) return null;

      final searchData = jsonDecode(searchRes.body);
      final places = searchData['places'] as List<dynamic>?;
      if (places == null || places.isEmpty) return null;

      final placeId = places[0]['id'] as String?;
      if (placeId == null) return null;

      final detailsRes = await http.get(
        Uri.https('places.googleapis.com', '/v1/places/$placeId', {
          'fields': 'rating',
          'key': Env.googleMapsApiKey,
        }),
      );

      if (detailsRes.statusCode != 200) return null;

      final detailsData = jsonDecode(detailsRes.body);
      return (detailsData['rating'] as num?)?.toDouble();
    } catch (e) {
      debugPrint('Google Rating Error: $e');
      return null;
    }
  }

  // 공유 링크 불러오는 함수 추가
  Future<void> loadSharedLinks() async {
    final rawLinks = await SharedLinkService().loadSharedLinks(); // ✅ 수정된 부분
    _sharedLinks.clear();
    _sharedLinks.addAll(rawLinks);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
