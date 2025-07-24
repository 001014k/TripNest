import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/markerdetail_viewmodel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerDetailView extends StatefulWidget {
  final Marker marker;
  final Function(Marker, String) onSave;
  final Function(Marker) onDelete;
  final String keyword;
  final Function(Marker) onBookmark;

  MarkerDetailView({
    required this.marker,
    required this.onSave,
    required this.onDelete,
    required this.keyword,
    required this.onBookmark,
  });

  @override
  _MarkerDetailPageState createState() => _MarkerDetailPageState();
}

class _MarkerDetailPageState extends State<MarkerDetailView> {
  late final MarkerDetailViewModel _viewmodel;

  @override
  void initState() {
    super.initState();
    _viewmodel = MarkerDetailViewModel(
      marker: widget.marker,
      keyword: widget.keyword,
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '길찾기',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _mapButton('구글맵', 'assets/GoogleMap.png', _viewmodel.openGoogleMaps),
              Divider(),
              _mapButton('카카오맵', 'assets/kakaomap.png', _viewmodel.openKakaoMap),
              Divider(),
              _mapButton('네이버맵', 'assets/NaverMap.png', _viewmodel.openNaverMap),
              Divider(),
              _mapButton('티맵', 'assets/Tmap.png', _viewmodel.openTmap),
            ],
          ),
        );
      },
    );
  }

  Widget _mapButton(String title, String iconPath, Function(BuildContext) onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black54),
      onPressed: () => onTap(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(iconPath, width: 24, height: 24),
          SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  // 🎯 리뷰 카드 위젯
  Widget _buildReviewCards() {
    final reviewLinks = _viewmodel.reviewLinks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("🔍 리뷰 미리보기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: reviewLinks.length,
            separatorBuilder: (_, __) => SizedBox(width: 12),
            itemBuilder: (context, index) {
              final review = reviewLinks[index];
              return GestureDetector(
                onTap: () async {
                  final url = Uri.parse(review['url']!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Card(
                  elevation: 3,
                  child: Container(
                    width: 140,
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(review['icon']!, height: 28),
                        SizedBox(height: 8),
                        Text('${review['platform']} 리뷰', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마커 정보', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == '수정') _viewmodel.saveMarker(context);
              else if (value == '삭제') _viewmodel.deleteMarker(context);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: '수정', child: Text('수정')),
              PopupMenuItem(value: '삭제', child: Text('삭제')),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.title, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  _viewmodel.marker.infoWindow.title ?? '제목 없음',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                )
              ],
            ),
            SizedBox(height: 4),
            Container(height: 2, color: Colors.black, width: double.infinity),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.label, color: Colors.blue),
                SizedBox(width: 8),
                Text(_viewmodel.keyword ?? '키워드 없음',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 20),
            _viewmodel.address != null
                ? Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(_viewmodel.address ?? '주소 없음',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
                : CircularProgressIndicator(),
            SizedBox(height: 20),
            _buildReviewCards(), // 🎯 리뷰 카드 삽입 위치
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _showBottomSheet(context),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions, color: Colors.black),
                              SizedBox(width: 8),
                              Text('길찾기', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
