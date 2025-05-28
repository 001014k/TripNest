import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../models/marker_model.dart';

class MarkerInfoViewModel extends ChangeNotifier {
  final String listId;
  List<MarkerModel> markers = [];
  bool isLoading = true;
  String? error;

  MarkerInfoViewModel({required this.listId}) {
    loadMarkers();
  }

  Future<void> loadMarkers() async {
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

      markers = snapshot.docs
          .map((doc) => MarkerModel.fromFirestore(doc.id, doc.data()))
          .toList();

      isLoading = false;
    } catch (e) {
      error = 'Failed to load markers: $e';
      isLoading = false;
    }
    notifyListeners();
  }

  Future<void> deleteMarker(String markerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(listId)
          .collection('bookmarks')
          .doc(markerId)
          .delete();

      markers.removeWhere((marker) => marker.id == markerId);
      notifyListeners();
    } catch (e) {
      error = 'Failed to delete marker: $e';
      notifyListeners();
    }
  }

  Future<String> getAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.administrativeArea}, ${place.locality}, ${place.street}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Unknown location';
  }
}
