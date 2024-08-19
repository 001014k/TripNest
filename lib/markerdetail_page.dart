import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MarkerDetailPage extends StatefulWidget {
  final Marker marker;
  final Function(Marker, String) onSave;
  final Function(Marker) onDelete;
  final String keyword;

  MarkerDetailPage({
    required this.marker,
    required this.onSave,
    required this.onDelete,
    required this.keyword,
  });

  @override
  _MarkerDetailPageState createState() => _MarkerDetailPageState();
}

class _MarkerDetailPageState extends State<MarkerDetailPage> {
  late TextEditingController _titleController;
  late String? _keyword;
  String? _address;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.marker.infoWindow.title);
    _keyword = widget.keyword;

    // 좌표로 부터 주소 가져오기
    _getAddressFromCoordinates(
      widget.marker.position.latitude,
      widget.marker.position.longitude,
    );
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

  void _deleteMarker() {
    widget.onDelete(widget.marker);
    Navigator.pop(context);
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
          ],
        ),
      ),
    );
  }
}
