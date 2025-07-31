import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../views/mapsample_view.dart';
import 'package:url_launcher/url_launcher.dart';


class MarkerDetailViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  final Marker _marker;
  String? _title;
  String? _keyword;
  String? _address;

  // 생성자 추가
  MarkerDetailViewModel(this._marker);

  Marker get marker => _marker;
  String get title => _title ?? '제목 없음';
  String? get keyword => _keyword;
  String? get address => _address;

  late TextEditingController _titleController;
  bool isLoadingImages = false;
  bool isBookmarked = false;
  List<Marker> bookmarkedMarkers = [];
  List<String> imageUrls = [];

  // 리뷰 플랫폼 리스트 반환
  List<Map<String, String>> get reviewLinks {
    final title = _marker.infoWindow.title ?? '';
    final addr = _address ?? '';
    final encoded = Uri.encodeComponent('$title $addr $keyword');

    return [
      {
        'platform': '네이버',
        'icon': 'assets/logos/naver.png',
        'url': 'https://search.naver.com/search.naver?query=$encoded',
      },
      {
        'platform': '다음',
        'icon': 'assets/logos/daum.png',
        'url': 'https://search.daum.net/search?q=$encoded',
      },
      {
        'platform': '구글',
        'icon': 'assets/logos/google.png',
        'url': 'https://www.google.com/search?q=$encoded',
      },
      {
        'platform': '인스타그램',
        'icon': 'assets/logos/instagram.png', // 로고 추가 필요
        'url': 'https://www.instagram.com/explore/tags/$encoded/',
      },
    ];
  }

  Future<void> fetchUserMarkerDetail(String markerId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    try {
      final data = await supabase
          .from('user_markers')
          .select('title, address, keyword')
          .eq('id', markerId)
          .eq('user_id', user.id)
          .maybeSingle();

      print('fetchUserMarkerDetail data: $data');  // 여기에 로그 추가

      if (data != null) {
        _title = data['title'] as String? ?? '제목 없음';
        _address = data['address'] as String?;
        _keyword = data['keyword'] as String? ?? '키워드 없음';
      } else {
        print('No data found for markerId: $markerId, userId: ${user.id}');
        _address = '주소를 찾을 수 없습니다';
        _keyword = '키워드 없음';
      }

      notifyListeners();
    } catch (e, stacktrace) {
      print('fetchUserMarkerDetail error: $e');
      print(stacktrace);  // 에러 스택트레이스도 출력
      _address = '주소 오류';
      _keyword = '키워드 오류';
      notifyListeners();
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
          .eq('marker_id', _marker.markerId.value);

      await supabase
          .from('bookmarks')
          .delete()
          .eq('user_id', user.id)
          .eq('marker_id', _marker.markerId.value);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('마커가 삭제되었습니다.')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MapSampleView()),
        ModalRoute.withName('/'),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.toString()}')),
      );
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
    _titleController.dispose();
    super.dispose();
  }

void openGoogleMaps(BuildContext context) async {
    //위치 권한 요청
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // 현재 위치 가져오기
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=${_marker.position.latitude},${_marker.position.longitude}');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      throw 'Could not open Google maps.';
    }
  }

  void openKakaoMap(BuildContext context) async {
    try {
      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double userLat = position.latitude;
      double userLng = position.longitude;

      // 카카오 맵 URL 생성
      final String kakaoMapUrl = Platform.isAndroid
          ? 'kakaomap://route?sp=$userLat,$userLng&ep=${_marker.position.latitude},${_marker.position.longitude}&by=CAR'
          : 'kakaomap://route?sp=$userLat,$userLng&ep=${_marker.position.latitude},${_marker.position.longitude}&by=CAR';

      final Uri kakaoMapUri = Uri.parse(kakaoMapUrl);

      // 카카오맵 실행 시도
      if (await canLaunchUrl(kakaoMapUri)) {
        await launchUrl(kakaoMapUri);
      } else {
        // 앱이 설치 되어 있지 않으면 카카오맵 설치 페이지로 이동
        final Uri kakaoMapInstallUrl = Platform.isIOS
            ? Uri.parse(
            'https://apps.apple.com/kr/app/id304608425') // iOS 앱 스토어 URL
            : Uri.parse(
            'https://play.google.com/store/apps/details?id=net.daum.android.map');
        if (await canLaunchUrl(kakaoMapInstallUrl)) {
          await launchUrl(kakaoMapInstallUrl);
        } else {
          throw 'Could not open Kakao Map.';
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 네이버 앱 실행
  void openNaverMap(BuildContext context) async {
    try {
      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double userLat = position.latitude;
      double userLng = position.longitude;

      // 네이버 맵 URL 생성
      final String naverMapUrl = Platform.isAndroid
          ? 'nmap://route/car?slat=$userLat&slng=$userLng&sname=Current%20Location&dlat=${_marker.position.latitude}&dlng=${_marker.position.longitude}&dname=Destination'
          : 'nmap://route/car?slat=$userLat&slng=$userLng&sname=Current%20Location&dlat=${_marker.position.latitude}&dlng=${_marker.position.longitude}&dname=Destination';

      final Uri naverMapUri = Uri.parse(naverMapUrl);

      // 네이버맵 실행 시도
      if (await canLaunchUrl(naverMapUri)) {
        await launchUrl(naverMapUri);
      } else {
        // 앱이 설치 되어 있지 않으면 네이버맵 설치 페이지로 이동
        final Uri naverMapInstallUrl = Platform.isIOS
            ? Uri.parse(
            'https://apps.apple.com/kr/app/id311867728') // iOS 앱 스토어 URL
            : Uri.parse(
            'https://play.google.com/store/apps/details?id=com.nhn.android.nmap');
        if (await canLaunchUrl(naverMapInstallUrl)) {
          await launchUrl(naverMapInstallUrl);
        } else {
          throw 'Could not open Naver Map.';
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void openTmap(BuildContext context) async {
    try {
      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double userLat = position.latitude;
      double userLng = position.longitude;

      // 티맵 URL 생성
      final String tmapUrl = Platform.isAndroid
          ? 'tmap://route?goalLat=${_marker.position.latitude}&goalLon=${_marker.position.longitude}&startLat=$userLat&startLon=$userLng&goalName=목적지&startName=출발지'
          : 'tmap://route?goalLat=${_marker.position.latitude}&goalLon=${_marker.position.longitude}&startLat=$userLat&startLon=$userLng&goalName=목적지&startName=출발지';

      final Uri tmapUri = Uri.parse(tmapUrl);

      // 티맵 실행 시도
      if (await canLaunchUrl(tmapUri)) {
        await launchUrl(tmapUri);
      } else {
        // 앱이 설치 되어 있지 않으면 티맵 설치 페이지로 이동
        final Uri tmapInstallUrl = Platform.isIOS
            ? Uri.parse(
            'https://apps.apple.com/kr/app/t-map-t맵-대중교통-길찾기-지도-내비게이션/id431589174') // iOS 앱 스토어 URL
            : Uri.parse(
            'https://play.google.com/store/apps/details?id=com.skt.tmap.ku');

        if (await canLaunchUrl(tmapInstallUrl)) {
          await launchUrl(tmapInstallUrl);
        } else {
          throw 'Could not open Tmap.';
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}