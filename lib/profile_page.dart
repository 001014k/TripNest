import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePage(),
    );
  }
}

enum Menu { account, settings, signOut }

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          PopupMenuButton<Menu>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (Menu item) {
              switch (item) {
                case Menu.account:
                // Account menu action
                  break;
                case Menu.settings:
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Settings'),
                        content: Text('Do you want to delete your account?'),
                        actions: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Colors.red,
                            ),
                            child: Text('Delete'),
                            onPressed: () async {
                              await _deleteUser(context);
                            },
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Colors.grey,
                            ),
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      );
                    },
                  );
                  break;
                case Menu.signOut:
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Sign Out'),
                        content: Text('Do you want to sign out?'),
                        actions: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
                            ),
                            child: Text('Sign Out'),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/login', (route) => false);
                            },
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Colors.grey,
                            ),
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      );
                    },
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
              const PopupMenuItem<Menu>(
                value: Menu.account,
                child: Text('Account'),
              ),
              const PopupMenuItem<Menu>(
                value: Menu.settings,
                child: Text('Settings'),
              ),
              const PopupMenuItem<Menu>(
                value: Menu.signOut,
                child: Text('Sign Out'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildProfileHeader(),
          _buildStoryHighlights(),
          _buildPostTabs(),
          _buildPostGrid(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatColumn('Posts', '123'),
                        _buildStatColumn('Followers', '456'),
                        _buildStatColumn('Following', '789'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      user != null ? user.email ?? 'No email' : 'Not logged in',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
            ),
            onPressed: () {},
            child: Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  Widget _buildStoryHighlights() {
    return Container(
      height: 120,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStoryHighlight('Travel', Icons.flight),
          _buildStoryHighlight('Food', Icons.fastfood),
          _buildStoryHighlight('Events', Icons.event),
          _buildStoryHighlight('Friends', Icons.group),
        ],
      ),
    );
  }

  Widget _buildStoryHighlight(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.blueAccent,
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPostTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(icon: Icon(Icons.grid_on, color: Colors.black)),
              Tab(icon: Icon(Icons.list, color: Colors.black)),
            ],
            indicatorColor: Colors.blueAccent,
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPostGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 30,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[200],
          child: Image.network(
            'https://via.placeholder.com/150',
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Future<void> _deleteUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Firestore에서 사용자 데이터 삭제
        final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDoc.delete();

        // markers 컬렉션에서 사용자 데이터 삭제
        final userMarkersCollection = FirebaseFirestore.instance
            .collection('markers')
            .doc(user.uid)
            .collection('user_markers');
        final userMarkerSnapshot = await userMarkersCollection.get();
        for (var doc in userMarkerSnapshot.docs) {
          await doc.reference.delete();
        }

        // Firebase Auth에서 사용자 삭제
        await user.delete();

        // 로그아웃 및 로그인 페이지로 이동
        await FirebaseAuth.instance.signOut();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } catch (e) {
        print('Error during account deletion: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during account deletion: $e'),
          ),
        );
      }
    }
  }
}
