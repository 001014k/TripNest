import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkPage extends StatelessWidget {
  Future<List<Marker>> loadBookmarks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks');

      final snapshot = await userMarkersCollection.get();
      return snapshot.docs.map((doc) {
        //필드가 없을 경우 대비하여 기본값 설정
        String title = doc.data().containsKey('title') ? doc ['title'] : '이름 없음';
        String keyword = doc.data().containsKey('keyword') ? doc ['keyword'] : '키워드 없음';
        String address = doc.data().containsKey('address') ? doc ['address'] : '주소 없음';

        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(doc['lat'], doc['lng']),
          infoWindow: InfoWindow(
            title: title, // 마커이름을 title로 사용
            snippet: '$keyword\n$address', //키워드와 주소를 snippet으로 사용
          ),
        );
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('북마크 목록'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: FutureBuilder<List<Marker>>(
        future: loadBookmarks(), // 직접 Firestore에서 북마크 불러오기
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
                title: Text(marker.infoWindow.title ?? '이름 없음'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('키워드: ${marker.infoWindow.snippet?.split('\n')[0] ?? '키워드 없음'}'),
                    Text('주소: ${marker.infoWindow.snippet?.split('\n')[1] ?? '주소 없음'}'),
                  ],
                ),
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
