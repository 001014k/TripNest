import 'package:flutter/material.dart';
import '../places/address_photo_preview.dart';
import '../places/place_keyword_icon.dart';

class RouteOrderPlace {
  const RouteOrderPlace(
      {required this.id,
      required this.title,
      required this.address,
      required this.keyword});
  final String id, title, address, keyword;
}

class RouteOrderSheet extends StatefulWidget {
  const RouteOrderSheet(
      {super.key,
      required this.places,
      required this.controller,
      required this.onReorder,
      required this.onPlace,
      required this.onMap,
      required this.onBack,
      required this.onStart});
  final List<RouteOrderPlace> places;
  final ScrollController controller;
  final void Function(int, int) onReorder;
  final ValueChanged<String> onPlace;
  final VoidCallback onMap, onBack, onStart;
  @override
  State<RouteOrderSheet> createState() => _RouteOrderSheetState();
}

class _RouteOrderSheetState extends State<RouteOrderSheet> {
  bool _showTip = true;
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        const SizedBox(height: 16),
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xffe3e3e7),
                borderRadius: BorderRadius.circular(4))),
        Expanded(
            child: ReorderableListView.builder(
                scrollController: widget.controller,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                header: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Expanded(
                                child: Text('경로 순서',
                                    style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.7))),
                            TextButton.icon(
                                onPressed: widget.onMap,
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: const Color(0xfff3f3f4),
                                    shape: const StadiumBorder()),
                                icon:
                                    const Icon(Icons.route_outlined, size: 20),
                                label: const Text('지도에서 보기',
                                    style: TextStyle(fontSize: 13)))
                          ]),
                          const SizedBox(height: 7),
                          Text('${widget.places.length}개의 장소를 방문할 순서를 정해보세요.',
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xff898992))),
                          if (_showTip) ...[
                            const SizedBox(height: 18),
                            Container(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 14, 4, 14),
                                decoration: BoxDecoration(
                                    color: const Color(0xfff0f0f2),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Row(children: [
                                  const CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.touch_app_outlined,
                                          color: Colors.black)),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text('드래그하여 순서 변경',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700)),
                                        SizedBox(height: 4),
                                        Text('카드를 길게 눌러 원하는 순서로 움직일 수 있어요.',
                                            style: TextStyle(
                                                fontSize: 12,
                                                height: 1.4,
                                                color: Color(0xff898992)))
                                      ])),
                                  IconButton(
                                      tooltip: '안내 닫기',
                                      onPressed: () =>
                                          setState(() => _showTip = false),
                                      icon: const Icon(Icons.close,
                                          size: 20, color: Color(0xff9999a1)))
                                ]))
                          ],
                        ])),
                itemCount: widget.places.length,
                onReorderItem: widget.onReorder,
                itemBuilder: (context, index) {
                  final place = widget.places[index];
                  final color = switch (place.keyword) {
                    '카페' => const Color(0xff957656),
                    '음식점' || '맛집' => const Color(0xffa36363),
                    '전시회' => const Color(0xff498b7d),
                    '사진' || '야경' => const Color(0xff8070ad),
                    _ => const Color(0xff557f9a)
                  };
                  return ReorderableDelayedDragStartListener(
                      key: ValueKey(place.id),
                      index: index,
                      child: IntrinsicHeight(
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            SizedBox(
                                width: 34,
                                child: Column(children: [
                                  const SizedBox(height: 23),
                                  Container(
                                      width: 28,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: index == 0
                                              ? const Color(0xff202020)
                                              : const Color(0xffebebee)),
                                      child: Text('${index + 1}',
                                          style: TextStyle(
                                              color: index == 0
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.w600))),
                                  if (index < widget.places.length - 1)
                                    const Expanded(
                                        child: CustomPaint(
                                            painter: _DottedRoute(),
                                            child: SizedBox(width: 2)))
                                ])),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            side: const BorderSide(
                                                color: Color(0xffededf0))),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                            onTap: () =>
                                                widget.onPlace(place.id),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Row(children: [
                                                  ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              11),
                                                      child: SizedBox(
                                                          width: 58,
                                                          height: 62,
                                                          child:
                                                              AddressPhotoPreview(
                                                                  address: place
                                                                      .address,
                                                                  title: place
                                                                      .title,
                                                                  size: 62))),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                        Text(place.title,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 15)),
                                                        const SizedBox(
                                                            height: 5),
                                                        Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              const Icon(
                                                                  Icons
                                                                      .location_on_outlined,
                                                                  size: 13,
                                                                  color: Color(
                                                                      0xff898992)),
                                                              const SizedBox(
                                                                  width: 3),
                                                              Expanded(
                                                                  child: Text(
                                                                      place
                                                                          .address,
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              11,
                                                                          color:
                                                                              Color(0xff898992))))
                                                            ]),
                                                        const SizedBox(
                                                            height: 5),
                                                        Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        7,
                                                                    vertical:
                                                                        3),
                                                            decoration: BoxDecoration(
                                                                color: color
                                                                    .withValues(
                                                                        alpha:
                                                                            .12),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20)),
                                                            child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                      placeKeywordIcon(
                                                                          place
                                                                              .keyword),
                                                                      size: 12,
                                                                      color:
                                                                          color),
                                                                  const SizedBox(
                                                                      width: 4),
                                                                  Flexible(
                                                                      child: Text(
                                                                          place
                                                                              .keyword,
                                                                          overflow: TextOverflow
                                                                              .ellipsis,
                                                                          style: TextStyle(
                                                                              color: color,
                                                                              fontSize: 10)))
                                                                ]))
                                                      ])),
                                                  ReorderableDragStartListener(
                                                      index: index,
                                                      child: const Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 18),
                                                          child: Icon(
                                                              Icons.drag_handle,
                                                              size: 21,
                                                              color: Color(
                                                                  0xffaaaab2)))),
                                                ]))))))
                          ])));
                })),
        SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(children: [
                  Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back, size: 20),
                          label: const Text('뒤로가기'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xff4e4e56),
                              minimumSize: const Size.fromHeight(54),
                              side: const BorderSide(color: Color(0xffe4e4e9)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17))))),
                  const SizedBox(width: 10),
                  Expanded(
                      flex: 5,
                      child: FilledButton.icon(
                          onPressed:
                              widget.places.isEmpty ? null : widget.onStart,
                          icon: const Icon(Icons.near_me, size: 20),
                          label: const Text('방문 순서로 지도 보기'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff202020),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17)))))
                ]))),
      ]));
}

class _DottedRoute extends CustomPainter {
  const _DottedRoute();
  @override
  void paint(Canvas canvas, Size size) {
    for (double y = 5; y < size.height; y += 6) {
      canvas.drawCircle(Offset(size.width / 2, y), 1,
          Paint()..color = const Color(0xffcfcfd6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
