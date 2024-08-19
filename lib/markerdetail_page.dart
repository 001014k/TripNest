import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MarkerDetailPage extends StatefulWidget {
  final Marker marker;
  final Function(Marker) onSave;

  MarkerDetailPage({required this.marker, required this.onSave});

  @override
  _MarkerDetailPageState createState() => _MarkerDetailPageState();
}

class _MarkerDetailPageState extends State<MarkerDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _snippetController;
  String? _selectedKeyword;
  String? _address;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.marker.infoWindow.title);
    _snippetController =
        TextEditingController(text: widget.marker.infoWindow.snippet);

    // 좌표로 부터 주소 가져오기
    _getAddressFromCoordinates(
        widget.marker.position.latitude, widget.marker.position.longitude);
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
    _snippetController.dispose();
    super.dispose();
  }

  void _saveMarker() {
    final updatedMarker = widget.marker.copyWith(
      infoWindowParam: widget.marker.infoWindow.copyWith(
        titleParam: _titleController.text,
        snippetParam: _snippetController.text,
      ),
    );
    widget.onSave(updatedMarker);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마커 세부 사항'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: _snippetController,
              decoration: InputDecoration(labelText: '설명'),
            ),
            SizedBox(height: 20),
            _address != null
                ? Text('주소: $_address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                : CircularProgressIndicator(), // 주소를 로드 중일 때 로딩 표시
            ElevatedButton(
              onPressed: _saveMarker,
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
