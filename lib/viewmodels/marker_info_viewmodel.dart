import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../models/marker_model.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkerInfoViewModel extends ChangeNotifier {
  final String listId;
  List<MarkerModel> markers = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();

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

  void openSpotify() async {
    final query = Uri.encodeComponent(_searchController.text);
    final String spotifyUrl = 'spotify:search:$query';
    final Uri spotifyUri = Uri.parse(spotifyUrl);
    final Uri spotifyInstallUri = Uri.parse(
        'https://apps.apple.com/us/app/spotify-music-and-podcasts/id324684580');

    try {
      if (await canLaunchUrl(spotifyUri)) {
        await launchUrl(spotifyUri);
      } else {
        if (await canLaunchUrl(spotifyInstallUri)) {
          await launchUrl(spotifyInstallUri);
        } else {
          throw 'Could not open Spotify.';
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void openAppleMusic() async {
    final query = Uri.encodeComponent(_searchController.text);
    final String appleMusicUrl = 'music://search/$query';
    final Uri appleMusicUri = Uri.parse(appleMusicUrl);
    final Uri appleMusicInstallUri =
    Uri.parse('https://apps.apple.com/us/app/apple-music/id1108187390');

    try {
      if (await canLaunchUrl(appleMusicUri)) {
        await launchUrl(appleMusicUri);
      } else {
        if (await canLaunchUrl(appleMusicInstallUri)) {
          await launchUrl(appleMusicInstallUri);
        } else {
          throw 'Could not open Apple Music.';
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void openYouTubeMusic() async {
    final query = Uri.encodeComponent(_searchController.text);
    final appUri = Uri.parse('youtubemusic://search?q=$query');
    final installUri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/app/id1017492454')
        : Uri.parse(
        'https://play.google.com/store/apps/details?id=com.google.android.apps.youtube.music');

    try {
      // 앱이 설치되어 있는지 확인하지 않고 바로 실행 시도
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // 앱이 설치되지 않았거나 실행에 실패한 경우 설치 페이지로 이동
      try {
        await launchUrl(installUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        print(
            'Could not open YouTube Music or redirect to the install page: $e');
      }
    }
  }
}
