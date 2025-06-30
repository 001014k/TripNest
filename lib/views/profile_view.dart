import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..fetchUserStats(widget.userId),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text('프로필',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: viewModel.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : viewModel.errorMessage != null
                  ? Center(
                child: Text(viewModel.errorMessage!,
                    style: TextStyle(color: Colors.red)),
              )
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 닉네임 출력
                    if (viewModel.nickname != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Text(
                          '닉네임: ${viewModel.nickname}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                    // 기존 통계 표시 UI
                    Text(
                      '사용자 통계',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildStatCard(
                        '마커', viewModel.stats?['markers'] ?? 0, Icons.location_on),
                    SizedBox(height: 8),
                    _buildStatCard('리스트', viewModel.stats?['lists'] ?? 0, Icons.list),
                    SizedBox(height: 8),
                    _buildStatCard(
                        '북마크', viewModel.stats?['bookmarks'] ?? 0, Icons.bookmark),
                    SizedBox(height: 24),

                    // 닉네임 검색 입력창
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: '친구 닉네임 검색',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            viewModel.searchUsers(
                                _searchController.text.trim(), widget.userId);
                          },
                        ),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        viewModel.searchUsers(value.trim(), widget.userId);
                      },
                    ),
                    SizedBox(height: 16),

                    // 검색 결과 리스트
                    if (viewModel.searchResults.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: viewModel.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = viewModel.searchResults[index];
                          final isFollowing =
                          viewModel.followingIds.contains(user.id);
                          return ListTile(
                            title: Text(user.nickname ?? '닉네임 없음'),
                            subtitle: Text(user.email ?? ''),
                          );
                        },
                      )
                    else if (_searchController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('검색 결과가 없습니다.'),
                      ),
                  ],
                ),
              ),
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
