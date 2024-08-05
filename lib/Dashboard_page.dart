import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertrip/user_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalUsers = 0;
  int totalMarkers = 0;
  Map<String, int> userMarkersCount = {};

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    QuerySnapshot usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    totalUsers = usersSnapshot.docs.length;

    for (var userDoc in usersSnapshot.docs) {
      String email = userDoc['email'];
      QuerySnapshot markersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('user_markers')
          .get();

      int userMarkerCount = markersSnapshot.docs.length;
      totalMarkers += userMarkerCount;
      userMarkersCount[email] = userMarkerCount;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              //로그아웃 가능
              await FirebaseAuth.instance.signOut();
              //로그인 페이지로 이동
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Users: $totalUsers'),
            Text('Total Markers: $totalMarkers'),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: userMarkersCount.keys.length,
                itemBuilder: (context, index) {
                  String email = userMarkersCount.keys.elementAt(index);
                  int markerCount = userMarkersCount[email]!;
                  return ListTile(
                    title: Text('User: $email'),
                    subtitle: Text('Markers: $markerCount'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage('assets/profile.png'),
                backgroundColor: Colors.white,
              ),
              otherAccountsPictures: <Widget>[
                CircleAvatar(
                  backgroundImage: AssetImage('assets/profile.png'),
                  backgroundColor: Colors.white,
                )
              ],
              accountName: Text('admin'),
              accountEmail: Text(user != null ? user.email ?? 'No email' : 'Not logged in'),
              onDetailsPressed: () {},
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.assignment_ind,
                color: Colors.grey,
              ),
              title: Text('회원관리'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserListPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.dashboard,
                color: Colors.grey,
              ),
              title: Text('대시보드'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
