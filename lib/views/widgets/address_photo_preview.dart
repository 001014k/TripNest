import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../design/app_design.dart';
import '../../viewmodels/address_photo_preview_viewmodel.dart';

class AddressPhotoPreview extends StatefulWidget {
  final String address;
  final String? title;
  final double size;
  final Widget? child;

  const AddressPhotoPreview({
    required this.address,
    required this.title,
    required this.size,
    this.child,
    super.key,
  });

  @override
  State<AddressPhotoPreview> createState() => _AddressPhotoPreviewState();
}

class _AddressPhotoPreviewState extends State<AddressPhotoPreview> {
  late final AddressPhotoPreviewViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AddressPhotoPreviewViewModel(widget.address, widget.title);
    _vm.addListener(_updateUI); // ViewModel 변경 시 UI 갱신
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_updateUI);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_vm.isLoading) {
      return _gradientPlaceholder();
    }

    if (_vm.error != null || _vm.photoUrl == null) {
      return _gradientPlaceholder();
    }

    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: _vm.photoUrl!,
          width: double.infinity,
          height: widget.size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _gradientPlaceholder(),
          errorWidget: (_, __, ___) => _gradientPlaceholder(),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }

  Widget _gradientPlaceholder() {
    return Container(
      width: double.infinity,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
      ),
      child: const Center(
        child: Icon(Icons.place, color: Colors.white, size: 40),
      ),
    );
  }
}