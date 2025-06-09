import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/marker_info_viewmodel.dart';
import '../views/add_markers_to_list_view.dart';

class MarkerInfoPage extends StatefulWidget {
  final String listId;

  const MarkerInfoPage({Key? key, required this.listId}) : super(key: key);

  @override
  _MarkerInfoPageState createState() => _MarkerInfoPageState();
}
class _MarkerInfoPageState extends State<MarkerInfoPage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late MarkerInfoViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = MarkerInfoViewModel(listId: widget.listId);
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      navigateToAddMarkersToListPage();
    } else if (index == 1) {
      _showMusicPlatformBottomSheet();
    }
  }

  Future<void> navigateToAddMarkersToListPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMarkersToListPage(listId: widget.listId),
      ),
    );

    if (result == true) {
      await viewModel.loadMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MarkerInfoViewModel(listId: widget.listId),
      child: Scaffold(
        appBar: AppBar(title: Text('Marker Info')),

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.black,
          // BottomNavigationBar 배경색
          selectedItemColor: Colors.white,
          // 선택된 아이템의 색상
          unselectedItemColor: Colors.white.withOpacity(0.6),
          // 선택되지 않은 아이템의 색상
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          // 선택된 아이템 라벨의 스타일
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          // 선택되지 않은 아이템 라벨의 스타일
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.add_location),
              label: 'Add Markers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note),
              label: 'Music',
            ),
          ],
        ),

        body: Consumer<MarkerInfoViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(child: Text(viewModel.error!, style: TextStyle(color: Colors.red)));
            }

            if (viewModel.markers.isEmpty) {
              return Center(child: Text('No markers found.'));
            }

            return ListView.builder(
              itemCount: viewModel.markers.length,
              itemBuilder: (context, index) {
                final marker = viewModel.markers[index];

                return FutureBuilder<String>(
                  future: viewModel.getAddress(marker.lat, marker.lng),
                  builder: (context, snapshot) {
                    String address = snapshot.data ?? 'Loading address...';

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Icon(Icons.location_on, color: Colors.blue),
                          title: Text(
                            marker.title,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(address),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, viewModel, marker.id),
                          ),
                        ),
                        Divider(color: Colors.grey, thickness: 1),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MarkerInfoViewModel viewModel, String markerId) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text('이 마커를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('삭제', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      viewModel.deleteMarker(markerId);
    }
  }

  void _showMusicPlatformBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Music',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54, // 버튼의 배경색을 흰색으로 설정
                ),
                onPressed: () {
                  viewModel.openSpotify();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/spotify.png', // 사용하고자 하는 이미지 경로
                      width: 24, // 이미지의 너비
                      height: 24, // 이미지의 높이
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Spotify',
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
                onPressed: () {
                  viewModel.openAppleMusic();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/applemusic.png', // 사용하고자 하는 이미지 경로
                      width: 24, // 이미지의 너비
                      height: 24, // 이미지의 높이
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Apple Music',
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
                onPressed: () {
                  viewModel.openYouTubeMusic();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/YoutubeMusic.png', // 사용하고자 하는 이미지 경로
                      width: 24, // 이미지의 너비
                      height: 24, // 이미지의 높이
                    ),
                    SizedBox(width: 8),
                    Text(
                      'YouTube Music',
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
}
