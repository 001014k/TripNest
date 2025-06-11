import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddMarkersToListViewModel extends ChangeNotifier {
  final Set<Marker> _markers = {};
  final Map<MarkerId, String> _markerKeywords = {};
  bool _isLoading = true;
  String? _error;

  Set<Marker> get markers => _markers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 해당 리스트에 이미 추가된 마커인지 여부를 반환
  bool isMarkerInList(Marker marker, String listId) {
    if (!_markersInLists.containsKey(listId)) return false;
    return _markersInLists[listId]!.contains(marker.markerId.value);
  }

  Map<String, Set<String>> _markersInLists = {};

  final Map<String, String> keywordMarkerImages = {
    '카페': 'assets/cafe_marker.png',
    '호텔': 'assets/hotel_marker.png',
    '사진': 'assets/photo_marker.png',
    '음식점': 'assets/restaurant_marker.png',
    '전시회': 'assets/exhibition_marker.png',
  };

  Future<void> loadMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('user_markers')
          .get();

      final markers = snapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final String keyword = data['keyword'] ?? 'default';
        final lat = data['lat'] as double?;
        final lng = data['lng'] as double?;

        if (lat == null || lng == null) return null;

        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: data['title'] ?? 'No Title',
            snippet: data['snippet'] ?? 'No Snippet',
          ),
        );
        _markerKeywords[marker.markerId] = keyword;
        return marker;
      })
          .where((m) => m != null)
          .cast<Marker>()
          .toSet();

      _markers.clear();
      _markers.addAll(markers);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load markers: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMarkerToList(Marker marker, String listId, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .doc(listId)
        .collection('bookmarks')
        .doc(marker.markerId.value)
        .set({
      'lat': marker.position.latitude,
      'lng': marker.position.longitude,
      'title': marker.infoWindow.title,
      'snippet': marker.infoWindow.snippet,
      'keyword': _markerKeywords[marker.markerId] ?? '',
    });

    _markersInLists.putIfAbsent(listId, () => <String>{});
    _markersInLists[listId]!.add(marker.markerId.value);

    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${marker.infoWindow.title} added to list')),
    );

    Navigator.pop(context, true);
  }

  Future<void> loadMarkersInList(String listId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(listId)
          .collection('bookmarks')
          .get();

      final markerIds = snapshot.docs.map((doc) => doc.id).toSet();

      _markersInLists[listId] = markerIds;

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load markers in list: $e';
      notifyListeners();
    }
  }
}
