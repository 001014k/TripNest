import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // AddMarkersToListPage에서 true를 반환하면 마커 리스트를 새로고침
    if (result == true) {
      _loadMarkers();
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _navigateToAddMarkersToListPage,
              child: Text('Add Markers to List'),
            ),
          ),
        ],
      ),
    );
  }
}
