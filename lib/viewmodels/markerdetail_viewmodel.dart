import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../env.dart';
import '../views/mapsample_view.dart';
import 'package:url_launcher/url_launcher.dart';


class MarkerDetailViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

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

  // 생성자 추가
  MarkerDetailViewModel(this._marker);

  Marker get marker => _marker;

  String get title => _title ?? '제목 없음';

  String? get keyword => _keyword;

  String? get address => _address;

  String? get memo => _memo;

  String? get businessHours => _businessHours;

  bool? get isOpen => _isOpen;

  double? get rating => _rating;

  int? get reviewCount => _reviewCount;

  String? get distance => _distance;

  String? get walkTime => _walkTime;

  String? get phone => _phone;

  late TextEditingController _titleController;
  bool isLoadingImages = false;
  bool isBookmarked = false;
  List<Marker> bookmarkedMarkers = [];
  List<String> imageUrls = [];

  // 리뷰 플랫폼 리스트 반환 (길찾기와 분리)
  List<Map<String, String>> get reviewLinks {
    final title = _marker.infoWindow.title ?? _title ?? '';
    final encoded = Uri.encodeComponent(title);

    return [
      {
        'platform': '네이버',
        'url': 'https://search.naver.com/search.naver?query=$encoded'
      },
      {'platform': '카카오맵', 'url': 'https://map.kakao.com/link/search/$encoded'},
      {'platform': '구글', 'url': 'https://www.google.com/search?q=$encoded'},
      {
        'platform': '인스타그램',
        'url': 'https://www.instagram.com/explore/tags/$encoded/'
      },
    ];
  }

  Future<List<String>> fetchPhotos(String address, String? title) async {
    if (address.isEmpty) return [];
    final query = (title != null && title.isNotEmpty)
        ? '$title $address'
        : address;
    try {
      final res = await http.post(
        Uri.https('places.googleapis.com', '/v1/places:searchText'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': Env.googleMapsApiKey,
          'X-Goog-FieldMask': 'places.id,places.photos',
        },
        body: jsonEncode({'textQuery': query}),
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final places = data['places'] as List<dynamic>?;
      if (places == null || places.isEmpty) return [];
      final urls = <String>[];
      for (final photo in places[0]['photos'] ?? []) {
        urls.add(
          'https://places.googleapis.com/v1/${photo['name']}/media'
              '?key=${Env.googleMapsApiKey}&maxWidthPx=800',
        );
        if (urls.length >= 6) break;
      }
      print('=== 불러온 사진 개수: ${urls.length}장 ===');
      return urls;
    } catch (_) {
      return [];
    }
  }

  // 서파베이스에 저장된 데이터 불러옴 + Google Places API로 실시간 정보 보강
  Future<void> fetchUserMarkerDetail(String markerId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    try {
      // 1. Supabase에서 실제 존재하는 컬럼만 가져오기
      final data = await supabase
          .from('user_markers')
          .select('title, address, keyword, snippet')
          .eq('id', markerId)
          .maybeSingle();

      print('Supabase data: $data');

      if (data != null) {
        _title = data['title'] as String? ?? '제목 없음';
        _address = data['address'] as String?;
        _keyword = data['keyword'] as String?;
        _memo = data['snippet'] as String?; // snippet을 memo로 대체 사용
      } else {
        _title = '제목 없음';
        _address = '주소를 찾을 수 없습니다';
        _keyword = null;
        _memo = null;
      }

      // 2. Google Places API로 실시간 정보 가져오기 (영업시간, 평점, 전화번호 등)
      if (_address != null && _address!.isNotEmpty) {
        await _fetchGooglePlaceDetails(_address!, _title);
      }

      // 3. 현재 위치 기반 거리 + 도보 시간 계산
      await _calculateDistanceAndWalkTime();

      notifyListeners();
    } catch (e, stacktrace) {
      print('fetchUserMarkerDetail error: $e');
      print(stacktrace);
      _address = '주소 오류';
      _memo = null;
      _distance = '–';
      _walkTime = null;
      notifyListeners();
    }
  }

// Google Places API 호출 (Text Search → Place Details)
  Future<void> _fetchGooglePlaceDetails(String address, String? title) async {
    final query = (title != null && title.isNotEmpty)
        ? '$title $address'
        : address;

    try {
      // Step 1: Text Search로 place 후보 찾기
      final searchRes = await http.post(
        Uri.https('places.googleapis.com', '/v1/places:searchText'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': Env.googleMapsApiKey,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress',
        },
        body: jsonEncode({'textQuery': query}),
      );

      if (searchRes.statusCode != 200) return;

      final searchData = jsonDecode(searchRes.body);
      final places = searchData['places'] as List<dynamic>?;

      if (places == null || places.isEmpty) return;

      final placeId = places[0]['id'] as String?;

      if (placeId == null) return;

      // Step 2: Place Details로 상세 정보 가져오기
      final detailsRes = await http.get(
        Uri.https('places.googleapis.com', '/v1/places/$placeId', {
          'fields': 'currentOpeningHours,regularOpeningHours,rating,userRatingCount,internationalPhoneNumber,nationalPhoneNumber,formattedAddress',
          'key': Env.googleMapsApiKey,
        }),
      );

      if (detailsRes.statusCode != 200) return;

      final detailsData = jsonDecode(detailsRes.body);

      // business_hours (영업시간 문자열로 변환)
      final openingHours = detailsData['currentOpeningHours'] ??
          detailsData['regularOpeningHours'];
      if (openingHours != null) {
        final periods = openingHours['periods'] as List<dynamic>? ?? [];
        _businessHours = periods.isNotEmpty
            ? '${periods[0]['open']['time']} - ${periods[0]['close']?['time'] ??
            '22:00'}'
            : '영업시간 정보 없음';
      } else {
        _businessHours = '영업시간 정보 없음';
      }

      // is_open (현재 영업 중 여부)
      _isOpen = openingHours?['openNow'] as bool?;

      // rating
      _rating = (detailsData['rating'] as num?)?.toDouble();

      // review_count
      _reviewCount = detailsData['userRatingCount'] as int?;

      // phone
      _phone = detailsData['internationalPhoneNumber'] as String? ??
          detailsData['nationalPhoneNumber'] as String?;

      print(
          'Google Places 데이터 로드 완료: rating=$_rating, phone=$_phone, isOpen=$_isOpen');
    } catch (e) {
      print('Google Places API error: $e');
      // 실패 시 기본값 유지 (null)
      _businessHours = null;
      _isOpen = null;
      _rating = null;
      _reviewCount = null;
      _phone = null;
    }
  }

  Future<void> deleteMarker(BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('user_markers')
          .delete()
          .eq('user_id', user.id)
          .eq('id', _marker.markerId.value);


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마커 및 연관 데이터가 삭제되었습니다.')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MapSampleView()),
            (route) => false, // 모든 이전 라우트를 제거
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.toString()}')),
      );
    }
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
        desiredAccuracy: LocationAccuracy.high,
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

      print('거리 계산 완료: $_distance, $_walkTime');
    } catch (e) {
      print('거리 계산 오류: $e');
      _distance = '–';
      _walkTime = null;
    }
  }

  void saveMarker(BuildContext context) {
    final updatedMarker = _marker.copyWith(
      infoWindowParam: _marker.infoWindow.copyWith(
        titleParam: _titleController.text,
      ),
    );
    Navigator.pop(context);
    notifyListeners();
  }

  @override
  void dispose() {
    Provider
        .of<MarkerDetailViewModel>(context as BuildContext, listen: false)
        .dispose();
    super.dispose();
  }

// ==================== 길찾기 메서드 개선 버전 ====================

// Google Maps (웹 URL이므로 기존 코드 유지 + 에러 처리 강화)
  void openGoogleMaps(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 서비스를 켜주세요')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 필요합니다')),
        );
        return;
      }

      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${currentPosition
            .latitude},${currentPosition.longitude}&destination=${_marker
            .position.latitude},${_marker.position.longitude}',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Maps를 열 수 없습니다')),
        );
      }
    } catch (e) {
      print('openGoogleMaps error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

// 카카오맵
  void openKakaoMap(BuildContext context) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final String kakaoMapUrl = 'kakaomap://route?sp=${position
          .latitude},${position.longitude}&ep=${_marker.position
          .latitude},${_marker.position.longitude}&by=CAR';

      final Uri uri = Uri.parse(kakaoMapUrl);

      // canLaunchUrl 대신 직접 launchUrl 시도 → 실패하면 설치 페이지
      final launched = await launchUrl(
          uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        final installUrl = Platform.isIOS
            ? Uri.parse('https://apps.apple.com/kr/app/id304608425')
            : Uri.parse(
            'https://play.google.com/store/apps/details?id=net.daum.android.map');

        await launchUrl(installUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('openKakaoMap error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오맵을 열 수 없습니다')),
      );
    }
  }

// 네이버맵
  void openNaverMap(BuildContext context) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final String naverMapUrl = 'nmap://route/car?slat=${position
          .latitude}&slng=${position.longitude}&sname=현재위치&dlat=${_marker
          .position.latitude}&dlng=${_marker.position.longitude}&dname=목적지';

      final Uri uri = Uri.parse(naverMapUrl);

      final launched = await launchUrl(
          uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        final installUrl = Platform.isIOS
            ? Uri.parse('https://apps.apple.com/kr/app/id311867728')
            : Uri.parse(
            'https://play.google.com/store/apps/details?id=com.nhn.android.nmap');

        await launchUrl(installUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('openNaverMap error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네이버맵을 열 수 없습니다')),
      );
    }
  }

// 티맵
  void openTmap(BuildContext context) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final String tmapUrl = 'tmap://route?goalLat=${_marker.position
          .latitude}&goalLon=${_marker.position.longitude}&startLat=${position
          .latitude}&startLon=${position.longitude}&goalName=목적지&startName=출발지';

      final Uri uri = Uri.parse(tmapUrl);

      final launched = await launchUrl(
          uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        final installUrl = Platform.isIOS
            ? Uri.parse(
            'https://apps.apple.com/kr/app/t-map-t맵-대중교통-길찾기-지도-내비게이션/id431589174')
            : Uri.parse(
            'https://play.google.com/store/apps/details?id=com.skt.tmap.ku');

        await launchUrl(installUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('openTmap error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('티맵을 열 수 없습니다')),
      );
    }
  }
}