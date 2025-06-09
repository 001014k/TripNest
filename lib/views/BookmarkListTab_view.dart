import 'package:flutter/material.dart';
import '../views/bookmark_view.dart';
import '../views/list_view.dart';

class BookmarklisttabView extends StatefulWidget {
  final int initialIndex;

  BookmarklisttabView({Key? key, this.initialIndex = 0}) : super(key: key);


  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<BookmarklisttabView> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // 초기 인덱스 설정
  }

  // 페이지 위젯 리스트
  final List<Widget> _pages = [
    ListPage(), // 리스트 페이지
    BookmarkView(), // 북마크 페이지
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // 탭된 페이지로 전환
          });
        },
        backgroundColor: Colors.black,
        // BottomNavigationBar 배경색
        selectedItemColor: Colors.white,
        // 선택된 아이템의 색상
        unselectedItemColor: Colors.white.withOpacity(0.6),
        // 선택되지 않은 아이템의 색상
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        // 선택된 아이템 라벨의 스타일
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        // 선택되지 않은 아이템 라벨의 스타일
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '여행 리스트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: '북마크 페이지',
          ),
        ],
      ),
    );
  }
}
