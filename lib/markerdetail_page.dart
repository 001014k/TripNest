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
  bool _isLoadingImages = false; // 로딩 상태를 나타내는 변수
  bool _isBookmarked = false; // 북마크 상태를 추적하는 변수
  List<Marker> bookmarkedMarkers = [];
  List<String> _imageUrls = []; // 사진 URL을 저장할 리스트
  final ImagePicker _picker = ImagePicker(); // ImagePicker 인스턴스 생성

  void _openGoogleMaps() async {
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
        'https://www.google.com/maps/dir/?api=1&origin=${currentPosition
            .latitude},${currentPosition.longitude}&destination=${widget.marker
            .position.latitude},${widget.marker.position.longitude}');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      throw 'Could not open Google maps.';
    }
  }

  void _openKakaoMap() async {
    try {
      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double userLat = position.latitude;
      double userLng = position.longitude;

      // 카카오 맵 URL 생성
      final String kakaoMapUrl = Platform.isAndroid
          ? 'kakaomap://route?sp=$userLat,$userLng&ep=${widget.marker.position
          .latitude},${widget.marker.position.longitude}&by=CAR'
          : 'kakaomap://route?sp=$userLat,$userLng&ep=${widget.marker.position
          .latitude},${widget.marker.position.longitude}&by=CAR';

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
  void _openNaverMap() async {
    try {
      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double userLat = position.latitude;
      double userLng = position.longitude;

      // 네이버 맵 URL 생성
      final String naverMapUrl = Platform.isAndroid
          ? 'nmap://route/car?slat=$userLat&slng=$userLng&sname=Current%20Location&dlat=${widget
          .marker.position.latitude}&dlng=${widget.marker.position
          .longitude}&dname=Destination'
          : 'nmap://route/car?slat=$userLat&slng=$userLng&sname=Current%20Location&dlat=${widget
          .marker.position.latitude}&dlng=${widget.marker.position
          .longitude}&dname=Destination';

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

  @override
  void initState() {
    super.initState();
    _marker = widget.marker;
    _titleController = TextEditingController(text: widget.marker.infoWindow.title);
    _isLoadingImages = true; // 이미지를 로드하기 시작할 때 로딩 상태를 설정
    _loadImages(); // 이미지를 로드하는 메서드 호출
    _keyword = widget.keyword;

    // 좌표로 부터 주소 가져오기
    _getAddressFromCoordinates(
      widget.marker.position.latitude,
      widget.marker.position.longitude,
    );

    //초기 상태에서 북마크 여부확인
    _checkIfBookmarked();
    // 사진 로드
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoadingImages = true; // 이미지 로드 시작 시 로딩 상태 설정
    });

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
        setState(() {
          _imageUrls = urls;
        });
      } else {
        print('No user is logged in.');
        setState(() {
          _imageUrls = []; // 사용자 정보가 없을 때는 빈 목록으로 설정
        });
      }
    } catch (e) {
      print('Error loading images: $e');
      // 오류 발생 시 사용자에게 알림을 표시하거나 로그를 남기는 등의 처리
    } finally {
      setState(() {
        _isLoadingImages = false; // 이미지 로드 완료 후 로딩 상태 해제
      });
    }
  }


  Future<void> _pickImage() async {
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

          setState(() {
            _imageUrls.add(downloadUrl);
          });

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

  Future<void> _getAddressFromCoordinates(double latitude,
      double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _address =
          ' ${placemark.administrativeArea ?? ''} ${placemark.locality ?? ''} ${placemark.street ?? ''}';
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
      } catch (e) {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54, // 버튼의 배경색을 흰색으로 설정
                ),
                onPressed: _openGoogleMaps,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.directions, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      '구글맵',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(), //구분선 추가
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54, // 버튼의 배경색을 흰색으로 설정
                ),
                onPressed: _openKakaoMap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.directions, color: Colors.yellowAccent),
                    SizedBox(width: 8),
                    Text(
                      '카카오맵',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(), // 구분선 추가
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54, // 버튼의 배경색을 흰색으로 설정
                ),
                onPressed: _openNaverMap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.directions, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      '네이버맵',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
            itemBuilder: (context) =>
            [
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
              height: 2, // 언더바의 두께
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
                Icon(Icons.location_on, color: Colors.red), // 주소 옆에 아이콘 추가
                SizedBox(width: 8),
                Text('$_address',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
                : CircularProgressIndicator(), // 주소를 로드 중일 때 로딩 표시
            SizedBox(height: 20), // 버튼 사이의 여백
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      // 버튼 간의 간격을 균등하게 분배
                      children: [
                        ElevatedButton(
                          onPressed: _showBottomSheet,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // 모서리를 직각으로 설정
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            // 텍스트와 아이콘의 크기에 맞게 버튼 크기 조정
                            children: [
                              Icon(Icons.directions, color: Colors.black),
                              SizedBox(width: 8), // 아이콘과 텍스트 사이의 간격
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
                    ),
                    SizedBox(height: 20),
                    // 사진 표시 부분
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '저장한 사진',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          _isLoadingImages
                              ? Center(
                            child: CircularProgressIndicator(), // 로딩 인디케이터
                          )
                              : _imageUrls.isEmpty
                              ? Text('사진이 없습니다.')
                              : Container(
                            height: 200, // 슬라이더 높이 설정
                            child: PageView.builder(
                              itemCount: _imageUrls.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () async {
                                    // 전체 화면에서 이미지 보기
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ImageViewPage(
                                          imageUrls: _imageUrls,
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
                                    // result가 true일 경우 이미지를 다시 로드
                                    if (result == true) {
                                      _loadImages(); // 이미지를 다시 불러오는 함수
                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 10.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(_imageUrls[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    constraints: BoxConstraints.expand(), // 세로로 꽉 차도록 설정
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // 버튼의 배경색을 흰색으로 설정
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Colors.black, // 아이콘 색상을 검은색으로 설정
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '사진 추가',
                                  style: TextStyle(
                                    color: Colors.black, // 텍스트 색상을 검은색으로 설정
                                    fontWeight: FontWeight.bold, // 텍스트를 볼드체로 설정
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ImageViewPage extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  ImageViewPage({required this.imageUrls, required this.initialIndex});

  Future<void> _deleteImage(String imageUrl, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Firestore에서 이미지 URL 삭제
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('marker_images')
            .where('url', isEqualTo: imageUrl)
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        // Firebase Storage에서 이미지 삭제
        final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();

        // 로컬 리스트에서 이미지 삭제
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진이 삭제되었습니다.')),
        );
        Navigator.pop(context,true); // 이미지 뷰어 페이지 종료
      } catch (e) {
        print('Error deleting image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 삭제 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('이미지 보기'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              final currentIndex = (ModalRoute.of(context)?.settings.arguments as int?) ?? 0;
              final imageUrl = imageUrls[currentIndex];
              _deleteImage(imageUrl, context);
            },
          ),
        ],
      ),
      body: PageView.builder(
        itemCount: imageUrls.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: Image.network(imageUrls[index]),
            ),
          );
        },
      ),
    );
  }
}
