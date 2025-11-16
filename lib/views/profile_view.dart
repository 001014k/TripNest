import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../design/app_design.dart';

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
            backgroundColor: AppDesign.primaryBg,
            appBar: AppBar(
              title: Text(
                '프로필',
                style: AppDesign.headingMedium.copyWith(
                  color: AppDesign.whiteText,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppDesign.whiteText),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                ),
              ),
              elevation: 0,
            ),
            body: viewModel.isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
              ),
            )
                : viewModel.errorMessage != null
                ? Center(
              child: Container(
                margin: const EdgeInsets.all(AppDesign.spacing24),
                padding: const EdgeInsets.all(AppDesign.spacing24),
                decoration: BoxDecoration(
                  color: AppDesign.cardBg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                  boxShadow: AppDesign.softShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: AppDesign.spacing16),
                    Text(
                      viewModel.errorMessage!,
                      style: AppDesign.bodyLarge.copyWith(
                        color: Colors.red.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
                : Container(
              decoration: const BoxDecoration(
                gradient: AppDesign.backgroundGradient,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDesign.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 프로필 기본 정보 - 개선된 디자인
                    if (viewModel.nickname != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppDesign.spacing32),
                        padding: const EdgeInsets.all(AppDesign.spacing24),
                        decoration: BoxDecoration(
                          color: AppDesign.cardBg,
                          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
                          boxShadow: AppDesign.elevatedShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: AppDesign.primaryGradient,
                                borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                              ),
                              child: const Icon(
                                Icons.account_circle,
                                size: 40,
                                color: AppDesign.whiteText,
                              ),
                            ),
                            const SizedBox(width: AppDesign.spacing20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    viewModel.nickname!,
                                    style: AppDesign.headingLarge,
                                  ),
                                  const SizedBox(height: AppDesign.spacing4),
                                  Text(
                                    '여행자',
                                    style: AppDesign.bodyLarge.copyWith(
                                      color: AppDesign.travelBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 활동 통계 섹션 - 개선된 디자인
                    Text(
                      '활동 통계',
                      style: AppDesign.headingMedium,
                    ),
                    const SizedBox(height: AppDesign.spacing16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '마커',
                            viewModel.stats?['markers'] ?? 0,
                            Icons.location_on,
                            AppDesign.travelBlue,
                          ),
                        ),
                        const SizedBox(width: AppDesign.spacing12),
                        Expanded(
                          child: _buildStatCard(
                            '리스트',
                            viewModel.stats?['lists'] ?? 0,
                            Icons.list,
                            AppDesign.travelGreen,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDesign.spacing40),

                    // 계정 관리 섹션 - 개선된 디자인
                    Text(
                      '계정 관리',
                      style: AppDesign.headingMedium,
                    ),
                    const SizedBox(height: AppDesign.spacing16),

                    // 보안/설정 메뉴 - 개선된 디자인
                    Container(
                      decoration: BoxDecoration(
                        color: AppDesign.cardBg,
                        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                        boxShadow: AppDesign.softShadow,
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          expansionTileTheme: const ExpansionTileThemeData(
                            backgroundColor: Colors.transparent,
                            collapsedBackgroundColor: Colors.transparent,
                          ),
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(AppDesign.spacing8),
                            decoration: BoxDecoration(
                              color: AppDesign.travelPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDesign.spacing8),
                            ),
                            child: Icon(
                              Icons.lock,
                              color: AppDesign.travelPurple,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '보안/설정',
                            style: AppDesign.bodyMedium,
                          ),
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(
                                AppDesign.spacing16,
                                0,
                                AppDesign.spacing16,
                                AppDesign.spacing12,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesign.lightGray,
                                borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                              ),
                              child: Column(
                                children: [
                                  _buildMenuTile(
                                    Icons.privacy_tip,
                                    '개인정보',
                                    AppDesign.travelBlue,
                                        () => Navigator.pushNamed(context, '/privacy_settings'),
                                  ),
                                  _buildMenuTile(
                                    Icons.notifications,
                                    '알림 설정',
                                    AppDesign.travelOrange,
                                        () => Navigator.pushNamed(context, '/notification_settings'),
                                  ),
                                  _buildMenuTile(
                                    Icons.delete_forever,
                                    '계정 탈퇴',
                                    Colors.red.shade400,
                                        () => _handleAccountDeletion(context),
                                    isDestructive: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDesign.spacing16),

                    // 로그아웃 - 개선된 디자인
                    Container(
                      decoration: BoxDecoration(
                        color: AppDesign.cardBg,
                        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                        boxShadow: AppDesign.softShadow,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDesign.spacing20,
                          vertical: AppDesign.spacing8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(AppDesign.spacing8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(AppDesign.spacing8),
                          ),
                          child: Icon(
                            Icons.logout,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '로그아웃',
                          style: AppDesign.bodyMedium,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppDesign.subtleText,
                        ),
                        onTap: () => _handleLogout(context),
                      ),
                    ),

                    const SizedBox(height: AppDesign.spacing80),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing20),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: AppDesign.spacing12),
          Text(
            '$count',
            style: AppDesign.headingLarge.copyWith(
              color: color,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: AppDesign.spacing4),
          Text(
            title,
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
      IconData icon,
      String title,
      Color iconColor,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing16,
        vertical: AppDesign.spacing4,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppDesign.spacing6),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDesign.spacing6),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: AppDesign.bodyMedium.copyWith(
          color: isDestructive ? iconColor : AppDesign.primaryText,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppDesign.subtleText,
      ),
      onTap: onTap,
    );
  }

  Future<void> _handleAccountDeletion(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        ),
        title: Text(
          '계정 탈퇴',
          style: AppDesign.headingMedium,
        ),
        content: Text(
          '정말로 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
          style: AppDesign.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: AppDesign.bodyMedium.copyWith(
                color: AppDesign.secondaryText,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(AppDesign.spacing8),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                '삭제',
                style: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.whiteText,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.auth.admin.deleteUser(user.id);

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login_option',
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('계정 탈퇴 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('계정 탈퇴에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.spacing8),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppDesign.spacing16),
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login_option',
            (route) => false,
      );
    } catch (e) {
      debugPrint('로그아웃 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그아웃에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.spacing8),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppDesign.spacing16),
        ),
      );
    }
  }
}