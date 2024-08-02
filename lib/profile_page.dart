import 'package:flutter/material.dart';
import 'main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'login_page.dart';
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

enum Menu { itemOne, itemTwo, itemThree }

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text('프로필'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        backgroundColor: Colors.blueGrey[700],
        actions: [
          PopupMenuButton<Menu>(
            icon: const Icon(Icons.person),
            offset: const Offset(0, 40),
            color: Colors.white,
            onSelected: (Menu item) {
              switch (item) {
                case Menu.itemOne:
                  //Account 메뉴 선택 시 처리
                  break;
                case Menu.itemTwo:
                  // Setting 메뉴 선택 시 처리
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('설정'),
                        content: Text('회원 탈퇴를 하시겠습니까?'),
                        actions: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: Text('회원 탈퇴'),
                            onPressed: () async {
                              await _deleteUser(context);
                            },
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: Text('취소'),
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      );
                    },
                  );
                  break;
                case Menu.itemThree:
                  // sign out 메뉴 선택 시 처리
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('로그아웃'),
                        content: Text('로그아웃 하시겠습니까?'),
                        actions: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: Text('로그아웃'),
                            onPressed: () async {
                              // 로그아웃 기능
                              await FirebaseAuth.instance.signOut();
                              // 로그인 페이지로 이동
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/login', (route) => false);
                            },
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: Text('취소'),
                            onPressed: () async {
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
                value: Menu.itemOne,
                child: Text('계정'),
              ),
              const PopupMenuItem<Menu>(
                value: Menu.itemTwo,
                child: Text('설정'),
              ),
              const PopupMenuItem<Menu>(
                value: Menu.itemThree,
                child: Text('로그아웃'),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage('asstes/profile.png'),
                backgroundColor: Colors.white,
              ),
              otherAccountsPictures: <Widget>[
                CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/profile.png'),
                ),
              ],
              accountName: Text('kim'),
              accountEmail: Text('hm4854@2gmail.com'),
              onDetailsPressed: () {},
              decoration: BoxDecoration(
                  color: Colors.blueGrey[200],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40.0),
                    bottomRight: Radius.circular(40.0),
                  )),
            ),
            ListTile(
              leading: Icon(
                Icons.map,
                color: Colors.grey[850],
              ),
              title: Text('지도'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapSample()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.account_circle,
                color: Colors.grey[850],
              ),
              title: Text('마이페이지'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.question_answer,
                color: Colors.grey[850],
              ),
              title: Text('Q&A'),
              onTap: () {
                // Handle navigation to the Q&A page
              },
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    NetworkImage('https://via.placeholder.com/150'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Posts', '123'),
                        _buildStatColumn('Followers', '456'),
                        _buildStatColumn('Following', '789'),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Username',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: () {},
            child: Text('프로필 수정'),
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
      height: 100,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStoryHighlight('Highlight 1'),
          _buildStoryHighlight('Highlight 2'),
          _buildStoryHighlight('Highlight 3'),
          _buildStoryHighlight('Highlight 4'),
        ],
      ),
    );
  }

  Widget _buildStoryHighlight(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          SizedBox(height: 4),
          Text(label),
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
              Tab(icon: Icon(Icons.grid_on)),
              Tab(icon: Icon(Icons.list)),
            ],
          ),
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
          color: Colors.grey[300],
          child: Image.network('https://via.placeholder.com/150',
              fit: BoxFit.cover),
        );
      },
    );
  }

  Future<void> _deleteUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // firestore에서 사용자 데이터 삭제
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
        print('회원 탈퇴 중 오류 발생 : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원 탈퇴 중 오류가 발생함: $e'),
          ),
        );
      }
    }
  }
}
