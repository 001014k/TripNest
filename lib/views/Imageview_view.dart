import 'package:flutter/material.dart';
import '../viewmodels/Imageview_viewmodel.dart';

class ImageviewView extends StatefulWidget {
  const ImageviewView({
    Key? key,
    required this.imageUrls,
    required this.initialIndex
  }) : super(key: key);

  final List<String> imageUrls;
  final int initialIndex;

  @override
  _ImageViewPageState createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageviewView> {
  late ImageviewViewmodel _viewmodel;
  late PageController _pageController;
  late int _currentPage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('이미지 보기'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              final imageUrl = widget.imageUrls[_currentPage];
              _viewmodel.deleteImage(imageUrl, context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            itemCount: widget.imageUrls.length,
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  child: Image.network(widget.imageUrls[index]),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_currentPage + 1} / ${widget.imageUrls.length}',
                // 현재 사진 / 전체 사진 수
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}