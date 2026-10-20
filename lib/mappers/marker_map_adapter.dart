import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/marker_model.dart';

class MarkerMapAdapter {
  const MarkerMapAdapter._();

  static Marker toGoogleMarker(MarkerModel marker) => Marker(
        markerId: MarkerId(marker.id),
        position: LatLng(marker.lat, marker.lng),
        infoWindow: InfoWindow(title: marker.title, snippet: marker.address),
      );
}
