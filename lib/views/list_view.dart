import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/list_viewmodel.dart';
import 'marker_info_view.dart';
import '../viewmodels/collaborator_viewmodel.dart';
import '../design/app_design.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                          padding: const EdgeInsets.all(24),
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
      floatingActionButton: _buildPremiumFAB(),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildPremiumAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppDesign.softShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                        (route) => false,
                  );
                },
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppDesign.primaryText,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(ListViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppDesign.travelPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppDesign.travelPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            '나의 컬렉션',
            style: AppDesign.caption.copyWith(
              color: AppDesign.travelPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppDesign.spacing12),
        const Text('여행 리스트', style: AppDesign.headingXL),
        const SizedBox(height: AppDesign.spacing8),
        Text(
          '${viewModel.lists.length}개의 여행 계획이 저장되어 있어요 📝',
          style: AppDesign.bodyLarge.copyWith(
            color: AppDesign.secondaryText,
          ),
        ),
      ],
    );
  }

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
          color: Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListGrid(ListViewModel viewModel) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final list = viewModel.lists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDesign.spacing16),
            child: _PremiumListCard(
              list: list,
              onTap: () => _showListOptions(context, list.id, viewModel),
            ),
          );
        },
        childCount: viewModel.lists.length,
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDesign.glowShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showCreateListDialog(context),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context) {
    final TextEditingController listNameController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              boxShadow: AppDesign.elevatedShadow,
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppDesign.greenGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.add_location_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing20),
                Text(
                  '새 리스트 만들기',
                  style: AppDesign.headingMedium,
                ),
                const SizedBox(height: AppDesign.spacing8),
                Text(
                  '새로운 여행 계획을 시작해보세요',
                  style: AppDesign.bodyMedium.copyWith(
                    color: AppDesign.secondaryText,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing24),
                Container(
                  decoration: BoxDecoration(
                    color: AppDesign.lightGray,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                    border: Border.all(
                      color: AppDesign.borderColor,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: listNameController,
                    decoration: const InputDecoration(
                      hintText: '리스트 이름을 입력하세요',
                      hintStyle: TextStyle(color: AppDesign.subtleText),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    style: AppDesign.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppDesign.lightGray,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                            onTap: () => Navigator.of(context).pop(),
                            child: Center(
                              child: Text(
                                '취소',
                                style: AppDesign.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDesign.spacing12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppDesign.primaryGradient,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                          boxShadow: AppDesign.softShadow,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                            onTap: () async {
                              final name = listNameController.text.trim();
                              if (name.isNotEmpty) {
                                await Provider.of<ListViewModel>(context, listen: false)
                                    .createList(name);
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Center(
                              child: Text(
                                '생성',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCollaborationDialog(BuildContext context, String listId) {
    final collaboratorVM = Provider.of<CollaboratorViewModel>(context, listen: false);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        collaboratorVM.getCollaborators(listId);
        collaboratorVM.getFriends();

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
                          gradient: AppDesign.primaryGradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppDesign.radiusLarge),
                            topRight: Radius.circular(AppDesign.radiusLarge),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.group_add,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: AppDesign.spacing12),
                            const Expanded(
                              child: Text(
                                '친구 초대',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => Navigator.of(dialogContext).pop(),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
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
                              : vm.friends.isEmpty
                              ? _buildNoFriendsState()
                              : _buildFriendsList(vm, listId, context),
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

  Widget _buildFriendsList(CollaboratorViewModel vm, String listId, BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: vm.friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDesign.spacing8),
      itemBuilder: (context, index) {
        final friend = vm.friends[index];
        final nickname = friend['nickname'] as String;
        final isAlreadyCollaborator = vm.collaborators.contains(nickname);

        return Container(
          decoration: BoxDecoration(
            color: AppDesign.lightGray,
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            border: Border.all(
              color: isAlreadyCollaborator
                  ? AppDesign.travelGreen.withOpacity(0.3)
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAlreadyCollaborator
                              ? AppDesign.travelGreen.withOpacity(0.1)
                              : AppDesign.travelBlue.withOpacity(0.1),
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
                          final success = await vm.addCollaborator(listId, nickname);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$nickname님을 초대했습니다'),
                                backgroundColor: AppDesign.travelGreen,
                              ),
                            );
                            await vm.getCollaborators(listId);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
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
                      color: AppDesign.travelGreen.withOpacity(0.1),
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

  void _showListOptions(BuildContext context, String listId, ListViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppDesign.cardBg,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDesign.radiusLarge),
            ),
            boxShadow: AppDesign.elevatedShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 핸들바
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppDesign.subtleText,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppDesign.spacing24),

                // 리스트 열기
                _OptionCard(
                  icon: Icons.open_in_new,
                  iconColor: AppDesign.travelBlue,
                  title: '리스트 열기',
                  subtitle: '저장된 장소들을 확인해보세요',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarkerInfoPage(listId: listId),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppDesign.spacing12),

                // 협업 관리
                _OptionCard(
                  icon: Icons.group,
                  iconColor: AppDesign.travelPurple,
                  title: '협업 관리',
                  subtitle: '친구들과 함께 여행을 계획해보세요',
                  onTap: () {
                    Navigator.pop(context);
                    _showCollaborationDialog(context, listId);
                  },
                ),

                const SizedBox(height: AppDesign.spacing12),

                // 리스트 삭제
                _OptionCard(
                  icon: Icons.delete_forever,
                  iconColor: Colors.red,
                  title: '리스트 삭제',
                  subtitle: '이 작업은 되돌릴 수 없습니다',
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await _showDeleteConfirmDialog(context);
                    if (confirm == true) {
                      await viewModel.deleteList(listId);
                    }
                  },
                ),

                const SizedBox(height: AppDesign.spacing24),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              boxShadow: AppDesign.elevatedShadow,
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing20),
                Text(
                  '정말 삭제하시겠습니까?',
                  style: AppDesign.headingMedium.copyWith(
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing8),
                Text(
                  '이 작업은 되돌릴 수 없으며,\n모든 데이터가 영구적으로 삭제됩니다.',
                  style: AppDesign.bodyMedium.copyWith(
                    color: AppDesign.secondaryText,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDesign.spacing24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppDesign.lightGray,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                            onTap: () => Navigator.of(context).pop(false),
                            child: Center(
                              child: Text(
                                '취소',
                                style: AppDesign.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDesign.spacing12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                            onTap: () => Navigator.of(context).pop(true),
                            child: const Center(
                              child: Text(
                                '삭제',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================================
// 프리미엄 리스트 카드 컴포넌트
// ================================
class _PremiumListCard extends StatefulWidget {
  final dynamic list; // ListModel 타입
  final VoidCallback onTap;

  const _PremiumListCard({
    required this.list,
    required this.onTap,
  });

  @override
  State<_PremiumListCard> createState() => _PremiumListCardState();
}

class _PremiumListCardState extends State<_PremiumListCard>
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
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              boxShadow: AppDesign.softShadow,
              border: Border.all(
                color: AppDesign.borderColor,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildListIcon(),
                  const SizedBox(width: AppDesign.spacing16),
                  Expanded(child: _buildListInfo()),
                  _buildActionButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDesign.softShadow,
      ),
      child: const Icon(
        Icons.folder_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildListInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.list.name,
          style: AppDesign.headingSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDesign.spacing8),
        _buildInfoRow(
          Icons.place_outlined,
          '마커 ${widget.list.markerCount}개',
          AppDesign.travelBlue,
        ),
        const SizedBox(height: AppDesign.spacing4),
        _buildInfoRow(
          Icons.people_outline,
          '협업자 ${widget.list.collaboratorCount ?? 0}명',
          AppDesign.travelPurple,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: AppDesign.spacing4),
        Text(
          text,
          style: AppDesign.bodyMedium.copyWith(
            color: AppDesign.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppDesign.lightGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.more_vert,
        color: AppDesign.subtleText,
        size: 20,
      ),
    );
  }

  void _handleTapUp() {
    _animationController.reverse();
    widget.onTap();
  }
}

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
                    color: widget.iconColor.withOpacity(0.1),
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