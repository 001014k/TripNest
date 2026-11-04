import 'package:flutter/material.dart';

/// Five stars filled proportionally to the score, with an accessible label.
class PlaceStarRating extends StatelessWidget {
  const PlaceStarRating({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 12,
    this.textStyle,
  });

  final double? rating;
  final int? reviewCount;
  final double starSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final value = rating != null && rating!.isFinite && rating! >= 0
        ? rating!.clamp(0.0, 5.0).toDouble()
        : null;
    final count = value != null && reviewCount != null && reviewCount! >= 0
        ? reviewCount
        : null;
    return Semantics(
      label: value == null
          ? '평점 없음'
          : '5점 만점에 ${value.toStringAsFixed(1)}점${count == null ? '' : ', 리뷰 $count개'}',
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 5,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (var index = 0; index < 5; index++)
                SizedBox(
                  width: starSize,
                  height: starSize,
                  child: Stack(children: [
                    Icon(Icons.star_rounded,
                        size: starSize, color: const Color(0xFFE1E2E6)),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: ((value ?? 0) - index).clamp(0.0, 1.0),
                        child: Icon(Icons.star_rounded,
                            size: starSize, color: const Color(0xFFE7A52B)),
                      ),
                    ),
                  ]),
                ),
            ]),
            Text(
                value == null
                    ? '평점 없음'
                    : '${value.toStringAsFixed(1)}${count == null ? '' : ' ($count)'}',
                style: textStyle),
          ],
        ),
      ),
    );
  }
}
