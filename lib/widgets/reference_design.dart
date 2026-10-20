import 'package:flutter/material.dart';
import 'address_photo_preview.dart';

/// Measurements are logical pixels, relative to the 390px reference viewport.
class ReferenceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool dashed;
  const ReferenceCard(
      {super.key,
      required this.child,
      this.dashed = false,
      this.padding = const EdgeInsets.all(12)});
  @override
  Widget build(BuildContext context) => CustomPaint(
      foregroundPainter: dashed ? _ReferenceDashedBorder() : null,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: dashed ? null : Border.all(color: const Color(0xFFF0F0F2)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x07000000),
                  blurRadius: 18,
                  offset: Offset(0, 4))
            ]),
        child: Material(type: MaterialType.transparency, child: child),
      ));
}

class _ReferenceDashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5), const Radius.circular(16)));
    final paint = Paint()
      ..color = const Color(0xFFDCDCE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 9) {
        canvas.drawPath(
            metric.extractPath(start, (start + 5).clamp(0, metric.length)),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ReferenceDashedBorder oldDelegate) => false;
}

class ReferencePhoto extends StatelessWidget {
  final String title;
  final String address;
  final double width;
  final double height;
  const ReferencePhoto(
      {super.key,
      required this.title,
      this.address = '',
      required this.width,
      required this.height});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
          width: width,
          height: height,
          child: AddressPhotoPreview(
              address: address, title: title, size: height)));
}

class ReferenceSearch extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilter;
  final String hint;
  const ReferenceSearch(
      {super.key,
      required this.onChanged,
      this.onFilter,
      this.hint = '어디로 떠날까요?'});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE8E8EB)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 12,
                  offset: Offset(0, 3))
            ]),
        child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    const TextStyle(fontSize: 16, color: Color(0xFF85858B)),
                prefixIcon: const Icon(Icons.search, size: 25),
                suffixIcon: onFilter == null
                    ? null
                    : IconButton(
                        tooltip: '필터',
                        onPressed: onFilter,
                        icon: const Icon(Icons.tune, size: 22)),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16))),
      );
}

class ReferencePeople extends StatelessWidget {
  final int count;
  const ReferencePeople({super.key, required this.count});
  @override
  Widget build(BuildContext context) => Row(children: [
        if (count > 0) ...[
          SizedBox(
              width: (count.clamp(1, 3) - 1) * 16 + 24,
              height: 25,
              child: Stack(
                  children: List.generate(
                      count.clamp(1, 3),
                      (index) => Positioned(
                          left: index * 16,
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.lerp(const Color(0xFFE4E3E0),
                                    const Color(0xFFC8CBD0), index / 3),
                                border: Border.all(
                                    color: Colors.white, width: 1.5)),
                            child: const Icon(Icons.person_outline,
                                size: 17, color: Color(0xFF666970)),
                          ))))),
          const SizedBox(width: 7),
        ],
        Flexible(
            child: Text(count > 0 ? '$count명이 함께 편집 중' : '나만의 여행 리스트',
                style: const TextStyle(fontSize: 11, color: Color(0xFF85858B)),
                maxLines: 2)),
      ]);
}

class ReferenceLogo extends StatelessWidget {
  const ReferenceLogo({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
      width: 25, height: 25, child: CustomPaint(painter: _LogoPainter()));
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 25, size.height / 25);
    final paint = Paint()..color = const Color(0xFF1F1F20);
    canvas.drawPath(
        Path()
          ..moveTo(10, 3)
          ..quadraticBezierTo(12, 0, 14, 3)
          ..lineTo(23, 19)
          ..quadraticBezierTo(25, 23, 21, 23)
          ..lineTo(16, 23)
          ..quadraticBezierTo(14, 23, 13, 21)
          ..lineTo(6, 9)
          ..close(),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(5, 12)
          ..lineTo(10, 20)
          ..lineTo(8, 23)
          ..quadraticBezierTo(7, 24, 5, 24)
          ..lineTo(2, 24)
          ..quadraticBezierTo(0, 24, 1, 21)
          ..close(),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ReferenceCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final Set<int> eventDays;
  final ValueChanged<DateTime> onSelected;
  final ValueChanged<DateTime> onMonthChanged;
  const ReferenceCalendar(
      {super.key,
      required this.month,
      required this.selected,
      required this.eventDays,
      required this.onSelected,
      required this.onMonthChanged});
  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final start = first.subtract(Duration(days: first.weekday % 7));
    final count = ((first.weekday % 7 +
                    DateUtils.getDaysInMonth(month.year, month.month)) /
                7)
            .ceil() *
        7;
    return ReferenceCard(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
        child: Column(children: [
          Row(children: [
            IconButton(
                tooltip: '이전 달',
                onPressed: () =>
                    onMonthChanged(DateTime(month.year, month.month - 1)),
                icon: const Icon(Icons.chevron_left)),
            Expanded(
                child: Text('${month.year}년 ${month.month}월',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700))),
            IconButton(
                tooltip: '다음 달',
                onPressed: () =>
                    onMonthChanged(DateTime(month.year, month.month + 1)),
                icon: const Icon(Icons.chevron_right)),
          ]),
          const SizedBox(height: 8),
          Row(
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .map((day) => Expanded(
                      child: Text(day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color: day == '토'
                                  ? const Color(0xFF5DAFD0)
                                  : day == '일'
                                      ? const Color(0xFFD46B76)
                                      : const Color(0xFF85858B)))))
                  .toList()),
          const SizedBox(height: 8),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: count,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisExtent: 37),
              itemBuilder: (context, index) {
                final date = start.add(Duration(days: index));
                final active = DateUtils.isSameDay(date, selected);
                final inMonth = date.month == month.month;
                return Semantics(
                    label: '${date.month}월 ${date.day}일',
                    selected: active,
                    button: true,
                    child: InkResponse(
                        onTap: () => onSelected(date),
                        child: Center(
                            child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                    color: active
                                        ? const Color(0xFF222222)
                                        : Colors.transparent,
                                    shape: BoxShape.circle),
                                child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text('${date.day}',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: active
                                                  ? Colors.white
                                                  : inMonth
                                                      ? (date.weekday ==
                                                              DateTime.saturday
                                                          ? const Color(
                                                              0xFF5DAFD0)
                                                          : date.weekday ==
                                                                  DateTime
                                                                      .sunday
                                                              ? const Color(
                                                                  0xFFD46B76)
                                                              : const Color(
                                                                  0xFF222222))
                                                      : (date.weekday ==
                                                              DateTime.saturday
                                                          ? const Color(
                                                              0xFFB7D9E6)
                                                          : date.weekday ==
                                                                  DateTime
                                                                      .sunday
                                                              ? const Color(
                                                                  0xFFE8BDC2)
                                                              : const Color(
                                                                  0xFFB9B9BE)))),
                                      if (inMonth &&
                                          eventDays.contains(date.day))
                                        Positioned(
                                            bottom: 3,
                                            child: Container(
                                                width: 3.5,
                                                height: 3.5,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: active
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF88888E)))),
                                    ])))));
              }),
        ]));
  }
}

class ReferencePlatform extends StatelessWidget {
  final String platform;
  const ReferencePlatform({super.key, required this.platform});
  @override
  Widget build(BuildContext context) {
    final name = platform.toLowerCase();
    final instagram = name.contains('instagram');
    final naver = name.contains('naver');
    final youtube = name.contains('youtube');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: instagram
                  ? null
                  : naver
                      ? const Color(0xFF03C75A)
                      : const Color(0xFF222222),
              gradient: instagram
                  ? const LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                          Color(0xFFFFC84C),
                          Color(0xFFE92C81),
                          Color(0xFF7938C3)
                        ])
                  : null),
          child: Center(
              child: naver
                  ? const Text('N',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 12))
                  : Icon(
                      instagram
                          ? Icons.camera_alt_outlined
                          : youtube
                              ? Icons.play_arrow_rounded
                              : Icons.link,
                      size: 14,
                      color: Colors.white))),
      const SizedBox(width: 6),
      Flexible(
          child: Text(platform,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF55555B)))),
    ]);
  }
}
