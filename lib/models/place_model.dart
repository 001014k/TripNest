import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';

class Place with ClusterItem {
  final String id;
  final String title;
  final String snippet;
  final LatLng latLng;
  final BitmapDescriptor? icon;

  Place({
    required this.id,
    required this.title,
    required this.snippet,
    required this.latLng,
    this.icon,
  });

  @override
  LatLng get location => latLng;
}
