import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BookmarkPage extends StatelessWidget {
  final List<Marker> bookmarks;

  BookmarkPage({required this.bookmarks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('북마크 리스트'),
      ),
      body: ListView.builder(
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          final marker = bookmarks[index];
          return ListTile(
            leading: Icon(Icons.location_pin),
            title: Text(marker.infoWindow.title ?? '제목 없음'),
            subtitle: Text(
                '위도: ${marker.position.latitude}, 경도: ${marker.position.longitude}'),
            onTap: () {
              // 해당 마커 위치로 이동하는 로직
              Navigator.pop(context, marker);
            },
          );
        },
      ),
    );
  }
}
