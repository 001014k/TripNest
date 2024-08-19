import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'bookmark_provider.dart'; // Firebase Firestore와의 상호작용을 위한 함수들

class BookmarkPage extends StatefulWidget {
  @override
  _BookmarkPageState createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  late Future<List<Marker>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('북마크 목록'),
      ),
      body: FutureBuilder<List<Marker>>(
        future: _bookmarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('북마크가 없습니다.'));
          }

          final markers = snapshot.data!;

          return ListView.builder(
            itemCount: markers.length,
            itemBuilder: (context, index) {
              final marker = markers[index];
              return ListTile(
                title: Text(marker.infoWindow.title ?? '제목 없음'),
                subtitle: Text('위도: ${marker.position.latitude}, 경도: ${marker.position.longitude}'),
                onTap: () {
                  // 선택한 마커에 대한 추가 작업 가능
                },
              );
            },
          );
        },
      ),
    );
  }
}
