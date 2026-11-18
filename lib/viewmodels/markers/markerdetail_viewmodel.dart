import 'dart:async';
import '../../services/places/place_lookup_repository.dart';
import '../../services/places/place_hours.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/markers/marker_service.dart';
import '../../services/places/places_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkerDetailViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  final MarkerService _markerService = MarkerService();
  final PlacesService _placesService = PlacesService();

  final Marker _marker;
  String? _title;
  String? _keyword;
  String? _address;
  String? _memo;
  String? _businessHours;
  bool? _isOpen;
  double? _rating;
  int? _reviewCount;
  String? _distance;
  String? _walkTime;
  String? _phone;
  List<String> _weeklyHours = [];
  String? placeDetailsError;
  bool isLoadingPlaceDetails = false;
  String? _googleMapsUri;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> retryPlaceDetails() =>
      _fetchGooglePlaceDetails(_address ?? '', title);

  // 생성자 추가
  MarkerDetailViewModel(this._marker);

  Marker get marker => _marker;

  String get title => _title ?? _marker.infoWindow.title ?? '제목 없음';

  List<Map<String, String>> savedLists = [];
  List<String> get tags => RegExp(r'#([^\s#]+)')
      .allMatches(_memo ?? '')
      .map((match) => match.group(1)!)
      .toSet()
      .toList();
  String get region {
    final parts = (_address ?? '').split(RegExp(r'\s+'));
    return parts.take(2).join(' ');
  }

  String? get keyword => _keyword;

  String? get address => _address;

  String? get memo {
    final text = _memo?.trim();
    if (text == null || text.isEmpty) return null;
    // 검색 결과의 주소가 마커 설명에 저장되어 있을 수 있습니다.
    // 실제 메모는 유지하되 주소를 설명으로 반복 표시하지 않습니다.
    String normalized(String value) =>
        value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (_address != null && normalized(text) == normalized(_address!)) {
      return null;
    }
    return text;
  }

  String? get businessHours => _businessHours;

  bool? get isOpen => _isOpen;

  double? get rating => _rating;

  int? get reviewCount => _reviewCount;

  String? get distance => _distance;

  String? get walkTime => _walkTime;

  String? get phone => _phone;

  List<String> get weeklyHours => _weeklyHours;

  late TextEditingController _titleController;
  bool isLoadingImages = false;
  bool isBookmarked = false;
  List<Marker> bookmarkedMarkers = [];
  List<String> imageUrls = [];
  Completer<List<String>> _photoResult = Completer<List<String>>();
  int photoRevision = 0;

  // 리뷰 플랫폼 리스트 반환 (길찾기와 분리)
  List<Map<String, String>> get reviewLinks {
    final title = _marker.infoWindow.title ?? _title ?? '';
    final address = _marker.infoWindow.snippet ?? _address ?? ''; // 주소 필드 사용

    // 검색어 조합 (이름 + 주소)
    final searchQuery = title.isNotEmpty && address.isNotEmpty
        ? '$title $address'
        : title; // 주소가 없으면 title만 사용

    final encoded = Uri.encodeComponent(searchQuery);

    return [
      {
        'platform': '네이버',
        'url': //'https://pcmap.place.naver.com/search/all/$encoded/review/visitor',  // 후기 탭 우선
            // 또는 더 일반적으로:
            'https://search.naver.com/search.naver?query=$encoded&where=pcmap&sm=tab_hty'
      },
      {
        'platform': '구글',
        'url': 'https://www.google.com/search?q=$encoded+리뷰', // "장소이름 리뷰"로 검색
        // 또는
        // 'https://www.google.com/maps/search/?api=1&query=$encoded'
      },
      {
        'platform': '인스타그램',
        'url':
            'https://www.instagram.com/explore/tags/${Uri.encodeComponent(title.replaceAll(" ", ""))}/',
      },
    ];
  }

  Future<List<String>> fetchPhotos(String address, String? title) =>
      _photoResult.future;

  // 서파베이스에 저장된 데이터 불러옴 + Google Places API로 실시간 정보 보강
  Future<void> fetchUserMarkerDetail(String markerId) async {
    _title = _marker.infoWindow.title;
    try {
      final data = await _markerService.loadMarkerDetail(markerId);
      if (data != null) {
        _title = data['title'] as String? ?? _title;
        _address = data['address'] as String?;
        _keyword = data['keyword'] as String?;
        _memo = data['snippet'] as String?;
      }
    } catch (error) {
      debugPrint('저장된 장소 정보 조회 실패');
    }
    notifyListeners();
    // 관련 정보 조회가 GPS나 소속 리스트 조회를 기다리지 않도록 합니다.
    await _fetchGooglePlaceDetails(_address ?? '', title);
    if (_disposed) return;
    await _loadSavedLists(markerId);
    if (_disposed) return;
    await _calculateDistanceAndWalkTime();
    notifyListeners();
  }

  Future<void> _loadSavedLists(String markerId) async {
    try {
      final rows = await supabase
          .from('list_bookmarks')
          .select('list_id, lists(id, name)')
          .eq('marker_id', markerId);
      final unique = <String, Map<String, String>>{};
      for (final row in rows) {
        final list = row['lists'];
        if (list is Map && list['id'] != null && list['name'] != null) {
          final id = list['id'].toString();
          unique[id] = {'id': id, 'name': list['name'].toString()};
        }
      }
      savedLists = unique.values.toList();
      notifyListeners();
    } catch (error) {
      debugPrint('Saved lists could not be loaded: $error');
    }
  }

// Google Places API 호출 (Text Search → Place Details)
  Future<void> _fetchGooglePlaceDetails(String address, String? title) async {
    final query = [title, address]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty && s != '제목 없음')
        .join(' ');
    if (query.isEmpty) {
      if (!_photoResult.isCompleted) _photoResult.complete([]);
      placeDetailsError = '장소 이름이 없어 관련 정보를 조회할 수 없습니다.';
      notifyListeners();
      return;
    }
    if (isLoadingPlaceDetails) return;
    if (_photoResult.isCompleted) {
      _photoResult = Completer<List<String>>();
      photoRevision++;
    }
    isLoadingPlaceDetails = true;
    placeDetailsError = null;
    notifyListeners();
    try {
      final details = await _placesService.searchPlaceDetails(query);
      if (!_photoResult.isCompleted) {
        _photoResult.complete(PlaceLookupRepository.photoUrls(details));
      }
      if (details == null) {
        placeDetailsError = '일치하는 장소를 찾지 못했어요.';
        return;
      }
      final current = details['currentOpeningHours'] as Map<String, dynamic>?;
      final regular = details['regularOpeningHours'] as Map<String, dynamic>?;
      final today = DateTime.now().weekday % 7;
      _businessHours = PlaceHours.forDay(current ?? regular, today);
      if (_businessHours == '영업시간 정보 없음' && regular != null) {
        _businessHours = PlaceHours.forDay(regular, today);
      }
      _weeklyHours = PlaceHours.weekly(regular ?? current);
      _isOpen = (current ?? regular)?['openNow'] as bool?;
      _rating = (details['rating'] as num?)?.toDouble();
      _reviewCount = (details['userRatingCount'] as num?)?.toInt();
      _googleMapsUri = details['googleMapsUri'] as String?;
      _address ??= details['formattedAddress'] as String?;
      _phone = details['internationalPhoneNumber'] as String? ??
          details['nationalPhoneNumber'] as String?;
    } on PlacesLookupException catch (error) {
      placeDetailsError = error.statusCode == 403
          ? '장소 API 접근이 거부됐어요. API 설정을 확인해주세요.'
          : '장소 정보를 불러오지 못했어요. 다시 시도해주세요.';
    } catch (_) {
      placeDetailsError = '장소 정보를 불러오지 못했어요. 다시 시도해주세요.';
    } finally {
      if (!_photoResult.isCompleted) _photoResult.complete([]);
      isLoadingPlaceDetails = false;
      notifyListeners();
    }
  }

  Future<void> deleteMarker() async {
    await _markerService.deleteUserMarker(_marker.markerId.value);
  }

  // 현재 위치 기반 거리 + 도보 시간 계산
  Future<void> _calculateDistanceAndWalkTime() async {
    if (_marker.position.latitude == 0 && _marker.position.longitude == 0) {
      _distance = '–';
      _walkTime = null;
      return;
    }

    try {
      // 위치 권한 및 서비스 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _distance = '위치 서비스 OFF';
        _walkTime = null;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _distance = '위치 권한 필요';
          _walkTime = null;
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _distance = '위치 권한 영구 거부';
        _walkTime = null;
        return;
      }

      // 현재 위치 가져오기
      Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // 거리 계산 (미터 → km)
      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        _marker.position.latitude,
        _marker.position.longitude,
      );

      double distanceInKm = distanceInMeters / 1000;

      _distance = distanceInKm < 1
          ? '${distanceInMeters.toStringAsFixed(0)} m'
          : '${distanceInKm.toStringAsFixed(1)} km';

      // 도보 시간 계산 (평균 도보 속도 4.5 km/h ≈ 1.25 m/s)
      double walkSpeedMps = 1.25; // 초당 1.25m
      int walkMinutes = (distanceInMeters / walkSpeedMps / 60).round();

      _walkTime = walkMinutes < 60
          ? '도보 $walkMinutes분'
          : '도보 ${(walkMinutes / 60).toStringAsFixed(1)}시간';

      debugPrint('거리 계산 완료: $_distance, $_walkTime');
    } catch (e) {
      debugPrint('거리 계산 오류: $e');
      _distance = '–';
      _walkTime = null;
    }
  }

  void saveMarker() {
    _title = _titleController.text;
    notifyListeners();
  }

  // 클래스 하단에 추가 (openReviewPage 메서드)
  Future<String?> openGoogleReview() async {
    final title = _title ?? _marker.infoWindow.title ?? '';
    final address = _address ?? _marker.infoWindow.snippet ?? '';

    final searchQuery =
        title.isNotEmpty && address.isNotEmpty ? '$title $address' : title;

    final encoded = Uri.encodeComponent(searchQuery);
    final googleReviewUrl = 'https://www.google.com/search?q=$encoded+리뷰';

    final uri = Uri.parse(_googleMapsUri ?? googleReviewUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      return '링크를 열 수 없습니다';
    }
    return null;
  }

// ==================== 길찾기 메서드 개선 버전 ====================

// Google Maps (웹 URL이므로 기존 코드 유지 + 에러 처리 강화)
  Future<String?> openGoogleMaps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return '위치 서비스를 켜주세요';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return '위치 권한이 필요합니다';
      }

      Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=${_marker.position.latitude},${_marker.position.longitude}',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        return 'Google Maps를 열 수 없습니다';
      }
      return null;
    } catch (e) {
      debugPrint('openGoogleMaps error: $e');
      return '오류가 발생했습니다: $e';
    }
  }

// 카카오맵
  Future<String?> openKakaoMap() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      final String kakaoMapUrl =
          'kakaomap://route?sp=${position.latitude},${position.longitude}&ep=${_marker.position.latitude},${_marker.position.longitude}&by=CAR';

      final Uri uri = Uri.parse(kakaoMapUrl);

      // canLaunchUrl 대신 직접 launchUrl 시도 → 실패하면 설치 페이지
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        final installUrl = Platform.isIOS
            ? Uri.parse('https://apps.apple.com/kr/app/id304608425')
            : Uri.parse(
                'https://play.google.com/store/apps/details?id=net.daum.android.map');

        await launchUrl(installUrl, mode: LaunchMode.externalApplication);
      }
      return null;
    } catch (e) {
      debugPrint('openKakaoMap error: $e');
      return '카카오맵을 열 수 없습니다';
    }
  }

// 네이버맵
  Future<String?> openNaverMap() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      final String naverMapUrl =
          'nmap://route/car?slat=${position.latitude}&slng=${position.longitude}&sname=현재위치&dlat=${_marker.position.latitude}&dlng=${_marker.position.longitude}&dname=목적지';

      final Uri uri = Uri.parse(naverMapUrl);

      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        final installUrl = Platform.isIOS
            ? Uri.parse('https://apps.apple.com/kr/app/id311867728')
            : Uri.parse(
                'https://play.google.com/store/apps/details?id=com.nhn.android.nmap');

        await launchUrl(installUrl, mode: LaunchMode.externalApplication);
      }
      return null;
    } catch (e) {
      debugPrint('openNaverMap error: $e');
      return '네이버맵을 열 수 없습니다';
    }
  }

// 티맵
  Future<String?> openTmap() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      final String tmapUrl =
          'tmap://route?goalLat=${_marker.position.latitude}&goalLon=${_marker.position.longitude}&startLat=${position.latitude}&startLon=${position.longitude}&goalName=목적지&startName=출발지';

      final Uri uri = Uri.parse(tmapUrl);

      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        final installUrl = Platform.isIOS
            ? Uri.parse(
                'https://apps.apple.com/kr/app/t-map-t맵-대중교통-길찾기-지도-내비게이션/id431589174')
            : Uri.parse(
                'https://play.google.com/store/apps/details?id=com.skt.tmap.ku');

        await launchUrl(installUrl, mode: LaunchMode.externalApplication);
      }
      return null;
    } catch (e) {
      debugPrint('openTmap error: $e');
      return '티맵을 열 수 없습니다';
    }
  }
}
