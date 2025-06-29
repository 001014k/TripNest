import 'package:flutter/material.dart';
import '../viewmodels/markerdetail_viewmodel.dart';
import '../views/Imageview_view.dart';
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54, // 버튼의 배경색을 흰색으로 설정
                ),
                onPressed: () => _viewmodel.openGoogleMaps(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/GoogleMap.png', // 사용하고자 하는 이미지 경로
                      width: 24, // 이미지의 너비
                      height: 24, // 이미지의 높이
                    ),
                    SizedBox(width: 8),
                    Text(
                      '구글맵',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(), //구분선 추가
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54, // 버튼의 배경색을 흰색으로 설정
                ),
                onPressed: () => _viewmodel.openKakaoMap(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/kakaomap.png', // 사용하고자 하는 이미지 경로
                      width: 24, // 이미지의 너비
                      height: 24, // 이미지의 높이
                    ),
                    SizedBox(width: 8),
                    Text(
                      '카카오맵',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(), // 구분선 추가
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54, // 버튼의 배경색을 흰색으로 설정
                ),
                onPressed: () => _viewmodel.openNaverMap(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/NaverMap.png', // 사용하고자 하는 이미지 경로
                      width: 24, // 이미지의 너비
                      height: 24, // 이미지의 높이
                    ),
                    SizedBox(width: 8),
                    Text(
                      '네이버맵',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(), // 구분선 추가
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54, // 버튼의 배경색을 흰색으로 설정
                ),
                onPressed: () => _viewmodel.openTmap(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/Tmap.png', // 사용하고자 하는 이미지 경로
                      width: 24, // 이미지의 너비
                      height: 24, // 이미지의 높이
                    ),
                    SizedBox(width: 8),
                    Text(
                      '티맵',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '마커 정보',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == '수정') {
                _viewmodel.saveMarker(context);
              } else if (value == '삭제') {
                _viewmodel.deleteMarker(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: '수정',
                child: Text('수정'),
              ),
              PopupMenuItem(
                value: '삭제',
                child: Text('삭제'),
              ),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
          children: [
            Row(
              children: [
                Icon(Icons.title, color: Colors.black), // 이름 옆에 아이콘 추가
                SizedBox(width: 8),
                Text(
                  _viewmodel.marker.infoWindow.title ?? '제목 없음',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
            SizedBox(height: 4),
            Container(
              height: 2, // 언더바의 두께
              color: Colors.black,
              width: double.infinity, // 화면 전체 너비로 언더바 확장
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.label, color: Colors.blue), // 키워드 옆에 아이콘 추가
                SizedBox(width: 8),
                Text(_viewmodel.keyword ?? '키워드 없음',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            _viewmodel.address != null
                ? Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Colors.red), // 주소 옆에 아이콘 추가
                      SizedBox(width: 8),
                      Text(_viewmodel.address ?? '주소 없음',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                : CircularProgressIndicator(), // 주소를 로드 중일 때 로딩 표시
            SizedBox(height: 20), // 버튼 사이의 여백
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      // 버튼 간의 간격을 균등하게 분배
                      children: [
                        ElevatedButton(
                          onPressed: () => _showBottomSheet(context),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // 모서리를 직각으로 설정
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            // 텍스트와 아이콘의 크기에 맞게 버튼 크기 조정
                            children: [
                              Icon(Icons.directions, color: Colors.black),
                              SizedBox(width: 8), // 아이콘과 텍스트 사이의 간격
                              Text(
                                '길찾기',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _viewmodel.toggleBookmark(context),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // 네모난 모서리
                            ),
                            backgroundColor: _viewmodel.isBookmarked
                                ? Colors.grey[300]
                                : Colors.white, // 버튼 배경 색상 변경
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark,
                                color: _viewmodel.isBookmarked
                                    ? Colors.grey
                                    : Colors.black, // 아이콘 색상 변경
                              ),
                              SizedBox(width: 8),
                              Text(
                                _viewmodel.isBookmarked ? '북마크 해제' : '북마크', // 텍스트 변경
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _viewmodel.isBookmarked
                                      ? Colors.black
                                      : Colors.black, // 텍스트 색상 변경
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // 사진 표시 부분
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo, // 원하는 아이콘을 선택합니다.
                                size: 24.0, // 아이콘의 크기를 설정합니다.
                              ),
                              SizedBox(width: 8), // 아이콘과 텍스트 사이의 간격을 설정합니다.
                              Text(
                                '사진',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          _viewmodel.isLoadingImages
                              ? Center(
                                  child:
                                      CircularProgressIndicator(), // 로딩 인디케이터
                                )
                              : _viewmodel.imageUrls.isEmpty
                                  ? Text('사진이 없습니다.')
                                  : Container(
                                      height: 200, // 슬라이더 높이 설정
                                      child: PageView.builder(
                                        itemCount: _viewmodel.imageUrls.length,
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () async {
                                              // 전체 화면에서 이미지 보기
                                              final result =
                                                  await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ImageviewView(
                                                    imageUrls: _viewmodel.imageUrls,
                                                    initialIndex: index,
                                                  ),
                                                ),
                                              );
                                              // result가 true일 경우 이미지를 다시 로드
                                              if (result == true) {
                                                _viewmodel.loadImages(context); // 이미지를 다시 불러오는 함수
                                              }
                                            },
                                            child: Container(
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 10.0),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                      _viewmodel.imageUrls[index]),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              constraints: BoxConstraints
                                                  .expand(), // 세로로 꽉 차도록 설정
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _viewmodel.pickImage(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // 버튼의 배경색을 흰색으로 설정
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Colors.black, // 아이콘 색상을 검은색으로 설정
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '사진 추가',
                                  style: TextStyle(
                                    color: Colors.black, // 텍스트 색상을 검은색으로 설정
                                    fontWeight: FontWeight.bold, // 텍스트를 볼드체로 설정
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
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
