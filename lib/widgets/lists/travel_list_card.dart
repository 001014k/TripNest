import 'package:flutter/material.dart';
import '../../models/lists/list_model.dart';
import '../../design/app_design.dart';
import '../common/reference_design.dart';
import '../places/place_keyword_icon.dart';

class TravelListCard extends StatelessWidget {
  final ListModel list;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  const TravelListCard(
      {super.key,
      required this.list,
      required this.onTap,
      required this.onOpen});
  @override
  Widget build(BuildContext context) => ReferenceCard(
          child: IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            ReferencePhoto(
                title: list.coverTitle ?? list.name, width: 88, height: 120),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(list.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5))),
                    SizedBox(
                        width: 26,
                        height: 28,
                        child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: '리스트 관리',
                            onPressed: onTap,
                            icon: const Icon(Icons.more_vert,
                                size: 20, color: AppDesign.secondaryText))),
                  ]),
                  const SizedBox(height: 2),
                  Text('저장한 장소 ${list.markerCount}개',
                      style: const TextStyle(
                          fontSize: 12, color: AppDesign.secondaryText)),
                  const SizedBox(height: 6),
                  ReferencePeople(count: list.collaboratorCount + 1),
                  const SizedBox(height: 6),
                  const Spacer(),
                  Row(children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: list.keywords
                                .map((keyword) => Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 6),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFF4F4F5),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(placeKeywordIcon(keyword),
                                                  size: 14,
                                                  color: AppDesign.primaryText),
                                              const SizedBox(width: 4),
                                              Text(keyword,
                                                  style: const TextStyle(
                                                      fontSize: 11)),
                                            ]),
                                      ),
                                    ))
                                .toList()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppDesign.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label:
                          const Text('바로 보기', style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                ])),
          ])));
}
