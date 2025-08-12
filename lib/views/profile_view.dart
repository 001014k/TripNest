import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..fetchUserStats(widget.userId),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                '프로필',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
              backgroundColor: Colors.blue,
              elevation: 0,
            ),
            body: viewModel.isLoading
                ? Center(child: CircularProgressIndicator())
                : viewModel.errorMessage != null
                ? Center(
              child: Text(
                viewModel.errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 기본 정보
                  if (viewModel.nickname != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.shade200.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_circle, size: 48, color: Colors.blueGrey.shade700),
                          const SizedBox(width: 16),
                          Text(
                            viewModel.nickname!,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 활동 통계 섹션
                  Text(
                    '활동 통계',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard('마커', viewModel.stats?['markers'] ?? 0, Icons.location_on),
                  const SizedBox(height: 12),
                  _buildStatCard('리스트', viewModel.stats?['lists'] ?? 0, Icons.list),

                  const SizedBox(height: 32),

                  // 계정 관리 섹션
                  Text(
                    '계정 관리',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('프로필 수정'),
                    onTap: () {
                      // 프로필 수정 페이지로 이동하는 로직 넣기
                      Navigator.pushNamed(context, '/profile_edit');
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('로그아웃'),
                    onTap: () async {
                      try {
                        await Supabase.instance.client.auth.signOut(); // ✅ Supabase 로그아웃
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login_option', // 로그인 페이지 라우트
                              (route) => false, // 스택 완전 제거
                        );
                      } catch (e) {
                        debugPrint('로그아웃 실패: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('로그아웃에 실패했습니다. 다시 시도해주세요.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.shade100.withOpacity(0.5),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueGrey.shade700),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
