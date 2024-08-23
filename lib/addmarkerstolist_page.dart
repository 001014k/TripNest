import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddMarkersToListPage extends StatefulWidget {
  final String listId;

  AddMarkersToListPage({required this.listId});

  @override
  _AddMarkersToListPageState createState() => _AddMarkersToListPageState();
}

class _AddMarkersToListPageState extends State<AddMarkersToListPage> {
  final Set<Marker> _markers = {}; // Firestore에서 불러온 마커들
  bool _isLoading = true; // 로딩 상태 확인용 변수
  String? _error; // 오류 메시지 저장용 변수

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  /// Firestore에서 사용자가 저장한 마커들을 불러오는 함수
  Future<void> _loadMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Firestore에서 마커 데이터를 가져옴
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('user_markers')
            .get();

        // 불러온 데이터를 _markers Set에 추가
        final markers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>; // data() 호출로 문서의 데이터를 가져옵니다

          // 데이터 검증
          final lat = data['lat'] as double?;
          final lng = data['lng'] as double?;

          if (lat == null || lng == null) {
            // lat 또는 lng 값이 없으면 마커를 생성하지 않음
            return null;
          }

          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['lat'], data['lng']),
            infoWindow: InfoWindow(
              title: data['title'] ?? 'No Title',
              snippet: data['snippet'] ?? 'No Snippet',
            ),
          );
        }).where((marker) => marker != null).cast<Marker>().toSet(); // null 필터링 및 캐스팅

        // 마커들을 로컬 상태에 추가하고 로딩 상태를 false로 변경
        setState(() {
          _markers.addAll(markers);
          _isLoading = false;
        });
      } catch (e) {
        // 데이터 로드 실패 시 오류 메시지 표시
        setState(() {
          _error = 'Failed to load markers: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 선택한 마커를 리스트에 추가하는 함수
  Future<void> _addMarkerToList(Marker marker) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(widget.listId)
          .collection('bookmarks')
          .doc(marker.markerId.value)
          .set({
        'lat': marker.position.latitude,
        'lng': marker.position.longitude,
        'title': marker.infoWindow.title,
        'snippet': marker.infoWindow.snippet,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${marker.infoWindow.title} added to list')),
      );

      // 마커를 추가한 후, true를 반환하여 MarkerInfoPage에서 새로고침을 트리거
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Markers to List'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
        itemCount: _markers.length,
        itemBuilder: (context, index) {
          final marker = _markers.elementAt(index);
          return ListTile(
            title: Text(marker.infoWindow.title ?? 'No Title'),
            onTap: () {
              _addMarkerToList(marker); // 리스트에 마커 추가
            },
          );
        },
      ),
    );
  }
}
