import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/shared_links/link_preview_data.dart';
import '../../models/shared_links/shared_link_model.dart';
import '../../services/shared_links/link_preview_service.dart';
import '../../services/places/places_service.dart';
import '../../services/shared_links/shared_link_service.dart';
import '../../services/shared_links/shared_place_lookup_service.dart';
import '../../services/places/geocoding_service.dart';

typedef PlaceRating = ({double score, int? count});

class SharedLinkDetailViewModel extends ChangeNotifier {
  SharedLinkDetailViewModel(this.link,
      {Future<Map<String, dynamic>?> Function(String)? ratingLoader})
      : _ratingLoader =
            ratingLoader ?? ((query) => PlacesService().searchRating(query));
  final Future<Map<String, dynamic>?> Function(String) _ratingLoader;

  final SharedLinkModel link;
  final SharedPlaceLookupService _placeLookup =
      const SharedPlaceLookupService();
  final GeocodingService _geocoding = const GeocodingService();
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  LinkPreviewData? preview;
  List<SharedLinkModel> places = const [];
  bool isLoadingPlaces = true;
  bool placeLoadFailed = false;
  bool isCheckingSavedMarkers = true;
  bool savedMarkerLookupFailed = false;
  bool isAdding = false;
  final Set<String> _savedPlaceKeys = {};
  final Map<String, PlaceRating> _ratings = {};

  PlaceRating? ratingFor(SharedLinkModel place) => _ratings[placeKey(place)];

  String placeKey(SharedLinkModel place) =>
      place.id ?? '${place.url}|${place.placeTitle}|${place.placeAddress}';

  bool isSaved(SharedLinkModel place) =>
      _savedPlaceKeys.contains(placeKey(place));

  Future<void> load() async {
    try {
      preview = await const LinkPreviewService().load(link.url);
      _notify();
    } catch (_) {
      // 원본 미리보기가 없어도 저장된 장소 목록은 사용할 수 있습니다.
    }
  }

  Future<void> loadPlaces() async {
    isLoadingPlaces = true;
    placeLoadFailed = false;
    _notify();
    try {
      places = await SharedLinkService().loadSharedLinkPlaces(link.url);
    } catch (_) {
      placeLoadFailed = true;
      places = [link];
    } finally {
      isLoadingPlaces = false;
      _notify();
      await refreshSavedMarkers();
    }
  }

  final _ratingQueued = <String>{};
  final _ratingQueue = <SharedLinkModel>[];
  int _ratingActive = 0;

  // 실제로 생성된 카드만 요청하고 동시에 실행하는 검색은 두 개로 제한합니다.
  void requestRating(SharedLinkModel place) {
    if (_disposed ||
        _ratings.containsKey(placeKey(place)) ||
        !_ratingQueued.add(placeKey(place))) {
      return;
    }
    _ratingQueue.add(place);
    _drainRatings();
  }

  void _drainRatings() {
    while (!_disposed && _ratingActive < 2 && _ratingQueue.isNotEmpty) {
      final place = _ratingQueue.removeAt(0);
      _ratingActive++;
      unawaited(_loadRating(place).whenComplete(() {
        _ratingActive--;
        _drainRatings();
      }));
    }
  }

  Future<void> _loadRating(SharedLinkModel place) async {
    final title = place.placeTitle?.trim() ?? '';
    final address = place.placeAddress?.trim() ?? '';
    if (title.isEmpty || address.isEmpty) return;
    try {
      final result = await _ratingLoader('$title $address');
      final score = (result?['rating'] as num?)?.toDouble();
      if (_disposed || score == null) return;
      _ratings[placeKey(place)] =
          (score: score, count: (result?['userRatingCount'] as num?)?.toInt());
      _notify();
    } catch (_) {
      // 실패를 성공 캐시로 남기지 않고 다음 진입에서 재시도합니다.
    }
  }

  String _normalized(String? value) => (value ?? '').trim().toLowerCase();

  bool _matchesSavedMarker(Map<String, dynamic> marker, SharedLinkModel place) {
    final title = _normalized(place.placeTitle);
    final titleMatches =
        title.isNotEmpty && title == _normalized(marker['title']?.toString());
    final lat = (marker['lat'] as num?)?.toDouble();
    final lng = (marker['lng'] as num?)?.toDouble();
    final coordinatesMatch = place.placeLatitude != null &&
        place.placeLongitude != null &&
        lat != null &&
        lng != null &&
        (place.placeLatitude! - lat).abs() < 0.00005 &&
        (place.placeLongitude! - lng).abs() < 0.00005;
    final address = _normalized(place.placeAddress);
    final addressMatches = address.isNotEmpty &&
        address == _normalized(marker['address']?.toString());
    return (titleMatches && (coordinatesMatch || addressMatches)) ||
        (coordinatesMatch && addressMatches);
  }

  Future<void> refreshSavedMarkers() async {
    isCheckingSavedMarkers = true;
    _notify();
    try {
      final markers = await _placeLookup.loadSavedMarkers();
      _savedPlaceKeys
        ..clear()
        ..addAll(places
            .where(
              (place) =>
                  markers.any((marker) => _matchesSavedMarker(marker, place)),
            )
            .map(placeKey));
      savedMarkerLookupFailed = false;
    } catch (error) {
      savedMarkerLookupFailed = true;
      debugPrint('저장된 장소 조회 실패: $error');
    } finally {
      isCheckingSavedMarkers = false;
      _notify();
    }
  }

  void setAdding(bool value) {
    isAdding = value;
    _notify();
  }

  void markSaved(SharedLinkModel place) {
    _savedPlaceKeys.add(placeKey(place));
    _notify();
  }

  Future<LatLng?> resolvePosition(SharedLinkModel place) async {
    if (place.placeLatitude != null && place.placeLongitude != null) {
      return LatLng(place.placeLatitude!, place.placeLongitude!);
    }
    final address = place.placeAddress;
    if (address == null || address.isEmpty) return null;
    return _geocoding.findCoordinates(address);
  }
}
