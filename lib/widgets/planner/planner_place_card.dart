import 'package:flutter/material.dart';
import '../../design/app_design.dart';
import '../places/address_photo_preview.dart';
import '../places/place_star_rating.dart';

class PlannerPlaceCard extends StatelessWidget {
  const PlannerPlaceCard({super.key, required this.place, required this.onAdd});
  final Map<String, dynamic> place;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final title = place['title']?.toString() ?? '장소 이름';
    final address = place['address']?.toString() ?? '';
    final rating = (place['rating'] as num?)?.toDouble();
    return LayoutBuilder(
        builder: (context, constraints) => ClipRRect(
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              child: Stack(children: [
                Positioned.fill(
                    child: AddressPhotoPreview(
                        address: address, title: title, size: double.infinity)),
                const Positioned.fill(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x10000000),
                        Color(0x66000000),
                        Color(0xF0000000)
                      ],
                      stops: [
                        0,
                        .35,
                        1
                      ]),
                ))),
                ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxWidth * .75),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDesign.spacing16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                      child: FilledButton.icon(
                                    onPressed: onAdd,
                                    style: FilledButton.styleFrom(
                                        backgroundColor: AppDesign.cardBg,
                                        foregroundColor: AppDesign.primary,
                                        minimumSize: const Size(48, 48),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppDesign.spacing16,
                                            vertical: AppDesign.spacing12),
                                        shape: const StadiumBorder()),
                                    icon: const Icon(
                                        Icons.add_location_alt_outlined,
                                        size: 20),
                                    label: const Text('지도에 추가'),
                                  )),
                                ]),
                            const Spacer(),
                            const SizedBox(height: AppDesign.spacing24),
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppDesign.headingSmall.copyWith(
                                    fontSize: 17,
                                    height: 1.3,
                                    color: AppDesign.whiteText)),
                            if (rating != null && rating.isFinite) ...[
                              const SizedBox(height: AppDesign.spacing4),
                              PlaceStarRating(
                                rating: rating,
                                starSize: 16,
                                textStyle: AppDesign.caption.copyWith(
                                  color: AppDesign.whiteText,
                                ),
                              ),
                            ],
                            if (address.isNotEmpty) ...[
                              const SizedBox(height: AppDesign.spacing4),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        color: AppDesign.whiteText, size: 14),
                                    const SizedBox(width: AppDesign.spacing4),
                                    Expanded(
                                        child: Text(address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppDesign.caption.copyWith(
                                                color: AppDesign.whiteText))),
                                  ]),
                            ],
                          ]),
                    ),
                  ),
                ),
              ]),
            ));
  }
}
