import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../views/user_list_view.dart';
import '../viewmodels/dashboard_viewmodel.dart';


class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late DashboardViewModel _viewModel;


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
            Text('Total Users: $_viewModel.totalUsers'),
            Text('Total Markers: $_viewModel.totalMarkers'),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _viewModel.userMarkersCount.keys.length,
                itemBuilder: (context, index) {
                  String email = _viewModel.userMarkersCount.keys.elementAt(index);
                  int markerCount = _viewModel.userMarkersCount[email]!;
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
              accountEmail: Text(
                  user != null ? user.email ?? 'No email' : 'Not logged in'),
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
                  MaterialPageRoute(builder: (context) => UserListView()),
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
                  MaterialPageRoute(builder: (context) => DashboardView ()),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
