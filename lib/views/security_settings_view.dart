import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../design/app_design.dart';

class SecuritySettingsView extends StatelessWidget {
  const SecuritySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final providers = _connectedProviders(user);

    return Scaffold(
      backgroundColor: AppDesign.primaryBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _SecurityAppBar(onBack: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppDesign.spacing20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SecurityHeader(user: user, providers: providers),
                      const SizedBox(height: AppDesign.spacing24),
                      const _SectionLabel(label: '연결된 로그인 계정'),
                      const SizedBox(height: AppDesign.spacing12),
                      _ConnectedAccountGroup(
                        accounts: [
                          _AccountProviderItem.email(
                            isConnected: providers.contains('email'),
                            email: user?.email,
                          ),
                          _AccountProviderItem.google(
                            isConnected: providers.contains('google'),
                          ),
                          _AccountProviderItem.kakao(
                            isConnected: providers.contains('kakao'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDesign.spacing24),
                      const _SectionLabel(label: '계정 보호'),
                      const SizedBox(height: AppDesign.spacing12),
                      const _SecurityTipCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Set<String> _connectedProviders(User? user) {
    final providers = <String>{};

    for (final identity in user?.identities ?? const []) {
      final provider = identity.provider.toLowerCase();
      if (provider.isNotEmpty) {
        providers.add(provider);
      }
    }

    _addProvider(providers, user?.appMetadata['provider']);
    _addProvider(providers, user?.appMetadata['providers']);

    return providers;
  }

  void _addProvider(Set<String> providers, Object? value) {
    if (value is String && value.isNotEmpty) {
      providers.add(value.toLowerCase());
    }

    if (value is List) {
      for (final item in value) {
        _addProvider(providers, item);
      }
    }
  }
}

class _SecurityAppBar extends StatelessWidget {
  final VoidCallback onBack;

  const _SecurityAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing16,
        vertical: AppDesign.spacing12,
      ),
      child: Row(
        children: [
          Material(
            color: AppDesign.cardBg,
            borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppDesign.primaryText,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDesign.spacing16),
          Text(
            '로그인 및 보안',
            style: AppDesign.headingMedium.copyWith(
              color: AppDesign.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityHeader extends StatelessWidget {
  final User? user;
  final Set<String> providers;

  const _SecurityHeader({required this.user, required this.providers});

  @override
  Widget build(BuildContext context) {
    final connectedCount = _providerCount(user, providers);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesign.spacing24),
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.glowShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: AppDesign.spacing16),
          const Text(
            '계정 접근 수단을 확인해요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            connectedCount == 0
                ? '현재 연결된 로그인 정보를 불러오지 못했어요.'
                : '$connectedCount개의 로그인 계정이 연결되어 있어요.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  int _providerCount(User? user, Set<String> providers) {
    final normalized = {...providers};
    return normalized.intersection({'email', 'google', 'kakao'}).length;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppDesign.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppDesign.subtleText,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ConnectedAccountGroup extends StatelessWidget {
  final List<_AccountProviderItem> accounts;

  const _ConnectedAccountGroup({required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(color: AppDesign.borderColor),
      ),
      child: Column(
        children: accounts.asMap().entries.map((entry) {
          final index = entry.key;
          final account = entry.value;

          return Column(
            children: [
              if (index != 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppDesign.borderColor,
                  indent: 20,
                  endIndent: 20,
                ),
              _ConnectedAccountTile(account: account),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AccountProviderItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String connectedText;
  final String disconnectedText;
  final bool isConnected;
  final String? detail;

  const _AccountProviderItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.connectedText,
    required this.disconnectedText,
    required this.isConnected,
    this.detail,
  });

  factory _AccountProviderItem.email({
    required bool isConnected,
    required String? email,
  }) {
    return _AccountProviderItem(
      icon: Icons.alternate_email,
      iconColor: AppDesign.travelBlue,
      iconBg: const Color(0xFFEFF6FF),
      title: '이메일',
      connectedText: '이메일과 비밀번호로 로그인할 수 있어요',
      disconnectedText: '이메일 로그인이 설정되어 있지 않아요',
      isConnected: isConnected,
      detail: isConnected ? email : null,
    );
  }

  factory _AccountProviderItem.google({required bool isConnected}) {
    return _AccountProviderItem(
      icon: Icons.g_mobiledata,
      iconColor: AppDesign.travelOrange,
      iconBg: const Color(0xFFFFFBEB),
      title: 'Google',
      connectedText: 'Google 계정으로 로그인할 수 있어요',
      disconnectedText: 'Google 계정이 연결되어 있지 않아요',
      isConnected: isConnected,
    );
  }

  factory _AccountProviderItem.kakao({required bool isConnected}) {
    return _AccountProviderItem(
      icon: Icons.chat_bubble_outline,
      iconColor: const Color(0xFF3A2929),
      iconBg: const Color(0xFFFFF7CC),
      title: 'Kakao',
      connectedText: '카카오톡 API로 로그인할 수 있어요',
      disconnectedText: 'Kakao 계정이 연결되어 있지 않아요',
      isConnected: isConnected,
    );
  }
}

class _ConnectedAccountTile extends StatelessWidget {
  final _AccountProviderItem account;

  const _ConnectedAccountTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        account.isConnected ? AppDesign.travelGreen : AppDesign.subtleText;
    final statusBg =
        account.isConnected ? const Color(0xFFECFDF5) : AppDesign.secondaryBg;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing20,
        vertical: AppDesign.spacing16,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: account.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(account.icon, color: account.iconColor, size: 22),
          ),
          const SizedBox(width: AppDesign.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.title,
                  style: AppDesign.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppDesign.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  account.isConnected
                      ? account.connectedText
                      : account.disconnectedText,
                  style: AppDesign.caption.copyWith(
                    fontSize: 12,
                    color: AppDesign.subtleText,
                  ),
                ),
                if (account.detail?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    account.detail!,
                    style: AppDesign.caption.copyWith(
                      fontSize: 12,
                      color: AppDesign.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDesign.spacing12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.spacing10,
              vertical: AppDesign.spacing6,
            ),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              account.isConnected ? '연결됨' : '미연결',
              style: AppDesign.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityTipCard extends StatelessWidget {
  const _SecurityTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing20),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(color: AppDesign.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: AppDesign.travelPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDesign.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '공용 기기에서는 로그아웃해주세요',
                  style: AppDesign.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing4),
                Text(
                  '연결된 로그인 계정이 낯설게 보이면 비밀번호를 재설정하거나 다시 로그인해주세요.',
                  style: AppDesign.caption.copyWith(
                    fontSize: 12,
                    color: AppDesign.secondaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
