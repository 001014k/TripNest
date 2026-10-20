import '../widgets/travel_list_card.dart';
import '../navigation/app_page_route.dart';
import '../widgets/app_overlays.dart';
import '../widgets/reference_design.dart';
import '../widgets/tripnest_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../viewmodels/list_viewmodel.dart';
import 'marker_info_view.dart';
import '../viewmodels/collaborator_viewmodel.dart';
import '../design/app_design.dart';

class ListPage extends StatefulWidget {
  final int initialFilter;
  const ListPage({super.key, this.initialFilter = 0});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  int _filter = 0;
  String _query = '';
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _initializeAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ListViewModel>();
      viewModel.loadLists();
    });
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const TripNestNavigation(currentRoute: '/list'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: Consumer<ListViewModel>(
            builder: (context, viewModel, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 프리미엄 앱바
                    SliverToBoxAdapter(
                      child: _buildPremiumAppBar(),
                    ),

                    // 헤더 섹션
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildPageHeader(viewModel),
                      ),
                    ),

                    // 컨텐츠 영역
                    if (viewModel.isLoading)
                      SliverToBoxAdapter(
                        child: _buildLoadingState(),
                      )
                    else if (viewModel.errorMessage != null)
                      SliverToBoxAdapter(
                        child: _buildErrorState(viewModel.errorMessage!),
                      )
                    else if (viewModel.lists.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: _buildListGrid(viewModel),
                      ),

                    // 하단 여백
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100), // FAB을 위한 여백
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildPremiumAppBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const TripNestHeader(),
      );

  Widget _buildPageHeader(ListViewModel viewModel) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(
                child: Text('내 여행 리스트',
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8))),
            _headerAction(
                Icons.add, '리스트 만들기', () => _showCreateListDialog(context)),
            const SizedBox(width: 8),
            _headerAction(Icons.search, '리스트 검색',
                () => setState(() => _searchVisible = !_searchVisible)),
          ]),
          const SizedBox(height: 8),
          const Text('저장한 여행 리스트를 확인하고 관리해보세요.',
              style: TextStyle(fontSize: 12, color: AppDesign.secondaryText)),
          if (_searchVisible) ...[
            const SizedBox(height: 14),
            ReferenceSearch(
                hint: '여행 리스트 검색',
                onChanged: (value) => setState(() => _query = value))
          ],
          const SizedBox(height: 18),
          Row(
              children: List.generate(
                  3,
                  (index) => Expanded(
                          child: Padding(
                        padding: EdgeInsets.only(right: index < 2 ? 7 : 0),
                        child: Material(
                            color: _filter == index
                                ? AppDesign.primary
                                : Colors.white,
                            shape: StadiumBorder(
                                side: BorderSide(
                                    color: _filter == index
                                        ? AppDesign.primary
                                        : AppDesign.borderColor)),
                            child: InkWell(
                                customBorder: const StadiumBorder(),
                                onTap: () => setState(() => _filter = index),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Text(
                                        ['전체', '내 리스트', '공유 리스트'][index],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: _filter == index
                                                ? Colors.white
                                                : AppDesign.primaryText))))),
                      )))),
        ],
      );

  Widget _headerAction(IconData icon, String label, VoidCallback action) =>
      Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: const BorderSide(color: AppDesign.borderColor)),
        child: IconButton(
            tooltip: label, onPressed: action, icon: Icon(icon, size: 23)),
      );

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppDesign.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: AppDesign.spacing20),
          Text(
            '리스트를 불러오는 중...',
            style: AppDesign.bodyLarge.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
          ),
          const SizedBox(height: AppDesign.spacing20),
          Text(
            '오류가 발생했습니다',
            style: AppDesign.headingMedium.copyWith(color: Colors.red),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            errorMessage,
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: AppDesign.sunsetGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.elevatedShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.add_location_alt,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: AppDesign.spacing24),
          Text(
            '첫 번째 여행 리스트를\n만들어보세요!',
            style: AppDesign.headingMedium.copyWith(
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDesign.spacing12),
          Text(
            '새로운 여행지를 발견하고 나만의 리스트로 정리해보세요',
            style: AppDesign.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListGrid(ListViewModel viewModel) {
    final lists = viewModel.lists
        .where((list) =>
            (_filter == 0 || (_filter == 1 ? list.isOwner : !list.isOwner)) &&
            list.name.toLowerCase().contains(_query.trim().toLowerCase()))
        .toList();
    if (lists.isEmpty) {
      return const SliverToBoxAdapter(
          child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('조건에 맞는 리스트가 없어요.', textAlign: TextAlign.center)));
    }
    return SliverList.builder(
        itemCount: lists.length,
        itemBuilder: (context, index) {
          final list = lists[index];
          return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TravelListCard(
                list: list,
                onTap: () => _showListOptions(context, list.id, viewModel),
                onOpen: () => Navigator.push(
                    context,
                    AppPageRoute(
                        builder: (_) => MarkerInfoPage(
                            listId: list.id,
                            listName: list.name,
                            collaboratorCount: list.collaboratorCount,
                            onManage: () =>
                                _showListOptions(context, list.id, viewModel),
                            onCollaborate: () =>
                                _showCollaborationDialog(context, list.id)))),
              ));
        });
  }

  void _showCreateListDialog(BuildContext context) async {
    final vm = context.read<ListViewModel>();
    final name = await showDialog<String>(
        context: context,
        builder: (_) => const AppTextInputDialog(
            title: '새 리스트 만들기',
            subtitle: '새로운 여행 계획을 시작해보세요.',
            hint: '리스트 이름을 입력해주세요',
            submitLabel: '만들기',
            icon: Icons.playlist_add_rounded));
    if (name == null || !context.mounted) return;
    await vm.createList(name);
    if (context.mounted && vm.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
    }
  }

  void _showCollaborationDialog(BuildContext context, String listId) {
    final collaboratorVM =
        Provider.of<CollaboratorViewModel>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    // 1. 다이얼로그를 띄우기 전에 데이터 로드 시작
    collaboratorVM.loadListOwner(listId);
    collaboratorVM.getCollaborators(listId);
    collaboratorVM.getFriends(listId);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: collaboratorVM,
          child: Consumer<CollaboratorViewModel>(
            builder: (context, vm, child) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: double.maxFinite,
                  constraints: const BoxConstraints(maxHeight: 500),
                  decoration: BoxDecoration(
                    color: AppDesign.cardBg,
                    borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
                    boxShadow: AppDesign.elevatedShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 헤더
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppDesign.cardBg,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppDesign.radiusLarge),
                            topRight: Radius.circular(AppDesign.radiusLarge),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.group_add,
                              color: AppDesign.primaryText,
                              size: 24,
                            ),
                            const SizedBox(width: AppDesign.spacing12),
                            const Expanded(
                              child: Text(
                                '협업자 관리',
                                style: TextStyle(
                                  color: AppDesign.primaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppDesign.secondaryBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: const Icon(
                                    Icons.close,
                                    color: AppDesign.primaryText,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 컨텐츠
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: vm.isLoading
                              ? _buildCollaborationLoadingState()
                              : vm.hasError
                                  ? Center(
                                      child: Text(vm.error ?? '오류가 발생했습니다'))
                                  : SingleChildScrollView(
                                      // 내용 많아질 경우 대비
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 1. 리스트 주인 섹션
                                          if (vm.listOwnerNickname != null) ...[
                                            Text(
                                              '리스트 주인',
                                              style: AppDesign.headingSmall
                                                  .copyWith(
                                                color: AppDesign.secondaryText,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: AppDesign.spacing8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: AppDesign.spacing16,
                                                vertical: AppDesign.spacing12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppDesign.secondaryBg
                                                    .withValues(alpha: 0.6),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppDesign.radiusMedium),
                                                border: Border.all(
                                                    color:
                                                        AppDesign.borderColor),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: AppDesign
                                                          .travelBlue
                                                          .withValues(
                                                              alpha: 0.12),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.person_rounded,
                                                      color:
                                                          AppDesign.travelBlue,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          AppDesign.spacing16),
                                                  Expanded(
                                                    child: Text(
                                                      vm.listOwnerNickname!,
                                                      style: AppDesign
                                                          .bodyMedium
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  if (vm.isCurrentUserOwner)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppDesign
                                                            .travelGreen
                                                            .withValues(
                                                                alpha: 0.15),
                                                        borderRadius: BorderRadius
                                                            .circular(AppDesign
                                                                .radiusSmall),
                                                      ),
                                                      child: const Text(
                                                        '나',
                                                        style: TextStyle(
                                                          color: AppDesign
                                                              .travelGreen,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                                height: AppDesign.spacing24),
                                          ],

                                          // 2. 협업 중인 멤버 섹션
                                          if (vm.collaborators.isNotEmpty) ...[
                                            Text(
                                              '협업 중인 멤버',
                                              style: AppDesign.headingSmall
                                                  .copyWith(
                                                color: AppDesign.secondaryText,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: AppDesign.spacing8),
                                            ...vm.collaborators.map((member) {
                                              final currentUserId =
                                                  supabase.auth.currentUser?.id;
                                              final isMe = member.userId ==
                                                  currentUserId;
                                              final isOwner =
                                                  vm.isCurrentUserOwner;
                                              final isEditor =
                                                  member.role == 'editor';
                                              final roleColor = isEditor
                                                  ? AppDesign.travelGreen
                                                  : AppDesign.travelOrange;
                                              final roleBg = isEditor
                                                  ? AppDesign.travelGreen
                                                      .withValues(alpha: 0.15)
                                                  : AppDesign.travelOrange
                                                      .withValues(alpha: 0.15);

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom:
                                                        AppDesign.spacing12),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal:
                                                        AppDesign.spacing16,
                                                    vertical:
                                                        AppDesign.spacing12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppDesign.secondaryBg
                                                        .withValues(alpha: 0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppDesign
                                                                .radiusMedium),
                                                    border: Border.all(
                                                        color: AppDesign
                                                            .borderColor),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppDesign
                                                              .travelPurple
                                                              .withValues(
                                                                  alpha: 0.12),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.group_rounded,
                                                          color: AppDesign
                                                              .travelPurple,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: AppDesign
                                                              .spacing16),
                                                      Expanded(
                                                        child: Text(
                                                          member.nickname,
                                                          style: AppDesign
                                                              .bodyMedium
                                                              .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppDesign
                                                                .primaryText,
                                                          ),
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          if (isMe)
                                                            Container(
                                                              margin: const EdgeInsets
                                                                  .only(
                                                                  right: AppDesign
                                                                      .spacing8),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 10,
                                                                vertical: 4,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: AppDesign
                                                                    .travelGreen
                                                                    .withValues(
                                                                        alpha:
                                                                            0.15),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        AppDesign
                                                                            .radiusSmall),
                                                              ),
                                                              child: const Text(
                                                                '나',
                                                                style:
                                                                    TextStyle(
                                                                  color: AppDesign
                                                                      .travelGreen,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),

                                                          // ===== 제거 버튼 (리스트 주인만 볼 수 있음) =====
                                                          if (isOwner && !isMe)
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons
                                                                      .remove_circle_outline,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 22),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(),
                                                              onPressed:
                                                                  () async {
                                                                // 1. ScaffoldMessenger 참조를 변수에 저장
                                                                final messenger =
                                                                    ScaffoldMessenger.of(
                                                                        context);
                                                                final confirm =
                                                                    await _showRemoveConfirmDialog(
                                                                        context,
                                                                        member
                                                                            .nickname);

                                                                if (confirm ==
                                                                    true) {
                                                                  final success =
                                                                      await vm.removeCollaborator(
                                                                          listId,
                                                                          member
                                                                              .userId);
                                                                  if (success) {
                                                                    // 2. 저장된 변수 사용
                                                                    messenger
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text('${member.nickname}님을 제거했습니다'),
                                                                        backgroundColor:
                                                                            AppDesign.travelGreen,
                                                                      ),
                                                                    );
                                                                  } else {
                                                                    messenger
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(vm.errorMessage ??
                                                                                '제거에 실패했습니다'),
                                                                        backgroundColor:
                                                                            Colors.red,
                                                                      ),
                                                                    );
                                                                  }
                                                                }
                                                              },
                                                            )
                                                          else
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 10,
                                                                vertical: 4,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: roleBg,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        AppDesign
                                                                            .radiusSmall),
                                                              ),
                                                              child: Text(
                                                                isEditor
                                                                    ? '편집 가능'
                                                                    : '읽기 전용',
                                                                style:
                                                                    TextStyle(
                                                                  color:
                                                                      roleColor,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                            const SizedBox(
                                                height: AppDesign.spacing24),
                                          ],

                                          // 3. 초대 가능한 친구 섹션
                                          Text(
                                            '초대 가능한 친구',
                                            style:
                                                AppDesign.headingSmall.copyWith(
                                              color: AppDesign.secondaryText,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: AppDesign.spacing8),

                                          if (vm.friends.isEmpty)
                                            _buildNoFriendsState()
                                          else
                                            _buildFriendsList(
                                                vm, listId, messenger),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCollaborationLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
          ),
          SizedBox(height: AppDesign.spacing16),
          Text(
            '친구 목록을 불러오는 중...',
            style: AppDesign.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNoFriendsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppDesign.lightGray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_add_disabled,
              color: AppDesign.subtleText,
              size: 40,
            ),
          ),
          const SizedBox(height: AppDesign.spacing16),
          Text(
            '친구가 없습니다',
            style: AppDesign.headingSmall.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            '먼저 친구를 추가해보세요',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.subtleText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(CollaboratorViewModel vm, String listId,
      ScaffoldMessengerState messenger) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: vm.friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDesign.spacing8),
      itemBuilder: (context, index) {
        final friend = vm.friends[index];
        final nickname = friend['nickname'] as String;
        final isAlreadyCollaborator = vm.collaborators
            .any((collaborator) => collaborator.nickname == nickname);

        return Container(
          decoration: BoxDecoration(
            color: AppDesign.lightGray,
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            border: Border.all(
              color: isAlreadyCollaborator
                  ? AppDesign.travelGreen.withValues(alpha: 0.3)
                  : AppDesign.borderColor,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppDesign.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDesign.spacing12),
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
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAlreadyCollaborator
                              ? AppDesign.travelGreen.withValues(alpha: 0.1)
                              : AppDesign.travelBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAlreadyCollaborator ? '이미 초대됨' : '초대 가능',
                          style: AppDesign.caption.copyWith(
                            color: isAlreadyCollaborator
                                ? AppDesign.travelGreen
                                : AppDesign.travelBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isAlreadyCollaborator)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppDesign.greenGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppDesign.softShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final confirm =
                              await _showInviteConfirmDialog(context, nickname);
                          if (confirm != true) return;

                          final success =
                              await vm.addCollaborator(listId, nickname);
                          if (success) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('$nickname님을 초대했습니다'),
                                backgroundColor: AppDesign.travelGreen,
                              ),
                            );
                            await vm.getCollaborators(listId);
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(vm.errorMessage ?? '초대에 실패했습니다'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                if (isAlreadyCollaborator)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppDesign.travelGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppDesign.travelGreen,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showInviteConfirmDialog(
          BuildContext context, String nickname) =>
      showDialog<bool>(
          context: context,
          builder: (_) => AppConfirmDialog(
              title: '$nickname님을 초대할까요?',
              message: '초대하면 이 친구가 리스트를 함께 편집할 수 있습니다.',
              confirmLabel: '초대',
              icon: Icons.person_add_outlined));

  void _showListOptions(
      BuildContext context, String listId, ListViewModel viewModel) {
    final pageContext = context;
    showAppSheet<void>(
        context: context,
        builder: (sheet) => AppSheet(
              title: '리스트 관리',
              subtitle: '함께하는 친구와 리스트를 관리해보세요.',
              children: [
                AppSheetOption(
                    title: '협업자 관리',
                    subtitle: '친구를 초대하고 함께 편집해요.',
                    icon: Icons.group_outlined,
                    onTap: () {
                      Navigator.pop(sheet);
                      _showCollaborationDialog(pageContext, listId);
                    }),
                AppSheetOption(
                    title: '리스트 삭제',
                    subtitle: '삭제한 리스트는 되돌릴 수 없어요.',
                    icon: Icons.delete_outline,
                    destructive: true,
                    onTap: () async {
                      Navigator.pop(sheet);
                      final confirm =
                          await _showDeleteConfirmDialog(pageContext);
                      if (confirm == true) await viewModel.deleteList(listId);
                    }),
              ],
            ));
  }

  Future<bool?> _showRemoveConfirmDialog(
          BuildContext context, String nickname) =>
      showDialog<bool>(
          context: context,
          builder: (_) => AppConfirmDialog(
              title: '$nickname님을 제외할까요?',
              message: '이 친구는 더 이상 해당 리스트에 접근할 수 없습니다.',
              confirmLabel: '제외',
              destructive: true,
              icon: Icons.person_remove_outlined));

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) =>
      showDialog<bool>(
          context: context,
          builder: (_) => const AppConfirmDialog(
              title: '리스트를 삭제할까요?',
              message: '리스트와 연결된 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
              confirmLabel: '삭제',
              destructive: true,
              icon: Icons.delete_outline));
}

// ================================
// 프리미엄 리스트 카드 컴포넌트
// ================================
// ================================
// 옵션 카드 컴포넌트
// ================================
class _OptionCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppDesign.lightGray,
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              border: Border.all(
                color: AppDesign.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDesign.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppDesign.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: AppDesign.caption.copyWith(
                          color: AppDesign.subtleText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppDesign.subtleText,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTapUp() {
    _animationController.reverse();
    widget.onTap();
  }
}
