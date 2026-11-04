import 'package:flutter/material.dart';
import '../../design/app_design.dart';
import '../places/place_keyword_icon.dart';
import '../places/place_star_rating.dart';

class HomePlaceMetadata extends StatelessWidget {
  const HomePlaceMetadata({super.key, required this.keyword, this.rating});

  final String keyword;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final label = keyword.trim().isEmpty ? '기타' : keyword.trim();
    final style = AppDesign.caption
        .copyWith(fontSize: 10, color: AppDesign.secondaryText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          ExcludeSemantics(
              child: Icon(placeKeywordIcon(label),
                  size: 13, color: AppDesign.secondaryText)),
          const SizedBox(width: 4),
          Expanded(
              child: Text(label,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
        ]),
        const SizedBox(height: 4),
        PlaceStarRating(rating: rating, textStyle: style),
      ],
    );
  }
}
