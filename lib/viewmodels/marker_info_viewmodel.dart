import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/marker_model.dart';

class MarkerInfoViewModel extends ChangeNotifier {
  final String listId;
  List<MarkerModel> markers = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();

  final supabase = Supabase.instance.client;

  MarkerInfoViewModel({required this.listId}) {
    loadMarkers();
  }

  Future<void> loadMarkers() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('list_bookmarks')
          .select()
          .eq('list_id', listId)
          .order('sort_order', ascending: true);

      markers = (data as List)
          .map((json) => MarkerModel.fromMap(json as Map<String, dynamic>))
          .toList();

      isLoading = false;
    } catch (e) {
      error = 'Failed to load markers: $e';
      isLoading = false;
    }
    notifyListeners();
  }

  Future<void> deleteMarker(String markerId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('list_bookmarks')
          .delete()
          .eq('id', markerId)
          .eq('user_id', user.id);

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
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(installUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        print(
            'Could not open YouTube Music or redirect to the install page: $e');
      }
    }
  }
}
