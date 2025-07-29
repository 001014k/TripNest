import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/markercreationscreen_viewmodel.dart';

class MarkerCreationScreen extends StatefulWidget {
  final LatLng initialLatLng;

  MarkerCreationScreen({required this.initialLatLng});

  @override
  _MarkerCreationScreenState createState() => _MarkerCreationScreenState();
}

class _MarkerCreationScreenState extends State<MarkerCreationScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _snippetController = TextEditingController();
  String? _selectedKeyword;
  String? _selectedListId;
  File? _image;
  String _address = '주소 불러오는 중...';

  @override
  void initState() {
    super.initState();
    _loadAddress();
    _loadUserLists();
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

  Future<void> _loadUserLists() async {
    final viewModel = Provider.of<MarkerCreationScreenViewModel>(context, listen: false);
    await viewModel.fetchUserLists();
    if (viewModel.lists.isNotEmpty) {
      setState(() {
        _selectedListId = viewModel.lists.first['id'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MarkerCreationScreenViewModel>(context);
    final List<String> keywords = viewModel.keywordIcons.keys.toList();
    final List<Map<String, dynamic>> userLists = viewModel.lists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마커 생성'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 🔹 제목
                const Text('이름', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    hintText: '마커 이름을 입력하세요',
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 설명
                const Text('설명', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _snippetController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    hintText: '간단한 설명을 입력하세요',
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 주소 표시
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _address,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🔹 리스트 선택
                const Text('리스트 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedListId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('리스트에 추가하지 않음'),
                    ),
                    ...userLists.map((list) {
                      return DropdownMenuItem<String>(
                        value: list['id'],
                        child: Text(list['name']),
                      );
                    }).toList(),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedListId = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 🔹 키워드 선택
                const Text('키워드 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedKeyword,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: keywords.map((keyword) {
                    return DropdownMenuItem<String>(
                      value: keyword,
                      child: Row(
                        children: [
                          Icon(viewModel.keywordIcons[keyword], color: Colors.grey),
                          SizedBox(width: 8),
                          Text(keyword),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedKeyword = newValue;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // 🔹 저장 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('저장하기'),
                    onPressed: () {
                      Navigator.pop(context, {
                        'title': _titleController.text,
                        'snippet': _snippetController.text,
                        'keyword': _selectedKeyword,
                        'image': _image,
                        'listId': _selectedListId,
                        'address': _address,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
