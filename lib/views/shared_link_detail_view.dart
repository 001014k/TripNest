import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../design/app_design.dart';
import '../env.dart';
import '../models/shared_link_model.dart';
import '../services/places_service.dart';
import '../services/shared_link_service.dart';
import '../widgets/address_photo_preview.dart';
import 'markercreationscreen_view.dart';
import 'shared_link_view.dart';

class SharedLinkDetailView extends StatefulWidget {
  const SharedLinkDetailView({required this.link, super.key});

  final SharedLinkModel link;

  @override
  State<SharedLinkDetailView> createState() => _SharedLinkDetailViewState();
}

class _SharedLinkDetailViewState extends State<SharedLinkDetailView> {
  LinkPreviewData? _preview;
  List<SharedLinkModel> _places = const [];
  bool _isLoadingPlaces = true;
  bool _isOpeningMarkerCreation = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
    _loadPlaces();
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await getPreviewData(widget.link.url);
      if (mounted) setState(() => _preview = preview);
    } catch (_) {
      // 원본 사이트가 미리보기를 제공하지 않아도 주소 정보는 표시합니다.
    }
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await SharedLinkService().loadSharedLinkPlaces(
        widget.link.url,
      );
      if (mounted) setState(() => _places = places);
    } catch (_) {
      // Keep the record passed by the list usable if the refresh fails.
      if (mounted) setState(() => _places = [widget.link]);
    } finally {
      if (mounted) setState(() => _isLoadingPlaces = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = widget.link;
    final placesWithAddress = _places
        .where((place) => place.placeAddress?.trim().isNotEmpty ?? false)
        .toList();

    return Scaffold(
      backgroundColor: AppDesign.primaryBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _SharedPlaceHeader(
                  placeCount:
                      _isLoadingPlaces ? null : placesWithAddress.length,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _OriginalPreviewCard(
                    preview: _preview,
                    link: link,
                    onTap: _openOriginalPost,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: AppDesign.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppDesign.radiusSmall),
                        ),
                        child: const Icon(
                          Icons.place_outlined,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppDesign.spacing10),
                      Text('추출된 장소', style: AppDesign.headingMedium),
                      const SizedBox(width: AppDesign.spacing8),
                      if (!_isLoadingPlaces)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDesign.spacing8,
                            vertical: AppDesign.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: AppDesign.secondaryBg,
                            borderRadius:
                                BorderRadius.circular(AppDesign.radiusSmall),
                          ),
                          child: Text(
                            '${placesWithAddress.length}곳',
                            style: AppDesign.caption.copyWith(
                              color: AppDesign.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_isLoadingPlaces)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: AppDesign.spacing48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (placesWithAddress.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: _MissingPlaceCard()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: placesWithAddress.length,
                    itemBuilder: (context, index) {
                      final place = placesWithAddress[index];
                      return _ExtractedPlaceCard(
                        key: ValueKey(
                            place.id ?? '${place.url}-${place.placeAddress}'),
                        place: place,
                        isAdding: _isOpeningMarkerCreation,
                        onAddToMap: () => _openMarkerCreation(place),
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDesign.spacing16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openOriginalPost() async {
    final uri = Uri.tryParse(widget.link.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMarkerCreation(SharedLinkModel link) async {
    final address = link.placeAddress;
    if (address == null || address.isEmpty) return;

    setState(() => _isOpeningMarkerCreation = true);
    try {
      final position = link.placeLatitude != null && link.placeLongitude != null
          ? LatLng(link.placeLatitude!, link.placeLongitude!)
          : await _geocodeAddress(address);
      if (!mounted) return;
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주소 위치를 찾지 못했습니다.')),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MarkerCreationScreen(
            initialLatLng: position,
            initialTitle: link.placeTitle,
            initialAddress: address,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningMarkerCreation = false);
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    final response = await http.get(
      Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'address': address,
        'language': 'ko',
        'region': 'kr',
        'key': Env.googleMapsApiKey,
      }),
    );
    if (response.statusCode != 200) return null;
    final results = (jsonDecode(response.body)['results'] as List?) ?? const [];
    if (results.isEmpty) return null;
    final location = (results.first as Map)['geometry']?['location'] as Map?;
    final latitude = (location?['lat'] as num?)?.toDouble();
    final longitude = (location?['lng'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }
}

class _OriginalPreviewCard extends StatelessWidget {
  const _OriginalPreviewCard({
    required this.preview,
    required this.link,
    required this.onTap,
  });

  final LinkPreviewData? preview;
  final SharedLinkModel link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesign.cardBg,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        side: const BorderSide(color: AppDesign.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDesign.radiusMedium),
              ),
              child: SizedBox(
                height: 184,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (preview?.image != null)
                      Image.network(
                        preview!.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppDesign.lightGray,
                          child: Icon(
                            Icons.link_rounded,
                            color: AppDesign.travelBlue,
                            size: 40,
                          ),
                        ),
                      )
                    else
                      const ColoredBox(
                        color: AppDesign.lightGray,
                        child: Icon(
                          Icons.link_rounded,
                          color: AppDesign.travelBlue,
                          size: 40,
                        ),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x55000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: AppDesign.spacing12,
                      left: AppDesign.spacing12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesign.spacing10,
                          vertical: AppDesign.spacing6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius:
                              BorderRadius.circular(AppDesign.radiusSmall),
                        ),
                        child: Text(
                          '원본 링크',
                          style: AppDesign.caption.copyWith(
                            color: AppDesign.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDesign.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview?.title ?? link.placeTitle ?? link.platform,
                          style: AppDesign.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDesign.spacing12),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color: AppDesign.travelBlue,
                        size: 20,
                      ),
                    ],
                  ),
                  if (preview?.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppDesign.spacing6),
                    Text(
                      preview!.description!,
                      style: AppDesign.bodySmall.copyWith(
                        color: AppDesign.secondaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppDesign.spacing8),
                  Text(
                    Uri.tryParse(link.url)?.host ?? link.url,
                    style: AppDesign.caption.copyWith(
                      color: AppDesign.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedPlaceHeader extends StatelessWidget {
  const _SharedPlaceHeader({required this.placeCount, required this.onBack});

  final int? placeCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Material(
            color: AppDesign.cardBg,
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 19),
              ),
            ),
          ),
          const SizedBox(width: AppDesign.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SAVED LINK', style: AppDesign.overline),
                const SizedBox(height: 2),
                Text('공유한 장소', style: AppDesign.headingLarge),
              ],
            ),
          ),
          if (placeCount != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing12,
                vertical: AppDesign.spacing8,
              ),
              decoration: BoxDecoration(
                gradient: AppDesign.sunsetGradient,
                borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              ),
              child: Text(
                '$placeCount곳',
                style: AppDesign.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExtractedPlaceCard extends StatelessWidget {
  const _ExtractedPlaceCard({
    required this.place,
    required this.isAdding,
    required this.onAddToMap,
    super.key,
  });

  final SharedLinkModel place;
  final bool isAdding;
  final VoidCallback onAddToMap;

  @override
  Widget build(BuildContext context) {
    final savedTitle = place.placeTitle?.trim() ?? '';
    final title = savedTitle.isNotEmpty ? savedTitle : '이름을 확인할 수 없는 장소';
    final address = place.placeAddress!;

    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: AppDesign.softShadow,
        border: Border.all(color: AppDesign.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
            child: AddressPhotoPreview(
              address: address,
              title: savedTitle.isEmpty ? null : savedTitle,
              size: 136,
            ),
          ),
          const SizedBox(height: AppDesign.spacing12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F1FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppDesign.travelBlue,
                ),
              ),
              const SizedBox(width: AppDesign.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title, style: AppDesign.headingSmall),
                        ),
                        _PlaceRatingBadge(title: title, address: address),
                      ],
                    ),
                    const SizedBox(height: AppDesign.spacing4),
                    Text(address, style: AppDesign.bodySmall),
                    const SizedBox(height: AppDesign.spacing12),
                    OutlinedButton.icon(
                      onPressed: isAdding ? null : onAddToMap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppDesign.primary,
                        side: const BorderSide(color: AppDesign.borderColor),
                      ),
                      icon: isAdding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_location_alt_outlined),
                      label: const Text('내 지도에 추가'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceRatingBadge extends StatefulWidget {
  const _PlaceRatingBadge({required this.title, required this.address});

  final String title;
  final String address;

  @override
  State<_PlaceRatingBadge> createState() => _PlaceRatingBadgeState();
}

class _PlaceRatingBadgeState extends State<_PlaceRatingBadge> {
  double? _rating;
  int? _ratingCount;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    try {
      final places = await PlacesService().searchPlacesByKeyword(
        '${widget.title} ${widget.address}',
      );
      if (places.isEmpty || !mounted) return;

      final place = places.first;
      final rating = (place['rating'] as num?)?.toDouble();
      final ratingCount = (place['userRatingCount'] as num?)?.toInt();
      if (rating != null) {
        setState(() {
          _rating = rating;
          _ratingCount = ratingCount;
        });
      }
    } catch (_) {
      // Ratings are supplemental. The place card remains usable without one.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_rating == null) return const SizedBox.shrink();

    final countLabel = _ratingCount == null ? '' : ' ($_ratingCount)';
    return Container(
      margin: const EdgeInsets.only(left: AppDesign.spacing8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppDesign.secondaryBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: AppDesign.travelOrange,
            size: 16,
          ),
          const SizedBox(width: 2),
          Text(
            '${_rating!.toStringAsFixed(1)}$countLabel',
            style: AppDesign.caption.copyWith(
              color: AppDesign.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingPlaceCard extends StatelessWidget {
  const _MissingPlaceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
      ),
      child: Text(
        '이전에 저장된 링크라 장소 정보가 없습니다.',
        style: AppDesign.bodyMedium.copyWith(color: AppDesign.secondaryText),
      ),
    );
  }
}
