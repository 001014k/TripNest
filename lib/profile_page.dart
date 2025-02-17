import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  final String userId;

  ProfilePage({required this.userId});

  Future<Map<String, int>> _getUserStats() async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    final markersSnapshot = await userDoc.collection('user_markers').get();
    final markersCount = markersSnapshot.size;

    final listsSnapshot = await userDoc.collection('lists').get();
    final listsCount = listsSnapshot.size;

    final bookmarksSnapshot = await userDoc.collection('bookmarks').get();
    final bookmarksCount = bookmarksSnapshot.size;

    return {
      'markers': markersCount,
      'lists': listsCount,
      'bookmarks': bookmarksCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _getUserStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child:
                    Text('오류가 발생했습니다.', style: TextStyle(color: Colors.red)));
          }

          final stats = snapshot.data;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사용자 통계',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 16),
                _buildStatCard('마커', stats?['markers'] ?? 0, Icons.location_on),
                SizedBox(height: 8),
                _buildStatCard('리스트', stats?['lists'] ?? 0, Icons.list),
                SizedBox(height: 8),
                _buildStatCard('북마크', stats?['bookmarks'] ?? 0, Icons.bookmark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueGrey[700]),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[600],
            ),
          ),
        ],
      ),
    );
  }
}
