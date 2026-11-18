import 'package:flutter/material.dart';

class HomeDateStrip extends StatelessWidget {
  const HomeDateStrip(
      {super.key,
      required this.start,
      required this.selected,
      required this.onSelect,
      required this.onPickMonth});
  final DateTime start, selected;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onPickMonth;

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          const Expanded(
              child: Text('다가오는 일정',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22))),
          PopupMenuButton<int>(
            tooltip: '월 선택',
            position: PopupMenuPosition.under,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            constraints: const BoxConstraints(minWidth: 112, maxHeight: 320),
            onSelected: onPickMonth,
            itemBuilder: (_) => List.generate(12, (index) {
              final month = index + 1;
              return PopupMenuItem<int>(
                  value: month,
                  child: Row(children: [
                    Expanded(child: Text('$month월')),
                    if (selected.month == month)
                      const Icon(Icons.check, size: 18),
                  ]));
            }),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${selected.month}월',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333338))),
                    const Icon(Icons.keyboard_arrow_down, size: 17),
                  ])),
            ),
          ),
        ]),
        SizedBox(
            height: 62 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
            child: ListView.builder(
                key: ValueKey(start),
                scrollDirection: Axis.horizontal,
                itemCount: 31,
                itemBuilder: (context, index) {
                  final date =
                      DateTime(start.year, start.month, start.day + index);
                  final active = DateUtils.isSameDay(date, selected);
                  final color = active
                      ? const Color(0xFF171719)
                      : date.weekday == DateTime.saturday
                          ? const Color(0xFF5DAFD0)
                          : date.weekday == DateTime.sunday
                              ? const Color(0xFFD46B76)
                              : const Color(0xFF3C3C42);
                  return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 3),
                      child: Semantics(
                          selected: active,
                          button: true,
                          label: '${date.month}월 ${date.day}일',
                          child: Material(
                              color: active ? Colors.white : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: active
                                    ? const BorderSide(color: Color(0xFFE0E0E5))
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                  onTap: () => onSelect(date),
                                  borderRadius: BorderRadius.circular(22),
                                  child: SizedBox(
                                      width:
                                          ((MediaQuery.sizeOf(context).width -
                                                          40) /
                                                      7 -
                                                  6)
                                              .clamp(32.0, 80.0),
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                [
                                                  '월',
                                                  '화',
                                                  '수',
                                                  '목',
                                                  '금',
                                                  '토',
                                                  '일'
                                                ][date.weekday - 1],
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: color)),
                                            const SizedBox(height: 4),
                                            Text('${date.day}',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: color)),
                                          ]))))));
                })),
      ]);
}
