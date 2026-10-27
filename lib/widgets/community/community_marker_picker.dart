import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/community/community_post_model.dart';
import '../places/address_photo_preview.dart';
import '../places/place_keyword_icon.dart';
import '../map/map_keyword_sheet.dart';

class CommunityMarkerPicker extends StatefulWidget {
  const CommunityMarkerPicker(
      {super.key, required this.markers, this.selected});
  final List<CommunityMarker> markers;
  final CommunityMarker? selected;
  @override
  State<CommunityMarkerPicker> createState() => _CommunityMarkerPickerState();
}

class _CommunityMarkerPickerState extends State<CommunityMarkerPicker> {
  CommunityMarker? _selected;
  String _query = '';
  Set<String> _categories = {};
  static const _keywords = ['카페', '음식점', '호텔', '사진', '전시회', '자연', '관광명소', '쇼핑', '체험'];
  static const _muted = Color(0xff85858f);
  static const _line = Color(0xffebebef);
  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  String _group(String? category) {
    final text = (category ?? '').trim();
    if (text == '관광지') return '관광명소';
    if (text.contains('카페')) return '카페';
    if (text.contains('맛집') || text.contains('음식') || text.contains('식당')) {
      return '음식점';
    }
    if (text.contains('호텔') || text.contains('숙소')) return '호텔';
    return text;
  }

  Future<void> _pickKeywords() async {
    FocusScope.of(context).unfocus();
    final keywords = <String>{
      ..._keywords,
      ...widget.markers.map((m) => _group(m.category)).where((c) => c.isNotEmpty),
    };
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => MapKeywordSheet(
        keywords: {for (final keyword in keywords) keyword: placeKeywordIcon(keyword)},
        selected: _categories,
      ),
    );
    if (mounted && selected != null) setState(() => _categories = selected);
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final markers = widget.markers
        .where((m) =>
            (_categories.isEmpty || _categories.contains(_group(m.category))) &&
            '${m.title} ${m.address} ${m.category ?? ''}'
                .toLowerCase()
                .contains(query))
        .toList();
    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: FractionallySizedBox(
            heightFactor: .9,
            child: Material(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                    top: false,
                    child: Column(children: [
                      const SizedBox(height: 12),
                      Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: const Color(0xffd8d8dd),
                              borderRadius: BorderRadius.circular(4))),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                          child: Row(children: [
                            const Expanded(
                                child: Text('공유할 마커 선택',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.6))),
                            IconButton.filledTonal(
                                tooltip: '닫기',
                                style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xfff1f1f3)),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close))
                          ])),
                      const Padding(
                          padding: EdgeInsets.fromLTRB(20, 4, 20, 18),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('내가 저장한 장소 중 하나를 선택해서 공유해보세요.',
                                  style: TextStyle(
                                      color: _muted,
                                      fontSize: 14,
                                      height: 1.5)))),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              decoration: InputDecoration(
                                  hintText: '저장한 장소 검색하기',
                                  hintStyle: const TextStyle(
                                      color: _muted, fontSize: 15),
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: IconButton(
                                    tooltip: '키워드 필터',
                                    onPressed: _pickKeywords,
                                    icon: Badge(
                                      isLabelVisible: _categories.isNotEmpty,
                                      label: Text('${_categories.length}'),
                                      child: Icon(Icons.tune_rounded,
                                        color: _categories.isEmpty ? _muted : Colors.black),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xfff6f6f7),
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide:
                                          const BorderSide(color: _line)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide:
                                          const BorderSide(color: _line))))),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(spacing: 6, runSpacing: 4, children: [
                            if (_categories.isEmpty)
                              const Padding(padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('전체 키워드', style: TextStyle(fontSize: 12, color: _muted))),
                            for (final keyword in _categories)
                              InputChip(
                                avatar: Icon(placeKeywordIcon(keyword), size: 16),
                                label: Text(keyword),
                                onDeleted: () => setState(() => _categories.remove(keyword)),
                              ),
                          ]),
                        ),
                      ),
                      Expanded(
                          child: markers.isEmpty
                              ? const Center(
                                  child: Text('조건에 맞는 저장한 장소가 없어요.',
                                      style: TextStyle(color: _muted)))
                              : ListView.builder(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: markers.length,
                                  itemBuilder: (context, i) =>
                                      _row(markers[i]))),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                          child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                  onPressed: _selected == null
                                      ? null
                                      : () => Navigator.pop(context, _selected),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xff202020),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(54),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18))),
                                  child: Text(
                                      '선택한 마커로 공유하기 (${_selected == null ? 0 : 1})',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600))))),
                    ])))));
  }

  Widget _row(CommunityMarker marker) {
    final selected = _selected?.id == marker.id;
    Widget fallback() => AddressPhotoPreview(
        address: marker.address, title: marker.title, size: 88);
    final url = Uri.tryParse(marker.imagePath ?? '');
    return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: selected
                        ? const Color(0xffd9d9df)
                        : Colors.transparent)),
            child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _selected = marker),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: selected
                        ? null
                        : const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Color(0xfff1f1f4)))),
                    child: Row(children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                              width: MediaQuery.sizeOf(context).width < 360
                                  ? 64
                                  : 88,
                              height: 76,
                              child: url != null &&
                                      ['https', 'http'].contains(url.scheme)
                                  ? CachedNetworkImage(
                                      imageUrl: url.toString(),
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const ColoredBox(
                                          color: Color(0xfff3f3f5)),
                                      errorWidget: (_, __, ___) => fallback())
                                  : fallback())),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(marker.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 5),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 14, color: _muted),
                                  const SizedBox(width: 3),
                                  Expanded(
                                      child: Text(marker.address,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11, color: _muted)))
                                ]),
                            if (marker.category?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: const Color(0xfff3f3f5),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(placeKeywordIcon(_group(marker.category)),
                                          size: 14, color: _muted),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(marker.category!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 11, color: _muted)),
                                      ),
                                    ],
                                  ))
                            ]
                          ])),
                      const SizedBox(width: 8),
                      Semantics(
                          checked: selected,
                          label: '${marker.title} 선택',
                          child: Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? Colors.black
                                  : const Color(0xffc7c7ce),
                              size: 24)),
                    ])))));
  }
}
