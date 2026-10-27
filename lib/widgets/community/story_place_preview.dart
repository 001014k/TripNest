import '../../services/community/story_saved_places.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../design/map_style.dart';
import '../../models/community/community_post_model.dart';
import '../../services/places/geocoding_service.dart';
import '../../services/map/marker_icon_service.dart';
import '../../views/map/mapsample_view.dart';
import '../../navigation/app_page_route.dart';

class StoryPlacePreview extends StatefulWidget {
  const StoryPlacePreview({super.key, required this.post});
  final CommunityPost post;
  @override
  State<StoryPlacePreview> createState() => _StoryPlacePreviewState();
}

class _StoryPlacePreviewState extends State<StoryPlacePreview> {
  LatLng? _point;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final post = widget.post;
    final lat = post.placeLatitude;
    final lng = post.placeLongitude;
    LatLng? point;
    try {
      if (lat != null &&
          lng != null &&
          lat.isFinite &&
          lng.isFinite &&
          lat.abs() <= 90 &&
          lng.abs() <= 180) {
        point = LatLng(lat, lng);
      } else if (post.placeAddress?.trim().isNotEmpty == true) {
        point = await const GeocodingService()
            .findCoordinates(post.placeAddress!)
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Keep the address visible when coordinate lookup fails.
    }
    if (mounted) {
      setState(() {
        _point = point;
        _loading = false;
      });
    }
  }

  Future<void> _openMap() async {
    if (_point == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('장소 위치를 찾지 못했어요. 잠시 후 다시 눌러주세요.')));
      setState(() => _loading = true);
      await _resolve();
      return;
    }
    final post = widget.post;
    final icon = await MarkerIconService().createSearchMarker();
    if (!mounted) return;
    await Navigator.of(context).push(AppPageRoute(
      builder: (_) => MapPreviewView(initialPlace: Marker(
        markerId: MarkerId('community-place-${post.id}'),
        icon: icon,
        anchor: const Offset(.5, 44 / 48),
        position: _point!,
        infoWindow: InfoWindow(
          title: post.placeTitle ?? post.title,
          snippet: post.placeAddress ?? post.destination ?? '',
        ),
      )),
    ));
    await StorySavedPlaces.refresh();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      label: '${widget.post.placeTitle ?? widget.post.title} 지도에서 보기',
      child: Material(
          color: const Color(0xfff5f5f7),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: _loading ? null : _openMap,
              child: SizedBox(
                  height: 96,
                  child: Row(children: [
                    const SizedBox(width: 12),
                    const CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.location_on,
                            size: 21, color: Colors.black)),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(widget.post.placeTitle ?? widget.post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(widget.post.placeAddress ?? '지도에서 장소 확인하기',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: Color(0xff85858f)))
                        ])),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(Icons.chevron_right,
                            size: 19, color: Color(0xff85858f))),
                    SizedBox(
                        width: MediaQuery.sizeOf(context).width * .24,
                        height: 96,
                        child: _loading
                            ? const Center(
                                child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                            : _point == null
                                ? const ColoredBox(
                                    color: Color(0xffe9eeeb),
                                    child: Center(
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                          Icon(Icons.map_outlined,
                                              color: Color(0xff7d8880)),
                                          SizedBox(height: 4),
                                          Text('지도에서 확인',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xff7d8880)))
                                        ])))
                                : Stack(alignment: Alignment.center, children: [
                                    Positioned.fill(
                                        child: IgnorePointer(
                                            child: GoogleMap(
                                                key: ValueKey(_point),
                                                style: tripNestMapStyle,
                                                initialCameraPosition:
                                                    CameraPosition(
                                                        target: _point!,
                                                        zoom: 14),
                                                zoomControlsEnabled: false,
                                                mapToolbarEnabled: false,
                                                myLocationButtonEnabled: false,
                                                compassEnabled: false,
                                                scrollGesturesEnabled: false,
                                                zoomGesturesEnabled: false,
                                                rotateGesturesEnabled: false,
                                                tiltGesturesEnabled: false))),
                                    const IgnorePointer(
                                        child: Icon(Icons.location_on,
                                            size: 35,
                                            color: Colors.white,
                                            shadows: [
                                          Shadow(
                                              color: Colors.black26,
                                              blurRadius: 5)
                                        ])),
                                    const IgnorePointer(
                                        child: Icon(Icons.location_on,
                                            size: 29, color: Color(0xff202020)))
                                  ])),
                  ])))));
}

class StoryActionButton extends StatelessWidget {
  const StoryActionButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onPressed,
      this.color});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xffe9e9ee))),
          child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                  height: 44,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(icon,
                                size: 21,
                                color: onPressed == null
                                    ? Colors.grey
                                    : color ?? Colors.black),
                            const SizedBox(width: 5),
                            Text(label,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: onPressed == null
                                        ? Colors.grey
                                        : Colors.black))
                          ])))))));
}
