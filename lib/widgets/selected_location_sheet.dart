import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'address_photo_preview.dart';

class SelectedLocationSheet extends StatelessWidget {
  const SelectedLocationSheet(
      {super.key,
      required this.marker,
      required this.onAdd,
      this.metadata,
      this.currentLocation});
  final Marker marker;
  final VoidCallback onAdd;
  final Map<String, dynamic>? metadata;
  final LatLng? currentLocation;

  @override
  Widget build(BuildContext context) {
    final rating = metadata?['rating'] as num?;
    final count = metadata?['userRatingCount'] as num?;
    final type =
        (metadata?['primaryTypeDisplayName'] as Map?)?['text']?.toString();
    final origin = currentLocation;
    final distance = origin == null
        ? null
        : Geolocator.distanceBetween(origin.latitude, origin.longitude,
            marker.position.latitude, marker.position.longitude);
    final subtitle = [
      if (type != null && type.isNotEmpty) type,
      if (distance != null)
        distance < 1000
            ? '${distance.round()}m'
            : '${(distance / 1000).toStringAsFixed(1)}km',
    ].join(' · ');
    return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                            color: const Color(0xFFCFD1D5),
                            borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 13),
                const Text('선택한 위치',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
                const SizedBox(height: 6),
                Text(
                    marker.infoWindow.snippet?.isNotEmpty == true
                        ? marker.infoWindow.snippet!
                        : '주소 정보 없음',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF555860), height: 1.4)),
                const SizedBox(height: 16),
                Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE8E9EC))),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                        onTap: onAdd,
                        child: Row(children: [
                          SizedBox(
                              width: 112,
                              height: 86,
                              child: AddressPhotoPreview(
                                  address: marker.infoWindow.snippet ?? '',
                                  title: marker.infoWindow.title,
                                  size: 86)),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            marker.infoWindow.title ?? '선택한 장소',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                height: 1.3)),
                                        const SizedBox(height: 5),
                                        if (rating != null)
                                          Row(children: [
                                            const Icon(Icons.star_rounded,
                                                color: Color(0xFFFF941F),
                                                size: 16),
                                            const SizedBox(width: 3),
                                            Flexible(
                                                child: Text(
                                                    '${rating.toStringAsFixed(1)}${count == null ? '' : ' (${_number(count.toInt())})'}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Color(
                                                            0xFF555860)))),
                                          ])
                                        else
                                          const Text('평점 정보 없음',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF858892))),
                                        if (subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(subtitle,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF858892))),
                                        ],
                                      ]))),
                          const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.chevron_right_rounded,
                                  color: Colors.black, size: 22)),
                        ]))),
                const SizedBox(height: 18),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: onAdd,
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF191919),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18))),
                        child: const Text('이 장소로 추가하기',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)))),
              ]),
        ));
  }

  String _number(int value) => value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
}
