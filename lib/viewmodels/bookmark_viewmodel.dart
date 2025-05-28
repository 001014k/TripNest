import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BookmarkViewmodel extends ChangeNotifier {
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
        String title = doc.data().containsKey('title') ? doc['title'] : '이름 없음';
        String keyword = doc.data().containsKey('keyword')
            ? doc['keyword']
            : '키워드 없음';
        String address = doc.data().containsKey('address')
            ? doc['address']
            : '주소 없음';

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
}
