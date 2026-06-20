import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../design/app_design.dart';
import 'security_settings_view.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({required this.userId, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
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
            body: viewModel.isLoading
                ? _buildLoadingState()
                : viewModel.errorMessage != null
                    ? _buildErrorState(viewModel.errorMessage!)
                    : _buildContent(context, viewModel),
          );
        },
      ),
    );
  }

  // ================================
  // 로딩 상태
  // ================================
  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
        ),
      ),
    );
  }

  // ================================
  // 에러 상태
  // ================================
  Widget _buildErrorState(String message) {
    return Container(
      decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
      child: Center(
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
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: AppDesign.spacing16),
              Text(
                message,
                style: AppDesign.bodyLarge.copyWith(color: Colors.red.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================
  // 메인 콘텐츠
  // ================================
  Widget _buildContent(BuildContext context, ProfileViewModel viewModel) {
    return Column(
      children: [
        // 그라데이션 히어로 영역 (AppBar + 프로필 정보 + 통계)
        _ProfileHero(viewModel: viewModel),
        // 스크롤 본문
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(AppDesign.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 활동 통계 카드
                  _SectionLabel(label: '활동 통계'),
                  const SizedBox(height: AppDesign.spacing12),
                  _ActivityStatCards(viewModel: viewModel),

                  // 계정 관리
                  _SectionLabel(label: '계정 관리'),
                  const SizedBox(height: AppDesign.spacing12),
                  _MenuGroup(
                    items: [
                      _MenuItem(
                        icon: Icons.shield_outlined,
                        iconColor: AppDesign.travelBlue,
                        iconBg: const Color(0xFFEFF6FF),
                        label: '개인정보',
                        subtitle: '개인정보 처리 방침',
                        onTap: () =>
                            Navigator.pushNamed(context, '/privacy_settings'),
                      ),
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        iconColor: AppDesign.travelOrange,
                        iconBg: const Color(0xFFFFFBEB),
                        label: '알림 설정',
                        subtitle: '푸시 알림 및 이메일 관리',
                        onTap: () => Navigator.pushNamed(
                            context, '/notification_settings'),
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline,
                        iconColor: AppDesign.travelPurple,
                        iconBg: const Color(0xFFF5F3FF),
                        label: '보안',
                        subtitle: '연결된 로그인 계정 확인',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SecuritySettingsView(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // 세션
                  _SectionLabel(label: '세션'),
                  const SizedBox(height: AppDesign.spacing12),
                  _MenuGroup(
                    items: [
                      _MenuItem(
                        icon: Icons.logout,
                        iconColor: AppDesign.secondaryText,
                        iconBg: AppDesign.secondaryBg,
                        label: '로그아웃',
                        subtitle: '현재 기기에서 로그아웃',
                        onTap: () => _handleLogout(context),
                      ),
                    ],
                  ),

                  // 위험 구역
                  _SectionLabel(
                    label: '위험 구역',
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: AppDesign.spacing12),
                  _MenuGroup(
                    items: [
                      _MenuItem(
                        icon: Icons.delete_forever_outlined,
                        iconColor: Colors.red.shade400,
                        iconBg: const Color(0xFFFEF2F2),
                        label: '계정 탈퇴',
                        subtitle: '모든 데이터가 영구 삭제됩니다',
                        labelColor: Colors.red.shade500,
                        onTap: () => _handleAccountDeletion(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDesign.spacing20),
                  Center(
                    child: Text(
                      'FlutterTrip v1.0.0',
                      style: AppDesign.caption,
                    ),
                  ),
                  const SizedBox(height: AppDesign.spacing40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================================
  // 로그아웃 처리
  // ================================
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('로그아웃에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppDesign.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.spacing8),
          ),
        ),
      );
    }
  }

  // ================================
  // 계정 탈퇴 처리
  // ================================
  Future<void> _handleAccountDeletion(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        ),
        title: Text('계정 영구 삭제', style: AppDesign.headingMedium),
        content: const Text(
          '정말로 계정을 삭제하시겠습니까?\n\n'
          '• 모든 마커, 리스트, 알림이 사라집니다\n'
          '• 친구 관계도 자동 해제됩니다\n'
          '• 이 작업은 되돌릴 수 없습니다',
          style: AppDesign.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
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
                style: AppDesign.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );

    final viewModel = context.read<ProfileViewModel>();
    final success = await viewModel.deleteAccount();

    if (!mounted) return;
    Navigator.of(context).pop(); // 로딩 닫기

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login_option',
        (route) => false,
        arguments: {'showDeletedMessage': true},
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(viewModel.errorMessage ?? '계정 탈퇴에 실패했습니다.'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppDesign.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.spacing8),
        ),
      ),
    );
  }
}

// ================================
// 프로필 히어로 (AppBar + 아바타 + 통계)
// ================================
class _ProfileHero extends StatelessWidget {
  final ProfileViewModel viewModel;
  const _ProfileHero({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppDesign.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar 행
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing20,
                vertical: AppDesign.spacing12,
              ),
              child: Row(
                children: [
                  _HeroIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '프로필',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // 밸런스용
                ],
              ),
            ),

            // 아바타 + 이름
            const SizedBox(height: AppDesign.spacing8),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.account_circle,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppDesign.spacing12),
            Text(
              viewModel.nickname ?? '여행자',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: AppDesign.spacing8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing16,
                vertical: AppDesign.spacing4,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '여행자',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            // 인라인 통계 스트립
            const SizedBox(height: AppDesign.spacing20),
            Container(
              margin: const EdgeInsets.fromLTRB(
                AppDesign.spacing20,
                0,
                AppDesign.spacing20,
                AppDesign.spacing24,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _HeroStat(
                      num: '${viewModel.stats?['markers'] ?? 0}',
                      label: '마커',
                    ),
                    _VerticalDivider(),
                    _HeroStat(
                      num: '${viewModel.stats?['lists'] ?? 0}',
                      label: '리스트',
                    ),
                    _VerticalDivider(),
                    _HeroStat(
                      num: '${viewModel.stats?['friends'] ?? 0}',
                      label: '친구',
                    ),
                    _VerticalDivider(),
                    _HeroStat(
                      num: '${viewModel.stats?['shared_links'] ?? 0}',
                      label: '링크',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String num;
  final String label;

  const _HeroStat({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              num,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: Colors.white.withOpacity(0.15),
    );
  }
}

// ================================
// 섹션 레이블
// ================================
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;

  const _SectionLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDesign.spacing24),
      child: Text(
        label.toUpperCase(),
        style: AppDesign.caption.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color ?? AppDesign.subtleText,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ================================
// 활동 통계 카드 쌍
// ================================
class _ActivityStatCards extends StatelessWidget {
  final ProfileViewModel viewModel;

  const _ActivityStatCards({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.location_on_outlined,
            iconColor: AppDesign.travelBlue,
            iconBg: const Color(0xFFEFF6FF),
            count: viewModel.stats?['markers'] ?? 0,
            label: '저장한 마커',
          ),
        ),
        const SizedBox(width: AppDesign.spacing12),
        Expanded(
          child: _StatCard(
            icon: Icons.list_alt_outlined,
            iconColor: AppDesign.travelGreen,
            iconBg: const Color(0xFFECFDF5),
            count: viewModel.stats?['lists'] ?? 0,
            label: '만든 리스트',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final int count;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing20),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(color: AppDesign.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: AppDesign.spacing10),
          Text(
            '$count',
            style: AppDesign.headingLarge.copyWith(
              fontSize: 28,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: AppDesign.spacing4),
          Text(
            label,
            style: AppDesign.caption.copyWith(
              fontSize: 12,
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================
// 메뉴 그룹 & 아이템
// ================================
class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(color: AppDesign.borderColor),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (idx != 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppDesign.borderColor,
                  indent: 20,
                  endIndent: 20,
                ),
              _MenuItemTile(item: item),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String subtitle;
  final Color? labelColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.labelColor,
  });
}

class _MenuItemTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesign.spacing20,
            vertical: AppDesign.spacing16,
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: AppDesign.spacing16),
              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: AppDesign.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: item.labelColor ?? AppDesign.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: AppDesign.caption.copyWith(
                        fontSize: 12,
                        color: AppDesign.subtleText,
                      ),
                    ),
                  ],
                ),
              ),
              // 화살표
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppDesign.subtleText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
