import 'package:flutter/material.dart';
import 'package:fluttertrip/listdetail_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'markerdetail_page.dart';
import 'create_list_page.dart';

class BookmarkPage extends StatelessWidget {
  Future<List<Marker>> loadBookmarks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userMarkersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks');

      final snapshot = await userMarkersCollection.get();
      return snapshot.docs.map((doc) {
        String title = doc.data().containsKey('title') ? doc['title'] : '이름 없음';
        String keyword =
        doc.data().containsKey('keyword') ? doc['keyword'] : '키워드 없음';
        String address =
        doc.data().containsKey('address') ? doc['address'] : '주소 없음';

        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(doc['lat'], doc['lng']),
          infoWindow: InfoWindow(
            title: title,
            snippet: '$keyword\n$address',
          ),
        );
      }).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> loadLists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userListsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists');

      final snapshot = await userListsCollection.get();
      print('Lists loaded: ${snapshot.docs.length}'); // 디버깅 코드
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title'],
          'createdAt': doc['createdAt'].toDate(),
        };
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('북마크 목록'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateListPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: loadLists(),
        builder: (context, listSnapshot) {
          if (listSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (listSnapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${listSnapshot.error}'));
          }

          if (!listSnapshot.hasData || listSnapshot.data!.isEmpty) {
            return Center(child: Text('생성된 리스트가 없습니다.'));
          }

          final lists = listSnapshot.data!;

          return FutureBuilder<List<Marker>>(
            future: loadBookmarks(),
            builder: (context, bookmarkSnapshot) {
              if (bookmarkSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (bookmarkSnapshot.hasError) {
                return Center(
                    child:
                    Text('오류가 발생했습니다: ${bookmarkSnapshot.error}'));
              }

              final markers = bookmarkSnapshot.data ?? [];

              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '리스트',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  for (var list in lists)
                    ListTile(
                      title: Text(list['title']),
                      subtitle: Text('생성일: ${list['createdAt']}'),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ListDetailPage(
                                  listId: list['id'], listTitle: list['title'],
                                ),
                            ),
                        );
                      },
                    ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '북마크',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  for (var marker in markers)
                    ListTile(
                      title: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            marker.infoWindow.title ?? '이름 없음',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.label, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                marker.infoWindow.snippet?.split('\n')[0] ??
                                    '키워드 없음',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Divider(),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MarkerDetailPage(
                                marker: marker,
                                keyword:
                                marker.infoWindow.snippet?.split('\n')[0] ??
                                    '',
                                onSave: (Marker marker, String keyword) {},
                                onDelete: (Marker marker) {},
                                onBookmark: (Marker marker) {},
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
