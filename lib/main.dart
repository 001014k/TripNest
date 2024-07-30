import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
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
      },
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  GoogleMapController? _controller;
  Marker? _selectedMarker;
  LatLng? _pendingLatLng;
  LocationData? _currentLocation;
  final Location _location = Location();
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  List<Marker> _searchResults = [];
  CollectionReference markersCollection = FirebaseFirestore.instance.collection('markers');
  int _selectedIndex = 0;

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

  void _checkUserStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _loadMarkers(); // 사용자 인증 후 마커 로드
        _getLocation(); // 사용자 인증 후 위치 정보 가져오기
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _loadMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('markers')
          .doc(user.uid)
          .collection('user_markers');

      final QuerySnapshot querySnapshot = await userMarkersCollection.get();
      setState(() {
        _markers.clear();
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['lat'], data['lng']),
            infoWindow: InfoWindow(
              title: data['title'],
              snippet: data['snippet'],
            ),
            icon: data['image'] != null
                ? BitmapDescriptor.fromBytes(Uint8List.fromList(
                (data['image'] as List<dynamic>).cast<int>()))
                : BitmapDescriptor.defaultMarker,
            onTap: () {
              _onMarkerTapped(context, MarkerId(doc.id));
            },
          );
          _markers.add(marker);
        }
      });
    }
  }

  Future<void> _saveMarker(Marker marker) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('markers')
          .doc(user.uid)
          .collection('user_markers');

      await userMarkersCollection.doc(marker.markerId.value).set({
        'title': marker.infoWindow.title,
        'snippet': marker.infoWindow.snippet,
        'lat': marker.position.latitude,
        'lng': marker.position.longitude,
        'image': marker.icon != BitmapDescriptor.defaultMarker
            ? await _bitmapDescriptorToBytes(marker.icon)
            : null,
      });
    }
  }

  Future<void> _deleteMarker(Marker marker) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('markers')
          .doc(user.uid)
          .collection('user_markers');
      await userMarkersCollection.doc(marker.markerId.value).delete();
    }
  }

  Future<Uint8List> _bitmapDescriptorToBytes(BitmapDescriptor descriptor) async {
    // BitmapDescriptor를 바이트로 변환하는 로직을 추가해야 합니다.
    return Uint8List(0);
  }

  Future<Uint8List> _fileToBytes(File file) async {
    return file.readAsBytes();
  }

  Future<void> _getLocation() async {
    final hasPermission = await _location.hasPermission();
    if (hasPermission == PermissionStatus.denied) {
      final requested = await _location.requestPermission();
      if (requested != PermissionStatus.granted) {
        // 권한이 없을 때 처리
        return;
      }
    }
    _currentLocation = await _location.getLocation();
    _location.onLocationChanged.listen((LocationData locationData) {
      setState(() {
        _currentLocation = locationData;
      });
      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(locationData.latitude!, locationData.longitude!),
              zoom: 15.0,
            ),
          ),
        );
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _loadMarkers();
    _controller!.setMapStyle(mapStyle); // 스타일 적용
    if (_currentLocation != null) {
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
                _currentLocation!.latitude!, _currentLocation!.longitude!),
            zoom: 15.0,
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
    _navigateToMarkerCreationScreen(context);
  }

  void _navigateToMarkerCreationScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => MarkerCreationScreen(),
      ),
    );

    if (result != null && _pendingLatLng != null) {
      final imageBytes =
      result['image'] != null ? await _fileToBytes(result['image']) : null;
      _addMarker(
          result['title'], result['snippet'], imageBytes, _pendingLatLng!);
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
            _markers.remove(marker);
            _markers.add(updatedMarker);
            _saveMarker(updatedMarker);
            _updateSearchResults(_searchController.text);
          });
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

  void _addMarker(String? title, String? snippet, Uint8List? imageBytes,
      LatLng position) {
    final marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: imageBytes != null
          ? BitmapDescriptor.fromBytes(imageBytes)
          : BitmapDescriptor.defaultMarker,
      onTap: () {
        _onMarkerTapped(context, MarkerId(position.toString()));
      },
    );

    setState(() {
      _markers.add(marker);
      _saveMarker(marker);
      _updateSearchResults(_searchController.text);
    });
  }

  void _onSearchSubmitted(String query) {
    setState(() {
      _searchResults = _markers.where((marker){
        final title = marker.infoWindow.title?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();
    });
    _showSearchResults();
    _updateSearchResults(query);
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
        backgroundColor: Colors.blueGrey[700],
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
                backgroundImage: AssetImage('assets/profile.png'),
                backgroundColor: Colors.white,
              ),
              otherAccountsPictures: <Widget>[
                CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/profile2.png'),
                ),
              ],
              accountName: Text('kim'),
              accountEmail: Text('hm4854@email.com'),
              onDetailsPressed: () {
                print('arrow is clicked');
              },
              decoration: BoxDecoration(
                color: Colors.blueGrey[200],
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
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentLocation?.latitude ?? _seoulCityHall.latitude,
                _currentLocation?.longitude ?? _seoulCityHall.longitude,
              ),
              zoom: 15.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: Set<Marker>.from(
                _searchResults.isEmpty ? _markers : _searchResults),
            onTap: (latLng) => _onMapTapped(context, latLng),
          ),
          if (_searchResults.isNotEmpty) ...[
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
        ],
      ),
    );
  }
}

class MarkerCreationScreen extends StatefulWidget {
  @override
  _MarkerCreationScreenState createState() => _MarkerCreationScreenState();
}

class _MarkerCreationScreenState extends State<MarkerCreationScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _snippetController = TextEditingController();
  File? _image;

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
                labelText: '주소',
              ),
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
              onPressed: _pickImage,
              child: Text('이미지를 고르시오'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'title': _titleController.text,
                  'snippet': _snippetController.text,
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
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarkerCreationScreen(),
                    ),
                  );

                  if (result != null) {
                    final updatedMarker = marker.copyWith(
                      infoWindowParam: marker.infoWindow.copyWith(
                        titleParam: result['title'],
                        snippetParam: result['snippet'],
                      ),
                      iconParam: result['image'] != null
                          ? BitmapDescriptor.fromBytes(
                          await File(result['image']).readAsBytes())
                          : marker.icon,
                    );
                    onEdit(updatedMarker);
                    Navigator.pop(context);
                  }
                },
                child: Text('Edit'),
              ),
              ElevatedButton(
                onPressed: onDelete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}