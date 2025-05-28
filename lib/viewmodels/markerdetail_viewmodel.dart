import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import '../views/mapsample_view.dart';


class MarkerDetailViewmodel extends ChangeNotifier {
  late TextEditingController _titleController;
  late Marker _marker;
  late String? _keyword;
  String? address;
  bool isLoadingImages = false; // 로딩 상태를 나타내는 변수
  bool isBookmarked = false; // 북마크 상태를 추적하는 변수
  List<Marker> bookmarkedMarkers = [];
  List<String> imageUrls = []; // 사진 URL을 저장할 리스트
  final ImagePicker _picker = ImagePicker(); // ImagePicker 인스턴스 생성


  final Marker marker;
  final String keyword;
  final Function(Marker, String) onSave;
  final Function(Marker) onDelete;
  final Function(Marker) onBookmark;

  MarkerDetailViewmodel({
    required this.marker,
    required this.keyword,
    required this.onSave,
    required this.onDelete,
    required this.onBookmark,
  });


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
        'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=${marker.position.latitude},${marker.position.longitude}');
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
          ? 'kakaomap://route?sp=$userLat,$userLng&ep=${marker.position.latitude},${marker.position.longitude}&by=CAR'
          : 'kakaomap://route?sp=$userLat,$userLng&ep=${marker.position.latitude},${marker.position.longitude}&by=CAR';

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
          ? 'nmap://route/car?slat=$userLat&slng=$userLng&sname=Current%20Location&dlat=${marker.position.latitude}&dlng=${marker.position.longitude}&dname=Destination'
          : 'nmap://route/car?slat=$userLat&slng=$userLng&sname=Current%20Location&dlat=${marker.position.latitude}&dlng=${marker.position.longitude}&dname=Destination';

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
          ? 'tmap://route?goalLat=${marker.position.latitude}&goalLon=${marker.position.longitude}&startLat=$userLat&startLon=$userLng&goalName=목적지&startName=출발지'
          : 'tmap://route?goalLat=${marker.position.latitude}&goalLon=${marker.position.longitude}&startLat=$userLat&startLon=$userLng&goalName=목적지&startName=출발지';

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


  Future<void> loadImages(BuildContext context) async {
      isLoadingImages = true; // 이미지 로드 시작 시 로딩 상태 설정
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('marker_images')
            .where('markerId', isEqualTo: _marker.markerId.value)
            .get();

        final urls = snapshot.docs.map((doc) => doc['url'] as String).toList();
          imageUrls = urls;
      } else {
        print('No user is logged in.');
          imageUrls = []; // 사용자 정보가 없을 때는 빈 목록으로 설정
      }
    } catch (e) {
      print('Error loading images: $e');
      // 오류 발생 시 사용자에게 알림을 표시하거나 로그를 남기는 등의 처리
    } finally {
        isLoadingImages = false; // 이미지 로드 완료 후 로딩 상태 해제
    }
  }

  Future<void> pickImage(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('marker_images')
            .child(user.uid)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        try {
          // 이미지 읽기
          final bytes = await file.readAsBytes();
          img.Image? image = img.decodeImage(Uint8List.fromList(bytes));

          // 이미지 회전
          if (image != null) {
            image = img.copyRotate(image, 90); // 회전 각도 조절 가능

            // 이미지 비율 유지
            final width = 800; // 원하는 너비
            final height = (width * image.height) ~/ image.width;
            image = img.copyResize(image, width: width, height: height);
          }

          // 회전된 이미지를 임시 파일로 저장
          final rotatedFile = File('${file.path}_rotated.jpg')
            ..writeAsBytesSync(img.encodeJpg(image!));

          // Firebase Storage에 업로드
          await storageRef.putFile(rotatedFile);
          final downloadUrl = await storageRef.getDownloadURL();

          // Firestore에 이미지 URL 저장
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('marker_images')
              .add({
            'markerId': _marker.markerId.value,
            'url': downloadUrl,
          });
            imageUrls.add(downloadUrl);

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
    }
  }

  Future<void> deleteBookmark(BuildContext context,Marker marker) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(marker.markerId.value)
          .delete();
    }
  }

  Future<void> saveBookmark(BuildContext context,Marker marker, String keyword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(marker.markerId.value)
          .set({
        'lat': marker.position.latitude,
        'lng': marker.position.longitude,
        'title': marker.infoWindow.title,
        'keyword': keyword,
      });
    }
  }

  Future<List<Marker>> loadBookmarks(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks');

      final snapshot = await userMarkersCollection.get();
      return snapshot.docs.map((doc) {
        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(doc['lat'], doc['lng']),
          infoWindow: InfoWindow(
            title: doc['title'],
            snippet:
            doc.data().containsKey('snippet') ? doc['snippet'] : '기본 스니펫',
          ),
        );
      }).toList();
    }
    return [];
  }

  Future<void> checkIfBookmarked(BuildContext context) async {
    try {
      isBookmarked = await _isMarkerBookmarked(context,marker);
    } catch (e) {
      // 오류 발생 시 기본값으로 설정
        isBookmarked = false;
      print('Error checking if bookmarked: $e');
    }
  }

  Future<bool> _isMarkerBookmarked(BuildContext context,Marker marker) async {
    return await isBookmarked; // BookmarkProvider에서 정의된 메서드
  }

  void bookmarkLocation(BuildContext context) async {
      if (isBookmarked) {
        // 이미 북마크 되어 있는 경우 북마크 해제
        deleteBookmark(context,marker);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크가 해제되었습니다.')),
        );
      } else {
        // 북마크 되어 있지 않은 경우 북마크 추가
        saveBookmark(context,marker, _keyword ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크에 추가되었습니다.')),
        );
      }
      isBookmarked = !isBookmarked; // 북마크 상태 업데이트
  }

  Future<void> getAddressFromCoordinates(BuildContext context,
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
          address =
          ' ${placemark.administrativeArea ?? ''} ${placemark.locality ?? ''} ${placemark.street ?? ''}';
      } else {
          address = '주소를 찾을 수 없습니다';
      }
    } catch (e) {
      print('Error getting address: $e');
        address = '주소를 가져오는 중 오류 발생';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void saveMarker(BuildContext context) {
    final updatedMarker = marker.copyWith(
      infoWindowParam: marker.infoWindow.copyWith(
        titleParam: _titleController.text,
      ),
    );
    onSave(updatedMarker, _keyword ?? '');
    Navigator.pop(context);
  }

  Future<void> deleteMarker(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_markers');

      final userBookmarksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks');

      try {
        // 사용자 등록 마커 삭제
        await userMarkersCollection.doc(_marker.markerId.value).delete();

        // 사용자 북마크에서 해당 마커 삭제
        await userBookmarksCollection.doc(_marker.markerId.value).delete();

        // 성공적으로 삭제된 경우,UI를 업데이트하고 이전 페이지로 돌아가기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('마커가 삭제되었습니다.')),
        );

        // onDelete 콜백 호출
        onDelete(_marker);

        // 페이지 전환 코드
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MapSampleView()),
          ModalRoute.withName('/'), // 홈 화면으로 이동
        );
      } catch (e) {
        //삭제중 오류가 발생한 경우
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: ${e.toString()}')),
        );
      }
    }
  }
}