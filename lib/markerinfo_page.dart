import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // 추가된 import
import 'addmarkerstolist_page.dart';

class MarkerInfoPage extends StatefulWidget {
  final String listId;

  MarkerInfoPage({required this.listId});

  @override
  _MarkerInfoPageState createState() => _MarkerInfoPageState();
}

class _MarkerInfoPageState extends State<MarkerInfoPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _markers = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lists')
            .doc(widget.listId)
            .collection('bookmarks')
            .get();

        final markers = snapshot.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).toList();

        setState(() {
          _markers = markers;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Failed to load marker info: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToAddMarkersToListPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMarkersToListPage(listId: widget.listId),
      ),
    );

    if (result == true) {
      _loadMarkers();
    }
  }

  Future<void> _launchMusicPlatform(String url, String fallbackUrl) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      await launch(fallbackUrl);
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
              Text(
                '음악',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54, // 버튼의 배경색을 흰색으로 설정
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _launchMusicPlatform('spotify:','https://open.spotify.com/');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.music_note, color: Colors.green),
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
                  Navigator.pop(context);
                  _launchMusicPlatform('music:','https://music.apple.com/');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.music_note, color: Colors.red),
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
                  Navigator.pop(context);
                  _launchMusicPlatform('vnd.youtube.music:','https://music.youtube.com/');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.music_note, color: Colors.redAccent),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _navigateToAddMarkersToListPage();
    } else if (index == 1) {
      _showMusicPlatformBottomSheet(); // 하단 시트 열기
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Marker Info'),
        ),
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Marker Info'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('lists')
                  .doc(widget.listId)
                  .collection('bookmarks')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final markers = snapshot.data!.docs;

                if (markers.isEmpty) {
                  return Center(child: Text('No markers found.'));
                }

                return ListView.builder(
                  itemCount: markers.length,
                  itemBuilder: (context, index) {
                    final marker = markers[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(marker['title'] ?? 'No Title'),
                      subtitle: Text(
                          'Lat: ${marker['lat']}, Lng: ${marker['lng']}\n${marker['snippet'] ?? 'No Snippet'}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black, // BottomNavigationBar 배경색
        selectedItemColor: Colors.white, // 선택된 아이템의 색상
        unselectedItemColor: Colors.white.withOpacity(0.6), // 선택되지 않은 아이템의 색상
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold), // 선택된 아이템 라벨의 스타일
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal), // 선택되지 않은 아이템 라벨의 스타일
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
    );
  }
}
