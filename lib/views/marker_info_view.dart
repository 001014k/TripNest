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

  @override
  void dispose() {
    _searchController.dispose();
    viewModel.dispose();
    super.dispose();
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
    return ChangeNotifierProvider<MarkerInfoViewModel>.value(
      value: viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Marker Info', style: TextStyle(fontWeight: FontWeight.w600)),
          elevation: 4,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          iconSize: 28,
          items: const [
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
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.error != null) {
              return Center(
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              );
            }

            if (vm.markers.isEmpty) {
              return const Center(
                child: Text(
                  'No markers found.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: vm.markers.length,
              itemBuilder: (context, index) {
                final marker = vm.markers[index];

                return FutureBuilder<String>(
                  future: vm.getAddress(marker.lat, marker.lng),
                  builder: (context, snapshot) {
                    final address = snapshot.data ?? 'Loading address...';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Colors.blueGrey, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    marker.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 26),
                                  onPressed: () => _confirmDelete(context, vm, marker.id),
                                  tooltip: 'Delete Marker',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              address,
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
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

  void _confirmDelete(BuildContext context, MarkerInfoViewModel vm, String markerId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: const Text(
            '삭제하시겠습니까?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            '이 마커를 삭제하면 되돌릴 수 없습니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('삭제'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
              ),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      vm.deleteMarker(markerId);
    }
  }


  void _showMusicPlatformBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        final musicPlatforms = [
          {
            'name': 'Spotify',
            'asset': 'assets/spotify.png',
            'action': () => viewModel.openSpotify(),
          },
          {
            'name': 'Apple Music',
            'asset': 'assets/applemusic.png',
            'action': () => viewModel.openAppleMusic(),
          },
          {
            'name': 'YouTube Music',
            'asset': 'assets/YoutubeMusic.png',
            'action': () => viewModel.openYouTubeMusic(),
          },
        ];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Music',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              ...musicPlatforms.map((platform) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // 닫고 호출
                      (platform['action'] as Function).call();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          (platform['asset'] as Function).call(),
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          (platform['name'] as Function).call(),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
