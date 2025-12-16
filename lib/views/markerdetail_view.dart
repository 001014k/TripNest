import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../env.dart';
import '../viewmodels/markerdetail_viewmodel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../design/app_design.dart';
import 'mapsample_view.dart';

class MarkerDetailView extends StatefulWidget {
  final Marker marker;
  final String keyword;

  MarkerDetailView({
    required this.marker,
    required this.keyword,
  });

  @override
  _MarkerDetailPageState createState() => _MarkerDetailPageState();
}

class _MarkerDetailPageState extends State<MarkerDetailView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showBottomSheet(BuildContext context, MarkerDetailViewModel viewmodel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 바텀시트 핸들
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppDesign.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppDesign.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '길찾기 앱 선택',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppDesign.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _mapButtonWithImage('구글맵', 'assets/GoogleMap.png', () => viewmodel.openGoogleMaps(context)),
              const SizedBox(height: 12),
              _mapButtonWithImage('카카오맵', 'assets/kakaomap.png', () => viewmodel.openKakaoMap(context)),
              const SizedBox(height: 12),
              _mapButtonWithImage('네이버맵', 'assets/NaverMap.png', () => viewmodel.openNaverMap(context)),
              const SizedBox(height: 12),
              _mapButtonWithImage('티맵', 'assets/Tmap.png', () => viewmodel.openTmap(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _mapButtonWithImage(String title, String assetPath, VoidCallback onTap) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        border: Border.all(color: AppDesign.borderColor, width: 1.5),
        boxShadow: AppDesign.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppDesign.lightGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(assetPath, fit: BoxFit.contain),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: AppDesign.bodyLarge.copyWith(
                    color: AppDesign.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppDesign.subtleText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = MarkerDetailViewModel(widget.marker);
        vm.fetchUserMarkerDetail(widget.marker.markerId.value);
        return vm;
      },
      child: Consumer<MarkerDetailViewModel>(
        builder: (context, viewmodel, _) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDesign.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPremiumAppBar(context, viewmodel),
                      const SizedBox(height: AppDesign.spacing24),
                      _buildPremiumMarkerImage(viewmodel),
                      const SizedBox(height: AppDesign.spacing32),
                      _buildMarkerInfoCard(viewmodel),
                      const SizedBox(height: AppDesign.spacing24),
                      if (viewmodel.address != null)
                      const SizedBox(height: AppDesign.spacing24),
                      _buildReviewCards(viewmodel),
                      const SizedBox(height: AppDesign.spacing32),
                      _buildActionButtons(context, viewmodel),
                      const SizedBox(height: AppDesign.spacing24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumAppBar(BuildContext context, MarkerDetailViewModel viewmodel) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppDesign.cardBg,
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            boxShadow: AppDesign.softShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppDesign.primaryText,
                size: 20,
              ),
            ),
          ),
        ),
        const Spacer(),
        // 개선된 메뉴 버튼
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppDesign.cardBg,
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            boxShadow: AppDesign.softShadow,
          ),
          child: PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            offset: const Offset(0, 56),
            icon: const Icon(Icons.more_vert, color: AppDesign.primaryText),
            onSelected: (value) async {
              if (value == '삭제') {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text('마커 삭제'),
                    content: const Text('정말 이 마커를 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );

                if (shouldDelete == true && mounted) {
                  try {
                    await viewmodel.deleteMarker(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('삭제 실패: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              } else if (value == '수정') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('수정 기능은 곧 추가될 예정입니다')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '수정',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: AppDesign.travelBlue),
                    SizedBox(width: 12),
                    Text('수정'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: '삭제',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('삭제', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarkerInfoCard(MarkerDetailViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      padding: const EdgeInsets.all(AppDesign.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppDesign.glowShadow,
                ),
                child: const Icon(Icons.place, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppDesign.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.title ?? '제목 없음',
                      style: AppDesign.headingMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppDesign.travelPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.label, size: 14, color: AppDesign.travelPurple),
                          const SizedBox(width: 6),
                          Text(
                            vm.keyword ?? '키워드 없음',
                            style: AppDesign.bodyMedium.copyWith(
                              color: AppDesign.travelPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (vm.address != null) ...[
            const SizedBox(height: AppDesign.spacing20),
            const Divider(color: AppDesign.borderColor),
            const SizedBox(height: AppDesign.spacing16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppDesign.travelBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on, color: AppDesign.travelBlue, size: 20),
                ),
                const SizedBox(width: AppDesign.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '위치',
                        style: AppDesign.caption.copyWith(
                          color: AppDesign.subtleText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vm.address!,
                        style: AppDesign.bodyLarge.copyWith(
                          color: AppDesign.primaryText,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCards(MarkerDetailViewModel vm) {
    final reviewLinks = vm.reviewLinks;
    if (reviewLinks.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppDesign.sunsetGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.rate_review, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text("리뷰 미리보기", style: AppDesign.headingSmall),
            const Spacer(),
            // 스크롤 힌트
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppDesign.travelBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '스와이프',
                    style: AppDesign.caption.copyWith(
                      color: AppDesign.travelBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppDesign.travelBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesign.spacing16),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: reviewLinks.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(width: AppDesign.spacing12),
            itemBuilder: (context, index) {
              final review = reviewLinks[index];

              return GestureDetector(
                onTap: () async {
                  final url = Uri.parse(review['url']!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: AppDesign.cardBg,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                    border: Border.all(color: AppDesign.borderColor, width: 1.5),
                    boxShadow: AppDesign.softShadow,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppDesign.lightGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(review['icon']!, height: 32, width: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        review['platform']!,
                        style: AppDesign.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppDesign.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, MarkerDetailViewModel vm) {
    return Column(
      children: [
        // 메인 액션 버튼 (길찾기)
        Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: AppDesign.primaryGradient,
            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
            boxShadow: AppDesign.glowShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              onTap: () => _showBottomSheet(context, vm),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions, color: Colors.white, size: 24),
                    const SizedBox(width: AppDesign.spacing12),
                    Text(
                      '길찾기',
                      style: AppDesign.headingSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDesign.spacing12),
        // 보조 액션 버튼 (지도에서 보기)
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppDesign.cardBg,
            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
            border: Border.all(color: AppDesign.travelBlue, width: 2),
            boxShadow: AppDesign.softShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapSampleView(
                      initialMarkerId: vm.marker.markerId,
                    ),
                  ),
                );
              },
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map, color: AppDesign.travelBlue, size: 22),
                    const SizedBox(width: AppDesign.spacing10),
                    Text(
                      '지도에서 보기',
                      style: AppDesign.bodyLarge.copyWith(
                        color: AppDesign.travelBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumMarkerImage(MarkerDetailViewModel viewmodel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
      child: Container(
        height: 360,
        width: double.infinity,
        child: FutureBuilder<List<String>>(
          future: _fetchMultiplePhotos(viewmodel.address ?? '', viewmodel.title),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildPhotoPlaceholder(viewmodel);
            }

            final photoUrls = snapshot.data!.take(6).toList();

            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: photoUrls.length,
                  itemBuilder: (context, index) {
                    final url = photoUrls[index];

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        precacheImage(CachedNetworkImageProvider(url), context);
                      }
                    });

                    return CachedNetworkImage(
                      key: ValueKey(url),
                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 360,
                      placeholder: (_, __) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppDesign.travelBlue.withOpacity(0.3),
                              AppDesign.travelPurple.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '이미지 로딩 중...',
                                style: AppDesign.bodyMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey[300]!,
                              Colors.grey[200]!,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey[400], size: 60),
                              const SizedBox(height: 8),
                              Text(
                                '이미지를 불러올 수 없습니다',
                                style: AppDesign.bodyMedium.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      fadeInDuration: const Duration(milliseconds: 300),
                      fadeOutDuration: const Duration(milliseconds: 200),
                    );
                  },
                ),



                if (photoUrls.length > 1)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPage + 1}/${photoUrls.length}',
                        style: AppDesign.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                if (photoUrls.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(photoUrls.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentPage ? 28 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<String>> _fetchMultiplePhotos(String address, String? title) async {
    if (address.isEmpty) return [];

    String query = title != null && title.isNotEmpty ? '$title $address' : address;

    try {
      final response = await http.post(
        Uri.https('places.googleapis.com', '/v1/places:searchText'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': Env.googleMapsApiKey,
          'X-Goog-FieldMask': 'places.id,places.photos',
        },
        body: jsonEncode({"textQuery": query}),
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final places = data['places'] as List<dynamic>?;

      if (places == null || places.isEmpty) return [];

      List<String> urls = [];
      for (var photo in places[0]['photos'] ?? []) {
        final name = photo['name'];
        final url = 'https://places.googleapis.com/v1/$name/media'
            '?key=${Env.googleMapsApiKey}&maxWidthPx=800';
        urls.add(url);
        if (urls.length >= 6) break;
      }

      return urls;
    } catch (e) {
      debugPrint('다중 사진 로드 실패: $e');
      return [];
    }
  }

  Widget _buildPhotoPlaceholder(MarkerDetailViewModel vm) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppDesign.travelBlue.withOpacity(0.7),
            AppDesign.travelPurple.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_back,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '사진을 찾을 수 없습니다',
                  style: AppDesign.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '하지만 여전히 멋진 장소예요!',
                  style: AppDesign.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vm.title?.isNotEmpty == true)
                    Text(
                      vm.title!,
                      style: AppDesign.headingLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(blurRadius: 12, color: Colors.black87),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          vm.address ?? '주소 불러오는 중...',
                          style: AppDesign.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.95),
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}