import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../design/app_design.dart';
import '../../models/community/community_post_model.dart';
import '../places/address_photo_preview.dart';

class CommunityPostPhoto extends StatelessWidget {
  const CommunityPostPhoto({super.key, required this.post});
  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => AddressPhotoPreview(
        address: post.placeAddress ?? '',
        title: post.placeTitle,
        size: double.infinity);
    final uri = Uri.tryParse(post.placeImagePath ?? '');
    if (uri == null || !['http', 'https'].contains(uri.scheme)) {
      return fallback();
    }
    return CachedNetworkImage(
      imageUrl: uri.toString(),
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(
          color: AppDesign.secondaryBg,
          child: Center(
              child: Icon(Icons.photo_outlined, color: AppDesign.subtleText))),
      errorWidget: (_, __, ___) => fallback(),
    );
  }
}
