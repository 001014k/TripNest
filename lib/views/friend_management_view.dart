import '../widgets/app_overlays.dart';
import 'package:provider/provider.dart';
import '../viewmodels/friend_management_viewmodel.dart';
import 'package:flutter/material.dart';
import '../design/app_design.dart'; // AppDesign 임포트 추가

class FriendManagementView extends StatefulWidget {
  const FriendManagementView({super.key});

  @override
  State<FriendManagementView> createState() => _FriendManagementViewState();
}

class _FriendManagementViewState extends State<FriendManagementView>
    with TickerProviderStateMixin {
  FriendManagementViewModel? _viewModel;

  // late 변수들은 선언 시점에 바로 빈 Future로 초기화하여 에러 방지
  Future<List<Map<String, dynamic>>> _receivedRequestsFuture = Future.value([]);
  Future<List<Map<String, dynamic>>> _friendsListFuture = Future.value([]);

  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = Provider.of<FriendManagementViewModel>(context);
    if (!identical(_viewModel, vm)) {
      _viewModel?.removeListener(_handleViewModelUpdate);
      _viewModel = vm;
      vm.addListener(_handleViewModelUpdate);
      _receivedRequestsFuture = vm.getReceivedFriendRequests();
      _friendsListFuture = vm.getFriendsList();
    }
  }

  @override
  void dispose() {
    // 4. null 체크 후 리스너 해제
    _viewModel?.removeListener(_handleViewModelUpdate);
    _fadeAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );
    _fadeAnimationController.forward();
  }

  void _refreshData() {
    if (_viewModel == null) return;

    setState(() {
      _receivedRequestsFuture =
          _viewModel?.getReceivedFriendRequests() ?? Future.value([]);
      _friendsListFuture = _viewModel?.getFriendsList() ?? Future.value([]);
    });
  }

  void _handleViewModelUpdate() {
    if (mounted) {
      _refreshData();
    }
  }

  void _showResult(String? message) {
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.primaryBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDesign.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // 프리미엄 헤더
                _buildPremiumHeader(context),

                // 통계 카드
                _buildStatsCard(),

                // 탭 바
                _buildTabBar(),

                // 탭 뷰
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildFriendsListTab(),
                      _buildFriendRequestsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildPremiumFAB(),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 뒤로가기 버튼
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppDesign.cardBg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                  boxShadow: AppDesign.softShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppDesign.primaryText,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // 친구 아이콘
              Container(
                padding: const EdgeInsets.all(AppDesign.spacing12),
                decoration: BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppDesign.glowShadow,
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing32),
          // 타이틀 섹션
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppDesign.travelPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppDesign.travelPurple.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              '소셜',
              style: AppDesign.caption.copyWith(
                color: AppDesign.travelPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppDesign.spacing12),
          const Text('친구 관리', style: AppDesign.headingXL),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            '함께 여행할 친구들과 연결하세요 👥',
            style: AppDesign.bodyLarge.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppDesign.travelBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _friendsListFuture,
        builder: (context, friendsSnapshot) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _receivedRequestsFuture,
            builder: (context, requestsSnapshot) {
              final friendsCount = friendsSnapshot.data?.length ?? 0;
              final requestsCount = requestsSnapshot.data?.length ?? 0;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.group_rounded,
                    friendsCount.toString(),
                    '친구',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  _buildStatItem(
                    Icons.person_add_rounded,
                    requestsCount.toString(),
                    '새 요청',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  _buildStatItem(
                    Icons.public_rounded,
                    '온라인',
                    '상태',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
        const SizedBox(height: AppDesign.spacing8),
        Text(
          value,
          style: AppDesign.headingMedium.copyWith(
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: AppDesign.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: AppDesign.softShadow,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppDesign.whiteText,
        unselectedLabelColor: AppDesign.secondaryText,
        labelStyle: AppDesign.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        indicator: BoxDecoration(
          gradient: AppDesign.primaryGradient,
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: AppDesign.spacing8),
                const Text('친구 목록'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline, size: 18),
                const SizedBox(width: AppDesign.spacing8),
                const Text('친구 요청'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _receivedRequestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _buildEmptyRequestsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final nickname = request['requester']['nickname'] ?? '알 수 없음';
    final requesterId = request['requester_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing16),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.spacing20),
        child: Row(
          children: [
            // 프로필 아바타
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppDesign.sunsetGradient,
                shape: BoxShape.circle,
                boxShadow: AppDesign.softShadow,
              ),
              child: Center(
                child: Text(
                  nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                  style: AppDesign.headingSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDesign.spacing16),
            // 닉네임
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: AppDesign.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDesign.spacing4),
                  Text(
                    '친구 요청을 보냈습니다',
                    style: AppDesign.caption.copyWith(
                      color: AppDesign.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            // 액션 버튼들
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.check_rounded,
                  color: AppDesign.travelGreen,
                  onTap: () async {
                    _showResult(
                      await _viewModel?.acceptFriendRequest(requesterId),
                    );
                    _refreshData();
                  },
                ),
                const SizedBox(width: AppDesign.spacing8),
                _buildActionButton(
                  icon: Icons.close_rounded,
                  color: Colors.red.shade400,
                  onTap: () async {
                    _showResult(
                      await _viewModel?.declineFriendRequest(requesterId),
                    );
                    _refreshData();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
          onTap: onTap,
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsListTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _friendsListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return _buildEmptyFriendsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFriendCard(friend, index);
          },
        );
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend, int index) {
    final nickname = friend['nickname'] ?? '알 수 없음';
    final isOnline = friend['is_online'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppDesign.primaryText.withValues(alpha: 0.9),
            AppDesign.primaryText,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing20),
            child: Row(
              children: [
                // 프로필 아바타
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                          style: AppDesign.headingSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // 온라인 상태 표시
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isOnline ? AppDesign.travelGreen : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppDesign.primaryText,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppDesign.spacing16),
                // 닉네임과 상태
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: AppDesign.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDesign.spacing4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesign.spacing8,
                          vertical: AppDesign.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppDesign.travelGreen.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppDesign.radiusXL),
                        ),
                        child: Text(
                          isOnline ? '온라인' : '오프라인',
                          style: AppDesign.caption.copyWith(
                            color: isOnline
                                ? AppDesign.travelGreen
                                : Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 더보기 메뉴
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                  ),
                  color: AppDesign.cardBg,
                  onSelected: (value) {
                    if (value == '삭제') {
                      _showDeleteConfirmDialog(context, friend['id'], nickname);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: '삭제',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_remove_rounded,
                            color: Colors.red.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: AppDesign.spacing12),
                          Text(
                            '친구 삭제',
                            style: AppDesign.bodyMedium.copyWith(
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, String friendId, String nickname) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AppConfirmDialog(
            title: '친구를 삭제할까요?',
            message: '$nickname 님을 친구 목록에서 삭제합니다.',
            confirmLabel: '삭제',
            destructive: true,
            icon: Icons.person_remove_outlined));
    if (confirmed == true && mounted) {
      final message = await _viewModel?.removeFriend(friendId);
      if (mounted) _showResult(message);
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesign.spacing24),
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              shape: BoxShape.circle,
              boxShadow: AppDesign.softShadow,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppDesign.spacing24),
          Text(
            '불러오는 중...',
            style: AppDesign.bodyLarge.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDesign.spacing32),
        padding: const EdgeInsets.all(AppDesign.spacing32),
        decoration: BoxDecoration(
          color: AppDesign.cardBg,
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          boxShadow: AppDesign.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 48,
            ),
            const SizedBox(height: AppDesign.spacing16),
            Text(
              '오류가 발생했습니다',
              style: AppDesign.headingSmall,
            ),
            const SizedBox(height: AppDesign.spacing8),
            Text(
              error,
              style: AppDesign.bodyMedium.copyWith(
                color: AppDesign.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppDesign.travelBlue.withValues(alpha: 0.1),
                  AppDesign.travelPurple.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: AppDesign.travelBlue,
              size: 48,
            ),
          ),
          const SizedBox(height: AppDesign.spacing24),
          Text(
            '받은 친구 요청이 없습니다',
            style: AppDesign.headingSmall,
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            '새로운 친구 요청을 기다리고 있어요',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFriendsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppDesign.travelPurple.withValues(alpha: 0.1),
                  AppDesign.travelBlue.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: AppDesign.travelPurple,
              size: 48,
            ),
          ),
          const SizedBox(height: AppDesign.spacing24),
          Text(
            '아직 친구가 없습니다',
            style: AppDesign.headingSmall,
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            '친구를 추가하고 함께 여행을 계획해보세요',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: [
          ...AppDesign.elevatedShadow,
          BoxShadow(
            color: AppDesign.travelBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          onTap: () => _showFriendRequestDialog(context),
          child: const Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _showFriendRequestDialog(BuildContext context) async {
    final nickname = await showDialog<String>(
        context: context,
        builder: (_) => const AppTextInputDialog(
            title: '친구 요청 보내기',
            subtitle: '함께 여행할 친구의 닉네임을 입력해주세요.',
            hint: '닉네임을 입력해주세요',
            submitLabel: '요청 보내기',
            icon: Icons.alternate_email_rounded));
    if (nickname == null || !mounted) return;
    final result = await _viewModel?.sendFriendRequest(nickname);
    if (!mounted) return;
    _showResult(result);
    _refreshData();
  }
}
