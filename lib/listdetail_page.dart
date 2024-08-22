import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'markerdetail_page.dart';

class ListDetailPage extends StatelessWidget {
  final String listId;
  final String listTitle;

  ListDetailPage({required this.listId, required this.listTitle});

  Future<List<Marker>> loadBookmarksInList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bookmarksCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(listId)
          .collection('bookmarks');

      final snapshot = await bookmarksCollection.get();
      return snapshot.docs.map((doc) {
        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(doc['lat'], doc['lng']),
          infoWindow: InfoWindow(
            title: doc['title'],
            snippet: doc['keyword'],
          ),
        );
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(listTitle),
      ),
      body: FutureBuilder<List<Marker>>(
        future: loadBookmarksInList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('북마크가 없습니다.'));
          }

          final markers = snapshot.data!;

          return ListView(
            children: markers.map((marker) {
              return ListTile(
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
                          marker.infoWindow.snippet ?? '키워드 없음',
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
                          keyword: marker.infoWindow.snippet ?? '',
                          onSave: (Marker marker, String keyword) {},
                          onDelete: (Marker marker) {},
                          onBookmark: (Marker marker) {},
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
