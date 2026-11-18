import 'package:flutter/material.dart';
import '../../design/app_design.dart';

/// 표시 방식만 변경하며, 파싱과 저장에 사용하는 원본 답변은 유지합니다.
class AiAnswerText extends StatelessWidget {
  const AiAnswerText(
      {super.key, required this.text, this.hasPlaceCard = false});
  final String text;
  final bool hasPlaceCard;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final raw in text.split('\n')) {
      var line = raw.trim();
      if (line.isEmpty) continue;
      final placeHeading =
          RegExp(r'^[•*\-]\s*(?:추천 장소:\s*)?(.+?)\s*\(검증됨\)\s*$')
                  .firstMatch(line) ??
              RegExp(r'^📍\s*(.+)$').firstMatch(line) ??
              RegExp(r'^\[\s*(.+?)\s*\(검증됨\)\s*\]$').firstMatch(line);
      final title = RegExp(r'^\[([^\]]+)\]$').firstMatch(line);
      final address = RegExp(r'^[→>\-]*\s*주소\s*[:：]').hasMatch(line);
      // 주소는 카드에 표시하므로 본문에서는 생략하되, 카드가 없으면 유지합니다.
      if (address && hasPlaceCard) continue;
      final heading = placeHeading != null || title != null;
      line = placeHeading?.group(1) ?? title?.group(1) ?? line;
      if (!heading) {
        line = line.replaceFirst(RegExp(r'^[→>\-]*\s*설명\s*[:：]\s*'), '');
      }
      children.add(Padding(
        padding: EdgeInsets.only(
            bottom: heading ? AppDesign.spacing8 : AppDesign.spacing6),
        child: Text(
          line,
          style: heading
              ? AppDesign.headingSmall.copyWith(height: 1.45)
              : AppDesign.bodyLarge.copyWith(
                  fontSize: 15, color: AppDesign.primaryText, height: 1.7),
        ),
      ));
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
