import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.marker.infoWindow.title);
    _snippetController = TextEditingController(text: widget.marker.infoWindow.snippet);
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
              decoration: InputDecoration(labelText: '제목'),
            ),
            TextField(
              controller: _snippetController,
              decoration: InputDecoration(labelText: '설명'),
            ),
            SizedBox(height: 20),
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
