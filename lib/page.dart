import 'package:flutter/material.dart';
import 'bookmark_page.dart';
import 'list_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0; // 현재 보여질 페이지의 인덱스

  // 페이지 위젯 리스트
  final List<Widget> _pages = [
    ListPage(),      // 리스트 페이지
    BookmarkPage(), // 북마크 페이지
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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '리스트 페이지',
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
