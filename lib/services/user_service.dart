import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geocoding;


class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사용자 통계를 가져오는 메서드
  Future<Map<String, int>> getUserStats(String userId) async {
    final userDoc = _firestore.collection('users').doc(userId);

    final markersSnapshot = await userDoc.collection('user_markers').get();
    final markersCount = markersSnapshot.size;

    final listsSnapshot = await userDoc.collection('lists').get();
    final listsCount = listsSnapshot.size;

    final bookmarksSnapshot = await userDoc.collection('bookmarks').get();
    final bookmarksCount = bookmarksSnapshot.size;

    return {
      'markers': markersCount,
      'lists': listsCount,
      'bookmarks': bookmarksCount,
    };
  }

  Future<List<QueryDocumentSnapshot>> _getUserLists() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return [];
    }

    final listSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .get();

    return listSnapshot.docs;
  }
}

class BookmarkService {
  Future<List<Marker>> getMarkersForList(String uid, String listId, Function(MarkerId) onTap) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('lists')
        .doc(listId)
        .collection('bookmarks')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(data['lat'], data['lng']),
        infoWindow: InfoWindow(
          title: data['title'] ?? '제목 없음',
          snippet: data['snippet'] ?? '설명 없음',
        ),
        onTap: () => onTap(MarkerId(doc.id)),
      );
    }).toList();
  }
}

// services/user_list_service.dart
class UserListService {
  Future<List<QueryDocumentSnapshot>> fetchUserLists(String uid) async {
    final listSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('lists')
        .get();
    return listSnapshot.docs;
  }
}

class SearchService {
  final String apiKey;

  SearchService({required this.apiKey});

  Future<List<Marker>> searchPlacesWithQuery(String query) async {
    final url = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText?&key=$apiKey');

    final requestBody = json.encode({
      "textQuery": query,
      "languageCode": "ko",
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-FieldMask':
        'places.displayName,places.formattedAddress,places.location'
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['places'] != null && data['places'] is List) {
        return (data['places'] as List).map<Marker>((place) {
          final displayName = place['displayName']['text'];
          final formattedAddress = place['formattedAddress'];
          final lat = place['location']['latitude'];
          final lng = place['location']['longitude'];
          final placeId = place['place_id'] ?? displayName;

          return Marker(
            markerId: MarkerId(placeId),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: displayName,
              snippet: formattedAddress,
            ),
          );
        }).toList();
      }
    }
    return [];
  }

  Future<Marker?> geocodeSearch(String query) async {
    try {
      final locations = await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return Marker(
          markerId: MarkerId('searchLocation'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(title: query),
        );
      }
    } catch (_) {}
    return null;
  }
}


