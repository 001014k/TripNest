import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<void> saveBookmark(Marker marker, String keyword) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userMarkersCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks');

    String address = await getAddressFromCoordinates(
      marker.position.latitude,
      marker.position.longitude,
    );

    await userMarkersCollection.doc(marker.markerId.value).set({
      'title': marker.infoWindow.title ?? '',
      'snippet': marker.infoWindow.snippet ?? '기본 스니펫',
      'lat': marker.position.latitude,
      'lng': marker.position.longitude,
      'address': address,
      'keyword': keyword,
    });
  }
}

Future<List<Marker>> loadBookmarks() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userMarkersCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks');

    final snapshot = await userMarkersCollection.get();
    return snapshot.docs.map((doc) {
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(doc['lat'], doc['lng']),
        infoWindow: InfoWindow(
          title: doc['title'],
          snippet: doc.data().containsKey('snippet') ? doc['snippet'] : '', // 필드 존재 여부 확인
        ),
      );
    }).toList();
  }
  return [];
}

Future<void> deleteBookmark(Marker marker) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userMarkersCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks');

    await userMarkersCollection.doc(marker.markerId.value).delete();
  }
}

Future<bool> isBookmarked(Marker marker) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userMarkersCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks');

    final doc = await userMarkersCollection.doc(marker.markerId.value).get();
    return doc.exists;
  }
  return false;
}

Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
  // 여기에 실제 지오코딩 API 호출 로직을 추가
  return '주소를 가져오는 중...';
}
