import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bookmark_provider.dart';
import 'main.dart';

class MarkerDetailPage extends StatefulWidget {
  final Marker marker;
  final Function(Marker, String) onSave;
  final Function(Marker) onDelete;
  final String keyword;
  final Function(Marker) onBookmark;

  MarkerDetailPage({
    required this.marker,
    required this.onSave,
    required this.onDelete,
    required this.keyword,
    required this.onBookmark,
  });

  @override
  _MarkerDetailPageState createState() => _MarkerDetailPageState();
}

class _MarkerDetailPageState extends State<MarkerDetailPage> {
  late TextEditingController _titleController;
  late Marker _marker;
  late String? _keyword;
  String? _address;
  bool _isBookmarked = false; // 북마크 상태를 추적하는 변수
  List<Marker> bookmarkedMarkers = [];

  void _openGoogleMaps() async {
    //위치 권한 요청
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled) {
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
        'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=${widget.marker.position.latitude},${widget.marker.position.longitude}');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      throw 'Could not open Google maps.';
    }
  }

  void _openKakaoMap() async {
    try {
      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      double userLat = position.latitude;
      double userLng = position.longitude;

      // 카카오 맵 URL 생성
      final String kakaoMapUrl = Platform.isAndroid
          ? 'kakaomap://route?sp=$userLat,$userLng&ep=${widget.marker.position.latitude},${widget.marker.position.longitude}&by=CAR'
          : 'kakaomap://route?sp=$userLat,$userLng&ep=${widget.marker.position.latitude},${widget.marker.position.longitude}&by=CAR';

      final Uri kakaoMapUri = Uri.parse(kakaoMapUrl);

      // 카카오맵 실행 시도
      if (await canLaunchUrl(kakaoMapUri)) {
        await launchUrl(kakaoMapUri);
      } else {
        // 앱이 설치 되어 있지 않으면 카카오맵 설치 페이지로 이동
        final Uri kakaoMapInstallUrl = Platform.isIOS
            ? Uri.parse('https://apps.apple.com/kr/app/id304608425') // iOS 앱 스토어 URL
            : Uri.parse('https://play.google.com/store/apps/details?id=net.daum.android.map');
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

  @override
  void initState() {
    super.initState();
    _marker = widget.marker;
    _titleController =
        TextEditingController(text: widget.marker.infoWindow.title);
    _keyword = widget.keyword;

    // 좌표로 부터 주소 가져오기
    _getAddressFromCoordinates(
      widget.marker.position.latitude,
      widget.marker.position.longitude,
    );

    //초기 상태에서 북마크 여부확인
    _checkIfBookmarked();
  }

  Future<void> deleteBookmark(Marker marker) async {
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

  Future<void> saveBookmark(Marker marker, String keyword) async {
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

  Future<List<Marker>> loadBookmarks() async {
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

  Future<void> _checkIfBookmarked() async {
    try {
      final isBookmarked = await _isMarkerBookmarked(widget.marker);
      setState(() {
        _isBookmarked = isBookmarked;
      });
    } catch (e) {
      // 오류 발생 시 기본값으로 설정
      setState(() {
        _isBookmarked = false;
      });
      print('Error checking if bookmarked: $e');
    }
  }

  Future<bool> _isMarkerBookmarked(Marker marker) async {
    return await isBookmarked(marker); // BookmarkProvider에서 정의된 메서드
  }

  void _bookmarkLocation() async {
    setState(() {
      if (_isBookmarked) {
        // 이미 북마크 되어 있는 경우 북마크 해제
        deleteBookmark(widget.marker);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크가 해제되었습니다.')),
        );
      } else {
        // 북마크 되어 있지 않은 경우 북마크 추가
        saveBookmark(widget.marker, _keyword ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크에 추가되었습니다.')),
        );
      }
      _isBookmarked = !_isBookmarked; // 북마크 상태 업데이트
    });
  }

  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _address =
              '${placemark.country ?? ''} ${placemark.administrativeArea ?? ''} ${placemark.locality ?? ''} ${placemark.street ?? ''}';
        });
      } else {
        setState(() {
          _address = '주소를 찾을 수 없습니다';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _address = '주소를 가져오는 중 오류 발생';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveMarker() {
    final updatedMarker = widget.marker.copyWith(
      infoWindowParam: widget.marker.infoWindow.copyWith(
        titleParam: _titleController.text,
      ),
    );
    widget.onSave(updatedMarker, _keyword ?? '');
    Navigator.pop(context);
  }

  Future<void> _deleteMarker() async {
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
        widget.onDelete(_marker);

        // 페이지 전환 코드
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MapSample()),
          ModalRoute.withName('/'), // 홈 화면으로 이동
        );
      } catch(e) {
        //삭제중 오류가 발생한 경우
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: ${e.toString()}')),
        );
      }
    }
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '길찾기',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _openGoogleMaps,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.directions, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      '구글맵',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(), //구분선 추가
              ElevatedButton(
                onPressed: _openKakaoMap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.directions, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      '카카오맵',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마커 세부 사항'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == '수정') {
                _saveMarker();
              } else if (value == '삭제') {
                _deleteMarker();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: '수정',
                child: Text('수정'),
              ),
              PopupMenuItem(
                value: '삭제',
                child: Text('삭제'),
              ),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
          children: [
            Row(
              children: [
                Icon(Icons.title, color: Colors.black), // 이름 옆에 아이콘 추가
                SizedBox(width: 8),
                Text(
                  widget.marker.infoWindow.title ?? '제목 없음',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
            SizedBox(height: 4),
            Container(
              height: 2, //언더바의 두께
              color: Colors.black,
              width: double.infinity, // 화면 전체 너비로 언더바 확장
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.label, color: Colors.blue), // 키워드 옆에 아이콘 추가
                SizedBox(width: 8),
                Text(
                  '$_keyword',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            _address != null
                ? Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Colors.red), // 주소 옆에 아이콘 추가
                      SizedBox(width: 8),
                      Text('$_address',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                : CircularProgressIndicator(), // 주소를 로드 중일 때 로딩 표시
            SizedBox(height: 20), // 버튼 사이의 여백
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              // 버튼간의 간격을 균등하게 분배
              children: [
                ElevatedButton(
                  onPressed: _showBottomSheet,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // 모서리를 직각으로 설정
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, //텍스트와 아이콘의 크기에 맞게 버튼 크기 조정
                    children: [
                      Icon(Icons.directions, color: Colors.black),
                      SizedBox(width: 8), //아이콘과 텍스트 사이의 간격
                      Text(
                        '길찾기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _bookmarkLocation,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // 네모난 모서리
                    ),
                    backgroundColor: _isBookmarked
                        ? Colors.grey[300]
                        : Colors.white, // 버튼 배경 색상 변경
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark,
                        color: _isBookmarked
                            ? Colors.grey
                            : Colors.black, // 아이콘 색상 변경
                      ),
                      SizedBox(width: 8),
                      Text(
                        _isBookmarked ? '북마크 해제' : '북마크', // 텍스트 변경
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isBookmarked
                              ? Colors.black
                              : Colors.black, // 텍스트 색상 변경
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
