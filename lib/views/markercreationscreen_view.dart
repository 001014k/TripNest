import 'dart:io';
import 'package:provider/provider.dart';
import '../viewmodels/markercreationscreen_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    _loadAddress(); // 🟡 주소를 비동기로 불러오는 메서드 호출
  }

  Future<void> _loadAddress() async {
    final viewModel = Provider.of<MarkerCreationScreenViewModel>(context, listen: false);
    final result = await viewModel.getAddressFromCoordinates(
      widget.initialLatLng.latitude,
      widget.initialLatLng.longitude,
    );
    setState(() {
      _address = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MarkerCreationScreenViewModel>(context, listen: false);
    final List<String> keywords = viewModel.keywordIcons.keys.toList();

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
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.title, color: Colors.black),
                      SizedBox(width: 2),
                      Text(
                        '이름',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )),
            ),
            TextField(
              controller: _snippetController,
              decoration: InputDecoration(
                labelText: '설명',
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '$_address',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label, color: Colors.blue),
                  SizedBox(height: 8),
                  Expanded(
                    child: DropdownButton<String>(
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
                  ),
                ],
              ),
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
              child: Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}