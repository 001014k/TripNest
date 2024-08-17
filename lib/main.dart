import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:fluttertrip/Dashboard_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'ForgotPassword_page.dart';
import 'user_list_page.dart';
import 'SplashScreen_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'markerdetail_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/forgot_password': (context) => ForgotPasswordPage(),
        '/user_list': (context) => UserListPage(),
        '/home': (context) => MapSample(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Map<MarkerId, String> _markerKeywords = {}; //마커의 키워드 저장
  Set<Marker> _allMarkers = {}; // 모든 마커 저장
  Set<Marker> _filteredMarkers = {}; // 필터링된 마커 저장
  Set<String> _activeKeywords = {}; //활성화 된 키워드 저장
  GoogleMapController? _controller;
  Marker? _selectedMarker;
  LatLng? _pendingLatLng;
  location.LocationData? _currentLocation;
  final location.Location _location = location.Location();
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  late GoogleMapController _mapController;
  String? _result;
  List<Marker> _searchResults = [];
  CollectionReference markersCollection =
      FirebaseFirestore.instance.collection('users');
  int _selectedIndex = 0;
  final Map<String, double> keywordHues = {
    '카페': BitmapDescriptor.hueGreen,
    '호텔': BitmapDescriptor.hueBlue,
    '사진': BitmapDescriptor.hueViolet,
    '음식점': BitmapDescriptor.hueRed,
    '전시회': BitmapDescriptor.hueYellow,
  };
  String _address = 'Fetching address...'; // Default value

  static const LatLng _seoulCityHall = LatLng(37.5665, 126.9780);

  final String mapStyle = '''
  [
    {
      "featureType": "poi",
      "elementType": "labels.icon",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    }
  ]
  ''';

  void _toggleKeyword(String keyword) {
    setState(() {
      if (_activeKeywords.contains(keyword)) {
        _activeKeywords.remove(keyword);
      } else {
        _activeKeywords.add(keyword);
      }

      if (_activeKeywords.isEmpty) {
        _filteredMarkers = _allMarkers;
      } else {
        _filteredMarkers = _allMarkers.where((marker) {
          final markerKeyword =
              _markerKeywords[marker.markerId]?.toLowerCase() ?? '';
          return _activeKeywords.contains(markerKeyword);
        }).toSet();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // 구글 맵 화면으로 이동하는 경우 맵 초기화
    if (index == 0 && _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(_seoulCityHall, 15.0),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadMarkers();
  }

  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          return '${placemark.country ?? ''} ${placemark.administrativeArea ?? ''} ${placemark.locality ?? ''} ${placemark.street ?? ''}';
      }
      return 'Unknown Address';
    } catch (e) {
      print('Error getting address: $e');
      return 'Error fetching address'; // Error message
    }
  }

  Future<void> _loadMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_markers');

      final QuerySnapshot querySnapshot = await userMarkersCollection.get();
      setState(() {
        _markers.clear();
        _allMarkers.clear();
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final hue = data['hue'] != null
              ? (data['hue'] as num).toDouble()
              : BitmapDescriptor.hueOrange; // 기본값은 Orange

          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['lat'], data['lng']),
            infoWindow: InfoWindow(
              title: data['title'],
              snippet: data['snippet'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            onTap: () {
              _onMarkerTapped(context, MarkerId(doc.id));
            },
          );
          _markers.add(marker);
          _allMarkers.add(marker); //모든 마커 저장
          _markerKeywords[marker.markerId] = data['keyword'] ?? '';
        }
        _filteredMarkers = _allMarkers; //초기 상태에서 모든 마커 표시
      });
    }
  }

  Future<void> _showMarkersInVisibleRegion() async {
    if (_controller == null) return;
    LatLngBounds bounds = await _controller!.getVisibleRegion();

    setState(() {
      _filteredMarkers = _allMarkers.where((marker) {
        return bounds.contains(marker.position);
      }).toSet();
    });
  }

  void onEdit(Marker updatedMarker) {
    setState(() {
      // 기존 마커를 업데이트
      _markers.removeWhere((m) => m.markerId == updatedMarker.markerId);
      _markers.add(updatedMarker);
      _allMarkers.removeWhere((m) => m.markerId == updatedMarker.markerId);
      _allMarkers.add(updatedMarker);
    });

    // Firebase Firestore에 수정된 마커 정보 업데이트
    final keyword = _markerKeywords[updatedMarker.markerId] ?? 'default';
    final hue = keywordHues[keyword] ?? BitmapDescriptor.hueOrange;
    _updateMarker(updatedMarker, keyword, hue);
  }

  // 파이어베이스: 'set' vs 'update'
  // set: 기존 문서를 덮어 쓰거나 문서가 없을 경우 새로 생성
  // update: 문서가 이미 존재하는 경우에만 특정 필드를 수정하며 문서가 존재하지 않으면 에러를 발생

  // 새 마커 생성
  Future<void> _saveMarker(Marker marker, String keyword, double hue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_markers');

      // 좌표로부터 주소를 가져온다
      String address = await _getAddressFromCoordinates(
        marker.position.latitude,
        marker.position.longitude,
      );

      await userMarkersCollection.doc(marker.markerId.value).set({
        'title': marker.infoWindow.title,
        'snippet': marker.infoWindow.snippet,
        'lat': marker.position.latitude,
        'lng': marker.position.longitude,
        'address': address,
        'keyword': keyword,
        'hue': hue,
      });
    }
  }

  // 기존 마커 수정
  Future<void> _updateMarker(
      Marker updatedMarker, String keyword, double hue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_markers');

      await userMarkersCollection.doc(updatedMarker.markerId.value).update({
        'title': updatedMarker.infoWindow.title,
        'snippet': updatedMarker.infoWindow.snippet,
        'keyword': keyword,
        'hue': hue,
      });
    }
  }

  Future<void> _deleteMarker(Marker marker) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_markers');
      await userMarkersCollection.doc(marker.markerId.value).delete();

      setState(() {
        _markers.remove(marker);
        _allMarkers.remove(marker);
        _filteredMarkers = _filteredMarkers
            .where((m) => m.markerId != marker.markerId)
            .toSet();
      });
    }
  }

  Future<Uint8List> _bitmapDescriptorToBytes(
      BitmapDescriptor descriptor) async {
    // BitmapDescriptor를 바이트로 변환하는 로직을 추가해야 합니다.
    return Uint8List(0);
  }

  Future<Uint8List> _fileToBytes(File file) async {
    return file.readAsBytes();
  }

  Future<void> _getLocation() async {
    final hasPermission = await _location.hasPermission();
    if (hasPermission == location.PermissionStatus.denied) {
      final requested = await _location.requestPermission();
      if (requested != location.PermissionStatus.granted) {
        // 권한이 없을 때 처리
        return;
      }
    }
    _currentLocation = await _location.getLocation();
    _location.onLocationChanged.listen((location.LocationData locationData) {
      setState(() {
        _currentLocation = locationData;
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  void _moveToCurrentLocation() {
    if (_controller != null && _currentLocation != null) {
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentLocation!.latitude!,
              _currentLocation!.longitude!,
            ),
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _onMarkerTapped(BuildContext context, MarkerId markerId) {
    final marker = _markers.firstWhere(
      (m) => m.markerId == markerId,
      orElse: () => throw Exception('Marker not found for ID: $markerId'),
    );
    setState(() {
      _selectedMarker = marker;
    });
    _showMarkerInfoBottomSheet(context, marker);
  }

  void _onMapTapped(BuildContext context, LatLng latLng) {
    setState(() {
      _pendingLatLng = latLng;
    });
    _navigateToMarkerCreationScreen(context, latLng);
  }

  void _navigateToMarkerCreationScreen(BuildContext context, LatLng latLng) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => MarkerCreationScreen(initialLatLng: latLng),
      ),
    );

    if (result != null && _pendingLatLng != null) {
      final keyword = result['keyword'] ?? 'default'; //키워드가 없을 경우 기본값 설정
      _addMarker(
          result['title'],
          result['snippet'], // String? 타입
          _pendingLatLng!, // LatLng 타입
          keyword // String 타입
          );
      _pendingLatLng = null;
    }
  }

  void _showMarkerInfoBottomSheet(BuildContext context, Marker marker) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => MarkerInfoBottomSheet(
        marker: marker,
        onEdit: (updatedMarker) {
          setState(() {
            // 기존 마커를 리스트에서 제거하고 업데이트된 마커를 추가
            _markers.removeWhere((m) => m.markerId == marker.markerId);
            _markers.add(updatedMarker);
            // 검색 결과 갱신
            _updateSearchResults(_searchController.text);
          });
          // Firestore에 수정된 마커를 반영
          final keyword = _markerKeywords[updatedMarker.markerId] ?? 'default';
          final hue = keywordHues[keyword] ?? BitmapDescriptor.hueOrange;
          _updateMarker(updatedMarker, keyword, hue);
        },
        onDelete: () {
          setState(() {
            _markers.remove(marker);
            _deleteMarker(marker);
            _updateSearchResults(_searchController.text);
          });
          Navigator.pop(context); // Close the bottom sheet
        },
      ),
    );
  }

  void _addMarker(
      String? title, String? snippet, LatLng position, String keyword) {
    final hue =
        keywordHues[keyword] ?? BitmapDescriptor.hueOrange; // 기본값은 Orange

    final markerIcon = BitmapDescriptor.defaultMarkerWithHue(hue);

    final marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: markerIcon,
      onTap: () {
        _onMarkerTapped(context, MarkerId(position.toString()));
      },
    );

    setState(() {
      _markers.add(marker);
      _allMarkers.add(marker); //모든 마커 저장
      _filteredMarkers = _allMarkers; // 모든 마커를 필터링된 마커로 설정
      _markerKeywords[marker.markerId] = keyword ?? ''; //키워드 저장
      _saveMarker(marker, keyword, hue); //키워드와 hue 값을 포함한 마커 저장
      _updateSearchResults(_searchController.text);
    });
  }

  void _onSearchSubmitted(String query) async {
    //1. 기존 마커 제목 검색기능
    setState(() {
      _searchResults = _markers.where((marker) {
        final title = marker.infoWindow.title?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();
    });

    // 2. geocoding API를 사용하여 주소반환
    try {
      List<geocoding.Location> locations =
          await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latlng = LatLng(location.latitude, location.longitude);

        //지도 위치 이동
        if (_controller != null) {
          _controller!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: latlng,
                zoom: 20, // 확대 비율
              ),
            ),
          );
        }

        setState(() {
          _searchResults = [
            Marker(
              markerId: MarkerId('searchLocation'),
              position: latlng,
              infoWindow: InfoWindow(title: query),
            )
          ];
        });
        // 모든 마커에 대한 검색을 새로 고침
        //_updateSearchResults(query);
        // 3. 검색 결과를 화면에 표시
        _showSearchResults();
      }
    } catch (e) {
      print('Erroe: $e');
    }
  }

  void _showSearchResults() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final marker = _searchResults[index];
              return ListTile(
                title: Text(marker.infoWindow.title ?? 'Untitled'),
                onTap: () {
                  Navigator.pop(context);
                  _controller?.animateCamera(
                    CameraUpdate.newLatLng(marker.position),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _updateSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
    } else {
      setState(() {
        _searchResults = _markers.where((marker) {
          final title = marker.infoWindow.title?.toLowerCase() ?? '';
          return title.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, //햄버거 아이콘 색상을 화이트 색상으로 변경
        ),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '검색...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: TextStyle(color: Colors.white),
          onChanged: _updateSearchResults,
          onSubmitted: _onSearchSubmitted,
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            color: Colors.white,
            onPressed: () => _onSearchSubmitted(_searchController.text),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/cad.png'),
              ),
              otherAccountsPictures: <Widget>[
                CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/cad.png'),
                ),
              ],
              accountName: Text('kim'),
              accountEmail: Text(
                  user != null ? user.email ?? 'No email' : 'Not logged in'),
              onDetailsPressed: () {
                print('arrow is clicked');
              },
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40.0),
                  bottomRight: Radius.circular(40.0),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.map,
                color: Colors.grey[850],
              ),
              title: Text('지도'),
              onTap: () {
                _onItemTapped(0); //구글 맵 화면으로 이동
              },
            ),
            ListTile(
              leading: Icon(
                Icons.account_circle,
                color: Colors.grey[850],
              ),
              title: Text('마이페이지'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.question_answer,
                color: Colors.grey[850],
              ),
              title: Text('Q&A'),
              onTap: () {
                print('Q&A is clicked');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _loadMarkers();
              _controller!.setMapStyle(mapStyle);
              if (_currentLocation != null) {
                _controller!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(_currentLocation!.latitude!,
                          _currentLocation!.longitude!),
                      zoom: 15,
                    ),
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentLocation?.latitude ?? _seoulCityHall.latitude,
                _currentLocation?.longitude ?? _seoulCityHall.longitude,
              ),
              zoom: 15.0,
            ),
            myLocationEnabled: true,
            // 내 위치 아이콘 표시 여부
            myLocationButtonEnabled: false,
            //GPS 버튼 비활성화
            markers: Set<Marker>.from(_filteredMarkers),
            //필터링된 마커를 사용
            onTap: (latLng) => _onMapTapped(context, latLng),
          ),
          if (_searchResults.isNotEmpty) ...[
            // 화면 하단에 검색 결과를 표시하는 기능
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final marker = _searchResults[index];
                    return ListTile(
                      title: Text(marker.infoWindow.title ?? 'Untitled'),
                      subtitle: Text(marker.infoWindow.snippet ?? ''),
                      onTap: () {
                        _controller?.animateCamera(
                          CameraUpdate.newLatLng(marker.position),
                        );
                        setState(() {
                          _selectedMarker = marker;
                        });
                        _showMarkerInfoBottomSheet(context, marker);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
          Positioned(
            top: 20.0,
            left: 0,
            right: 0,
            child: Container(
              height: 40.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: keywords.length,
                itemBuilder: (context, index) {
                  final keyword = keywords[index];
                  final isActive = _activeKeywords.contains(keyword);
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 5.0),
                    // 키워드 버튼 간격 조정
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.grey : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10),
                        // horizontal : 가로 방향에 각각 몇 픽셀의 패딩을 추가
                        // vertical: 세로 방향에 각각 몇 픽셀의 패딩을 추가 (Textstyle에 값과 비슷하게 설정할것)
                      ),
                      onPressed: () {
                        _toggleKeyword(keyword);
                      },
                      child: Text(
                        keyword,
                        style: TextStyle(
                            color: Colors.black, fontSize: 12), // 글씨 크기 조정
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _moveToCurrentLocation,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location),
                ),
                SizedBox(height: 16),
                FloatingActionButton(
                    onPressed: _showMarkersInVisibleRegion,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.place)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> keywords = ['카페', '호텔', '사진', '음식점', '전시회'];

class MarkerCreationScreen extends StatefulWidget {
  final LatLng initialLatLng;

  MarkerCreationScreen({required this.initialLatLng}); //생성자에서 LatLng 받기


  @override
  _MarkerCreationScreenState createState() => _MarkerCreationScreenState();
}

class _MarkerCreationScreenState extends State<MarkerCreationScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _snippetController = TextEditingController();
  String? _selectedKeyword; // 드롭다운 메뉴를 통해 키워드 선택
  File? _image;
  String _address = 'Fetching address...';

  @override
  void initState() {
    super.initState();
    _getAddressFromCoordinates(
      widget.initialLatLng.latitude,
      widget.initialLatLng.longitude,
    );
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
            latitude,
            longitude,
      );
      if (placemarks.isNotEmpty) {
        setState(() {
          final placemark = placemarks.first;
          _address = '${placemark.country ?? ''} ${placemark.administrativeArea ?? ''} ${placemark.locality ?? ''} ${placemark.street ?? ''}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _address = 'Error fetching address';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마커생성'),
        titleTextStyle: TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '이름',
              ),
            ),
            TextField(
              controller: _snippetController,
              decoration: InputDecoration(
                labelText: '설명',
              ),
            ),
            SizedBox(height: 16),
            Text('주소: $_address'), // 주소 표시
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedKeyword,
              hint: Text('키워드 선택'),
              items: keywords.map((String keyword) {
                return DropdownMenuItem<String>(
                  value: keyword,
                  child: Text(keyword),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedKeyword = newValue;
                });
              },
            ),
            SizedBox(height: 16.0),
            _image != null
                ? Image.file(
                    _image!,
                    height: 200,
                  )
                : Text('이미지가 선택된게 없습니다.'),
            SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: _pickImage,
              child: Text('이미지를 고르시오'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'title': _titleController.text,
                  'snippet': _snippetController.text,
                  'keyword': _selectedKeyword, // 키워드 포함
                  'image': _image,
                });
              },
              child: Text('마커 저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class MarkerInfoBottomSheet extends StatelessWidget {
  final Marker marker;
  final ValueChanged<Marker> onEdit;
  final VoidCallback onDelete;

  MarkerInfoBottomSheet({
    required this.marker,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            marker.infoWindow.title ?? 'Untitled',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
            ),
          ),
          Text(marker.infoWindow.snippet ?? ''),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final updatedMarker = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarkerDetailPage(
                          marker: marker,
                          onSave: (updatedMarker) {
                            //onSave 콜백에서 수정된 마커를 처리
                            Navigator.pop(context, updatedMarker);
                          }),
                    ),
                  );
                  if (updatedMarker != null) {
                    // 수정된 마커가 반환되면 onEdit 콜백을 호출하여 처리
                    onEdit(updatedMarker);
                  }
                },
                child: Text('수정'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: onDelete,
                child: Text('삭제'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
