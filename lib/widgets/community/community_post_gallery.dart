import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/community/community_post_model.dart';
import '../../services/places/address_photo_preview_service.dart';

class CommunityPostGallery extends StatefulWidget {
  const CommunityPostGallery({super.key, required this.post});
  final CommunityPost post;

  @override
  State<CommunityPostGallery> createState() => _CommunityPostGalleryState();
}

class _CommunityPostGalleryState extends State<CommunityPostGallery> {
  List<String> _photos = [];
  int _index = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cover = widget.post.placeImagePath ?? '';
    if (['http', 'https'].contains(Uri.tryParse(cover)?.scheme)) {
      _photos = [cover];
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final photos = await const AddressPhotoPreviewService().loadPhotos(
          widget.post.placeAddress ?? '', widget.post.placeTitle);
      if (!mounted) return;
      if (photos.isNotEmpty) {
        setState(() => _photos = photos.take(5).toList());
      }
    } catch (_) {
      // Retain the saved cover if place photos cannot be loaded.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _placeholder() => const ColoredBox(
    color: Color(0xFFF0F0F2),
    child: Center(child: Icon(Icons.photo_outlined, color: Colors.grey, size: 32)),
  );

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) return _placeholder();
    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        itemCount: _photos.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (_, index) => Semantics(
          label: '장소 미리보기 사진 ${index + 1}, 전체 ${_photos.length}장',
          child: CachedNetworkImage(
            imageUrl: _photos[index],
            fit: BoxFit.cover,
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _placeholder(),
          ),
        ),
      ),
      Positioned(
        right: 16,
        bottom: 34,
        child: IgnorePointer(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
          child: Text(_loading ? '장소 사진 불러오는 중' : '${_index + 1}/${_photos.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        )),
      ),
    ]);
  }
}
