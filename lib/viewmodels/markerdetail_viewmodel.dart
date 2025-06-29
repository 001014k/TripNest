import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../views/mapsample_view.dart';
import 'package:url_launcher/url_launcher.dart';


class MarkerDetailViewModel extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  final Marker _marker;
  final String _keyword;
  String? _address;

  MarkerDetailViewModel({required Marker marker, required String keyword})
      : _marker = marker,
        _keyword = keyword;

  Marker get marker => _marker;
  String get keyword => _keyword;
  String? get address => _address;

  late TextEditingController _titleController;
  bool isLoadingImages = false;
  bool isBookmarked = false;
  List<Marker> bookmarkedMarkers = [];
  List<String> imageUrls = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> loadImages(BuildContext context) async {
    isLoadingImages = true;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('marker_images')
          .select()
          .eq('user_id', user.id)
          .eq('marker_id', _marker.markerId.value);

      imageUrls = (response as List)
          .map((item) => item['url'] as String)
          .toList();
    } catch (e) {
      print('Error loading images: $e');
    } finally {
      isLoadingImages = false;
      notifyListeners();
    }
  }

  Future<void> pickImage(BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image != null) {
        image = img.copyRotate(image, 90);
        final width = 800;
        final height = (width * image.height) ~/ image.width;
        image = img.copyResize(image, width: width, height: height);
      }

      final rotatedFile = File('${file.path}_rotated.jpg')
        ..writeAsBytesSync(img.encodeJpg(image!));

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '${user.id}/$fileName';

      final storageResponse = await supabase.storage
          .from('marker-images')
          .upload(storagePath, rotatedFile);

      final publicUrl = supabase.storage
          .from('marker-images')
          .getPublicUrl(storagePath);

      await supabase.from('marker_images').insert({
        'user_id': user.id,
        'marker_id': _marker.markerId.value,
        'url': publicUrl,
      });

      imageUrls.add(publicUrl);
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진이 추가되었습니다.')),
      );
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 업로드 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> saveBookmark() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('bookmarks').upsert({
      'user_id': user.id,
      'marker_id': _marker.markerId.value,
      'lat': _marker.position.latitude,
      'lng': _marker.position.longitude,
      'title': _marker.infoWindow.title,
      'keyword': _keyword,
    });
  }

  Future<void> deleteBookmark() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('bookmarks')
        .delete()
        .eq('user_id', user.id)
        .eq('marker_id', _marker.markerId.value);
  }

  Future<void> checkIfBookmarked() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('bookmarks')
        .select()
        .eq('user_id', user.id)
        .eq('marker_id', _marker.markerId.value);

    isBookmarked = (response as List).isNotEmpty;
    notifyListeners();
  }

  Future<List<Marker>> loadBookmarks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('bookmarks')
        .select()
        .eq('user_id', user.id);

    return (response as List).map((doc) {
      return Marker(
        markerId: MarkerId(doc['marker_id']),
        position: LatLng(doc['lat'], doc['lng']),
        infoWindow: InfoWindow(
          title: doc['title'],
          snippet: doc['snippet'] ?? '기본 스니펫',
        ),
      );
    }).toList();
  }

  void toggleBookmark(BuildContext context) async {
    if (isBookmarked) {
      await deleteBookmark();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('북마크가 해제되었습니다.')),
      );
    } else {
      await saveBookmark();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('북마크에 추가되었습니다.')),
      );
    }
    isBookmarked = !isBookmarked;
    notifyListeners();
  }

  Future<void> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _address = '${p.administrativeArea ?? ''} ${p.locality ?? ''} ${p.street ?? ''}';
      } else {
        _address = '주소를 찾을 수 없습니다';
      }
    } catch (e) {
      _address = '주소를 가져오는 중 오류 발생';
    }
    notifyListeners();
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