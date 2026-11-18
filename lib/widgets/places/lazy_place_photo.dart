import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/places/place_photo_resolver.dart';

/// PageView의 인접 페이지가 미리 생성되어도 사진 요청은 아직 보내지 않습니다.
class LazyPlacePhoto extends StatefulWidget {
  const LazyPlacePhoto(
      {super.key,
      required this.reference,
      required this.active,
      required this.placeholder,
      this.resolver});
  final String reference;
  final bool active;
  final Widget placeholder;
  final PlacePhotoResolver? resolver;

  @override
  State<LazyPlacePhoto> createState() => _LazyPlacePhotoState();
}

class _LazyPlacePhotoState extends State<LazyPlacePhoto> {
  Future<String>? _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LazyPlacePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference) _url = null;
    _load();
  }

  void _load() {
    if (widget.active) {
      _url ??= (widget.resolver ?? PlacePhotoResolver.shared)
          .resolve(widget.reference);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: _url,
        builder: (_, snapshot) => snapshot.hasData
            ? CachedNetworkImage(
                imageUrl: snapshot.data!,
                fit: BoxFit.cover,
                placeholder: (_, __) => widget.placeholder,
                errorWidget: (_, __, ___) => widget.placeholder)
            : widget.placeholder,
      );
}
