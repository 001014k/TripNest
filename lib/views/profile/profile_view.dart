import '../../widgets/places/place_keyword_icon.dart';
import '../../navigation/app_page_route.dart';
import '../../widgets/common/app_overlays.dart';
import '../lists/list_view.dart';
import '../../widgets/common/reference_design.dart';
import '../../services/markers/marker_service.dart';
import '../../models/markers/marker_model.dart';
import '../../mappers/marker_map_adapter.dart';
import '../markers/markerdetail_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/navigation/tripnest_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile/profile_viewmodel.dart';
import '../../design/app_design.dart';
import 'security_settings_view.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({required this.userId, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<List<Map<String, dynamic>>> _recent;
  @override
  void initState() {
    super.initState();
    _recent = MarkerService().getRecentMarkers(limit: 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileViewModel>().fetchUserStats(widget.userId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      context.read<ProfileViewModel>().fetchUserStats(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          bottomNavigationBar:
              const TripNestNavigation(currentRoute: '/profile'),
          backgroundColor: AppDesign.primaryBg,
          body: viewModel.isLoading
              ? _buildLoadingState()
              : viewModel.errorMessage != null
                  ? _buildErrorState(viewModel.errorMessage!)
                  : _buildContent(context, viewModel),
        );
      },
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
  Widget _buildContent(BuildContext context, ProfileViewModel viewModel) =>
      SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const TripNestHeader(trailing: TripNestSocialActions()),
              const SizedBox(height: 18),
              _ProfileHero(viewModel: viewModel, onInfo: _showMyInfo),
              const SizedBox(height: 22),
              Row(children: [
                const Expanded(
                    child: Text('최근 저장한 장소', style: AppDesign.headingSmall)),
                TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/marker_list'),
                    child: const Text('전체보기 ›',
                        style: TextStyle(
                            fontSize: 12, color: AppDesign.secondaryText)))
              ]),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                  future: _recent,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return TextButton(
                          onPressed: () => setState(() => _recent =
                              MarkerService().getRecentMarkers(limit: 4)),
                          child: const Text('장소를 다시 불러오기'));
                    }
                    final places =
                        (snapshot.data ?? []).map(MarkerModel.fromMap).toList();
                    if (places.isEmpty) {
                      return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('저장한 장소가 아직 없어요.',
                              style: AppDesign.bodySmall));
                    }
                    return SizedBox(
                        height: 154,
                        child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: places.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final place = places[index];
                              return SizedBox(
                                  width:
                                      (MediaQuery.sizeOf(context).width - 56) /
                                          4,
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                        context,
                                        AppPageRoute(
                                            builder: (_) => MarkerDetailView(
                                                marker: MarkerMapAdapter
                                                    .toGoogleMarker(place),
                                                keyword: place.keyword))),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ReferencePhoto(
                                              title: place.title,
                                              address: place.address,
                                              width: double.infinity,
                                              height: 84),
                                          const SizedBox(height: 7),
                                          Row(children: [
                                            Icon(
                                                placeKeywordIcon(place.keyword),
                                                size: 13,
                                                color: AppDesign.primaryText),
                                            const SizedBox(width: 4),
                                            Expanded(
                                                child: Text(place.keyword,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: AppDesign
                                                            .secondaryText))),
                                          ]),
                                          const SizedBox(height: 3),
                                          Text(place.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 3),
                                          Text(place.address,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppDesign.secondaryText)),
                                        ]),
                                  ));
                            }));
                  }),
              const SizedBox(height: 18),
              ReferenceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(children: [
                    _profileMenu(Icons.person_outline, '내 정보', _showMyInfo),
                    _profileMenu(
                        Icons.people_outline,
                        '협업 리스트',
                        () => Navigator.push(
                            context,
                            AppPageRoute(
                                builder: (_) =>
                                    const ListPage(initialFilter: 2)))),
                    _profileMenu(
                        Icons.notifications_none_outlined,
                        '알림 설정',
                        () => Navigator.pushNamed(
                            context, '/notification_settings')),
                    _profileMenu(
                        Icons.settings_outlined,
                        '앱 설정',
                        () => Navigator.push(
                            context,
                            AppPageRoute(
                                builder: (_) => const SecuritySettingsView()))),
                    _profileMenu(
                        Icons.logout, '로그아웃', () => _handleLogout(context),
                        last: true),
                  ])),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () => _handleAccountDeletion(context),
                  child: Text('계정 탈퇴',
                      style:
                          TextStyle(color: Colors.red.shade400, fontSize: 12))),
            ]),
      );
  void _showMyInfo() {
    final user = Supabase.instance.client.auth.currentUser;
    showAppSheet<void>(
        context: context,
        builder: (sheet) => AppSheet(
              title: '내 정보',
              subtitle: 'TripNest에서 사용 중인 프로필이에요.',
              children: [
                ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('닉네임', style: AppDesign.caption),
                    subtitle: Text(
                        context.read<ProfileViewModel>().nickname ?? '여행자',
                        style: AppDesign.bodyMedium)),
                const Divider(color: AppDesign.separator),
                ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('이메일', style: AppDesign.caption),
                    subtitle: Text(user?.email ?? '등록된 이메일이 없어요',
                        style: AppDesign.bodyMedium)),
              ],
            ));
  }

  Widget _profileMenu(IconData icon, String title, VoidCallback onTap,
          {bool last = false}) =>
      Container(
        decoration: BoxDecoration(
            border: last
                ? null
                : const Border(
                    bottom: BorderSide(color: AppDesign.borderColor))),
        child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
            leading: Icon(icon, size: 27, color: AppDesign.primaryText),
            title: Text(title, style: const TextStyle(fontSize: 16)),
            trailing:
                const Icon(Icons.chevron_right, color: AppDesign.secondaryText),
            onTap: onTap),
      );

  // ================================
  // 로그아웃 처리
  // ================================
  Future<void> _handleLogout(BuildContext context) async {
    final signedOut = await context.read<ProfileViewModel>().signOut();
    if (!context.mounted) return;
    if (signedOut) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login_option',
        (route) => false,
      );
      return;
    }
    if (!context.mounted) return;
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

  // ================================
  // 계정 탈퇴 처리
  // ================================
  Future<void> _handleAccountDeletion(BuildContext context) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => const AppConfirmDialog(
            title: '계정을 영구 삭제할까요?',
            message: '모든 마커, 리스트, 알림과 친구 관계가 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
            confirmLabel: '영구 삭제',
            destructive: true,
            icon: Icons.person_off_outlined));

    if (confirm != true) return;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppLoadingDialog(message: '계정을 삭제하고 있어요.'),
    );

    final viewModel = context.read<ProfileViewModel>();
    final success = await viewModel.deleteAccount();

    if (!context.mounted) return;
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
    if (!context.mounted) return;
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
  final VoidCallback onInfo;
  const _ProfileHero({required this.viewModel, required this.onInfo});
  @override
  Widget build(BuildContext context) {
    final raw =
        Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_url'];
    final avatar = raw is String && Uri.tryParse(raw)?.hasAbsolutePath == true
        ? raw
        : null;
    return ReferenceCard(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            CircleAvatar(
                radius: 40,
                backgroundColor: AppDesign.lightGray,
                foregroundImage: avatar == null ? null : NetworkImage(avatar),
                child: const Icon(Icons.person_outline,
                    size: 42, color: AppDesign.secondaryText)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(viewModel.nickname ?? '여행자',
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('나만의 여행 지도를 만드는 중', style: AppDesign.bodySmall),
                ])),
            IconButton(
                onPressed: onInfo,
                tooltip: '내 정보',
                icon: const Icon(Icons.chevron_right,
                    color: AppDesign.secondaryText)),
          ]),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppDesign.borderColor),
          const SizedBox(height: 14),
          IntrinsicHeight(
              child: Row(children: [
            _stat('내 장소', viewModel.stats?['markers'] ?? 0),
            const VerticalDivider(width: 1, color: AppDesign.borderColor),
            _stat('리스트', viewModel.stats?['lists'] ?? 0),
            const VerticalDivider(width: 1, color: AppDesign.borderColor),
            _stat('공유 링크', viewModel.stats?['shared_links'] ?? 0),
          ])),
        ]));
  }

  Widget _stat(String label, int count) => Expanded(
          child: Column(children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppDesign.secondaryText)),
        const SizedBox(height: 5),
        Text('$count',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      ]));
}
