import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../places/address_photo_preview.dart';
import '../places/place_keyword_icon.dart';

class MarkerDeleteDialog extends StatelessWidget {
  const MarkerDeleteDialog(
      {super.key,
      required this.title,
      required this.address,
      this.imageUrl,
      this.removeFromList = false,
      this.tags = const []});
  final bool removeFromList;
  final String title, address;
  final String? imageUrl;
  final List<String> tags;
  @override
  Widget build(BuildContext context) {
    Widget photo() =>
        AddressPhotoPreview(address: address, title: title, size: 76);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                            color: Color(0xfffff1f3), shape: BoxShape.circle),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xffe65050), size: 38)),
                    const SizedBox(height: 16),
                    Text(removeFromList ? '리스트에서 장소를 뺄까요?' : '마커를 삭제할까요?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.7)),
                    const SizedBox(height: 12),
                    Text(
                        removeFromList
                            ? '이 리스트에서만 장소가 제외됩니다.\n마커와 사진·메모는 유지되며, 다시 추가할 수 있어요.'
                            : '이 마커와 연결된 데이터가 함께 삭제되며,\n이 작업은 되돌릴 수 없습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xff81818d))),
                    const SizedBox(height: 18),
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xfff6f6f8),
                            borderRadius: BorderRadius.circular(18)),
                        child: Row(children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                  width: 68,
                                  height: 76,
                                  child: imageUrl?.isNotEmpty == true
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) =>
                                              const ColoredBox(
                                                  color: Color(0xffededf0)),
                                          errorWidget: (_, __, ___) => photo())
                                      : photo())),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 15, color: Color(0xff858591)),
                                      const SizedBox(width: 3),
                                      Expanded(
                                          child: Text(
                                              address.isEmpty
                                                  ? '주소 정보 없음'
                                                  : address,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  height: 1.4,
                                                  color: Color(0xff858591))))
                                    ]),
                                if (tags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                      spacing: 5,
                                      runSpacing: 5,
                                      children: tags
                                          .toSet()
                                          .take(3)
                                          .map((tag) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xffebebf0),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20)),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                      placeKeywordIcon(tag
                                                          .replaceFirst(
                                                              RegExp(r'^#'), '')
                                                          .trim()),
                                                      size: 14,
                                                      color: const Color(
                                                          0xff777783)),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                      child: Text(
                                                          tag
                                                              .replaceFirst(
                                                                  RegExp(r'^#'),
                                                                  '')
                                                              .trim(),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              fontSize: 11,
                                                              color: Color(
                                                                  0xff777783)))),
                                                ],
                                              )))
                                          .toList())
                                ]
                              ])),
                        ])),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(
                                      color: Color(0xffd6d6de)),
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15))),
                              child: const Text('취소'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xffe24e4e),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15))),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        size: 20),
                                    SizedBox(width: 6),
                                    Flexible(
                                        child: Text(removeFromList
                                            ? '리스트에서 빼기'
                                            : '삭제하기'))
                                  ])))
                    ]),
                  ])))),
    );
  }
}
