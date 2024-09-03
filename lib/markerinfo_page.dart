import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'addmarkerstolist_page.dart';
import 'dart:io' show Platform;

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
  TextEditingController _searchController = TextEditingController();

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

  void _openSpotify() async {
    final query = Uri.encodeComponent(_searchController.text);
    final String spotifyUrl = 'spotify:search:$query';
    final Uri spotifyUri = Uri.parse(spotifyUrl);
    final Uri spotifyInstallUri = Uri.parse(
        'https://apps.apple.com/us/app/spotify-music-and-podcasts/id324684580');

    try {
      if (await canLaunchUrl(spotifyUri)) {
        await launchUrl(spotifyUri);
      } else {
        if (await canLaunchUrl(spotifyInstallUri)) {
          await launchUrl(spotifyInstallUri);
        } else {
          throw 'Could not open Spotify.';
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _openAppleMusic() async {
    final query = Uri.encodeComponent(_searchController.text);
    final String appleMusicUrl = 'music://search/$query';
    final Uri appleMusicUri = Uri.parse(appleMusicUrl);
    final Uri appleMusicInstallUri = Uri.parse(
        'https://apps.apple.com/us/app/apple-music/id1108187390');

    try {
      if (await canLaunchUrl(appleMusicUri)) {
        await launchUrl(appleMusicUri);
      } else {
        if (await canLaunchUrl(appleMusicInstallUri)) {
          await launchUrl(appleMusicInstallUri);
        } else {
          throw 'Could not open Apple Music.';
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _openYouTubeMusic() async {
    final query = Uri.encodeComponent(_searchController.text);
    final appUri = Uri.parse('youtubemusic://search?q=$query');
    final installUri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/app/id1017492454')
        : Uri.parse('https://play.google.com/store/apps/details?id=com.google.android.apps.youtube.music');

    try {
      // 앱이 설치되어 있는지 확인하지 않고 바로 실행 시도
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // 앱이 설치되지 않았거나 실행에 실패한 경우 설치 페이지로 이동
      try {
        await launchUrl(installUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        print('Could not open YouTube Music or redirect to the install page: $e');
      }
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
                  _openSpotify();
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
                  _openAppleMusic();
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
                  _openYouTubeMusic();
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
                    final markerDoc = markers[index];
                    final markerData = markerDoc.data() as Map<String, dynamic>;
                    final markerId = markerDoc.id; // Use the document ID as the marker ID

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Icon(Icons.location_on, color: Colors.blue),
                          title: Text(
                              markerData['title'] ?? 'No Title',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, // 마커 이름을 볼드 처리
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            'Lat: ${markerData['lat']}, Lng: ${markerData['lng']}\n${markerData['snippet'] ?? 'No Snippet'}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final result = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('삭제 확인'),
                                      content: Text('이 마커를 삭제하시겠습니까?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text('취소'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: Text('삭제', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                              );
                              if (result == true) {
                                // 마커 삭제
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('lists')
                                    .doc(widget.listId)
                                    .collection('bookmarks')
                                    .doc(markerId)
                                    .delete();
                              }
                            },
                          ),
                        ),
                        Divider(
                          color: Colors.grey, // 구분선 색상
                          thickness: 1, // 구분선 두께
                        ),
                      ],
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
