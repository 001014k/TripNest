import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialUiCompatibilityBridge;
import 'package:shimmer/shimmer.dart';

import '../design/app_design.dart';

/// 데이터 로딩 중에도 실제 카드와 같은 밀도와 톤을 유지하는 공용 스켈레톤입니다.
class TravelShimmer extends StatelessWidget {
  const TravelShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialUiCompatibilityBridge(
      child: Shimmer.fromColors(
        baseColor: AppDesign.lightGray,
        highlightColor: AppDesign.cardBg,
        period: const Duration(milliseconds: 1300),
        child: child,
      ),
    );
  }
}
