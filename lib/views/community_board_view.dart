import '../navigation/app_page_route.dart';
import '../widgets/community_post_photo.dart';
import '../widgets/app_photo_hero.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../design/app_design.dart';
import '../models/community_post_model.dart';
import '../viewmodels/community_board_viewmodel.dart';
import '../widgets/tripnest_navigation.dart';
import 'community_post_detail_view.dart';

class CommunityBoardView extends StatelessWidget {
  const CommunityBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommunityBoardViewModel()..loadPosts(),
      child: const _CommunityBoardBody(),
    );
  }
}

class _CommunityBoardBody extends StatelessWidget {
  const _CommunityBoardBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommunityBoardViewModel>();

    return Scaffold(
      bottomNavigationBar: const TripNestNavigation(currentRoute: '/community'),
      backgroundColor: AppDesign.primaryBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppDesign.primaryBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const TripNestHeader(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: LayoutBuilder(builder: (context, constraints) {
                final button = FilledButton.icon(
                  onPressed: () => _showPostComposer(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('장소 공유'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppDesign.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                );
                final compact = constraints.maxWidth < 350 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.2;
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compact)
                        const Text('여행 이야기', style: AppDesign.headingXL)
                      else
                        Row(children: [
                          const Expanded(
                              child:
                                  Text('여행 이야기', style: AppDesign.headingXL)),
                          const SizedBox(width: 8),
                          button,
                        ]),
                      const SizedBox(height: 6),
                      const Text('여행자들이 발견한 장소를 만나보세요',
                          style: AppDesign.bodySmall),
                      if (compact) ...[
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerRight, child: button),
                      ],
                    ]);
              }),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: viewModel.loadPosts,
                child: Builder(
                  builder: (context) {
                    if (viewModel.isLoading && viewModel.posts.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (viewModel.errorMessage != null &&
                        viewModel.posts.isEmpty) {
                      // ===== 디버깅 로그 추가 =====
                      debugPrint('🚨 Error Screen Shown');
                      debugPrint(
                          '   - errorMessage: ${viewModel.errorMessage}');
                      debugPrint(
                          '   - posts.length: ${viewModel.posts.length}');
                      debugPrint(
                          '   - posts.isEmpty: ${viewModel.posts.isEmpty}');
                      // ============================

                      return _BoardMessage(
                        icon: Icons.cloud_off_outlined,
                        message: viewModel.errorMessage!,
                        actionLabel: '다시 시도',
                        onAction: viewModel.loadPosts,
                      );
                    }

                    if (viewModel.posts.isEmpty) {
                      return _BoardMessage(
                        icon: Icons.edit_note_outlined,
                        message: '첫 여행 이야기를 남겨보세요',
                        actionLabel: '글쓰기',
                        onAction: () => _showPostComposer(context),
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: viewModel.posts.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        if (index == 0) {
                          return _BoardIntroBanner(
                              postCount: viewModel.posts.length);
                        }
                        return _PostCard(post: viewModel.posts[index - 1]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPostComposer(BuildContext context) async {
    final viewModel = context.read<CommunityBoardViewModel>();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostComposerSheet(viewModel: viewModel),
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('여행 이야기를 공유했습니다')),
      );
    }
  }
}

/// A quiet section label keeps the shared places as the focus.
class _BoardIntroBanner extends StatelessWidget {
  const _BoardIntroBanner({required this.postCount});
  final int postCount;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          const Expanded(child: Text('최근 이야기', style: AppDesign.headingSmall)),
          Text('$postCount개', style: AppDesign.bodySmall),
        ]),
      );
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final CommunityPost post;

  Future<void> _open(BuildContext context) async {
    final board = context.read<CommunityBoardViewModel>();
    await Navigator.of(context).push(
        AppPageRoute(builder: (_) => CommunityPostDetailView(post: post)));
    if (context.mounted) await board.loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<CommunityBoardViewModel>();
    final date = DateFormat('M월 d일').format(post.createdAt.toLocal());
    final location = post.placeAddress ?? post.destination;
    return Material(
      color: AppDesign.cardBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppDesign.borderColor)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _PostAvatar(nickname: post.authorNickname),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(post.authorNickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppDesign.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('$date · ${post.isMarkerShare ? '장소 공유' : '여행 이야기'}',
                        style: AppDesign.bodySmall),
                  ])),
            ]),
            const SizedBox(height: 14),
            if (post.isMarkerShare) ...[
              AppPhotoHero(tag: 'community-photo-${post.id}',
                child: ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(aspectRatio: 1.85, child: CommunityPostPhoto(post: post))),
              ),
              const SizedBox(height: 12),
            ],
            Text(post.placeTitle ?? post.title,
                style: AppDesign.headingSmall
                    .copyWith(fontWeight: FontWeight.w700)),
            if (location != null && location.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppDesign.secondaryText),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppDesign.bodySmall)),
              ]),
            ],
            if (post.content.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(post.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppDesign.bodyMedium
                      .copyWith(fontWeight: FontWeight.w400)),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppDesign.separator),
            Row(children: [
              TextButton.icon(
                onPressed: board.pendingLikes.contains(post.id)
                    ? null
                    : () async {
                        final error = await board.toggleLike(post.id);
                        if (context.mounted && error != null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(error)));
                        }
                      },
                style: TextButton.styleFrom(
                    foregroundColor: AppDesign.secondaryText),
                icon: Icon(
                    board.likedPosts.contains(post.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 22),
                label: Text('${board.likeCounts[post.id] ?? 0}',
                    semanticsLabel: '좋아요 ${board.likeCounts[post.id] ?? 0}개'),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: () => _open(context),
                style: TextButton.styleFrom(
                    foregroundColor: AppDesign.secondaryText),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 21),
                label: Text('${board.commentCounts[post.id] ?? 0}',
                    semanticsLabel: '댓글 ${board.commentCounts[post.id] ?? 0}개'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _PostAvatar extends StatelessWidget {
  const _PostAvatar({required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 18,
        backgroundColor: AppDesign.secondaryBg,
        child: Text(nickname.trim().isEmpty ? '?' : nickname.characters.first,
            style: AppDesign.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _BoardMessage extends StatelessWidget {
  const _BoardMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 260,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: AppDesign.label3),
                const SizedBox(height: 14),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(message,
                        textAlign: TextAlign.center,
                        style: AppDesign.bodyMedium)),
                const SizedBox(height: 16),
                _PrimaryButton(label: actionLabel, onPressed: onAction),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PostComposerSheet extends StatefulWidget {
  const _PostComposerSheet({required this.viewModel});

  final CommunityBoardViewModel viewModel;

  @override
  State<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends State<_PostComposerSheet> {
  final _contentController = TextEditingController();
  CommunityMarker? _selectedMarker;
  bool _isSubmitting = false;

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadMyMarkers();
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유할 마커를 선택해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await widget.viewModel.createMarkerPost(
      marker: _selectedMarker!,
      content: _contentController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.viewModel.errorMessage ?? '게시물을 등록하지 못했습니다.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final viewModel = widget.viewModel;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppDesign.cardBg,
            borderRadius: const BorderRadius.all(AppDesign.r16),
            boxShadow: AppDesign.elevatedShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppDesign.separator,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('장소 공유하기', style: AppDesign.headingMedium),
                const SizedBox(height: AppDesign.spacing6),
                Text('내가 저장한 장소를 다른 여행자에게 추천해보세요', style: AppDesign.bodySmall),
                const SizedBox(height: AppDesign.spacing20),
                _MarkerSelector(
                  markers: viewModel.myMarkers,
                  value: _selectedMarker,
                  isLoading: viewModel.isLoadingMarkers,
                  onChanged: (marker) =>
                      setState(() => _selectedMarker = marker),
                ),
                const SizedBox(height: 12),
                _ComposerField(
                  controller: _contentController,
                  label: '추천 이유 (선택)',
                  minLines: 4,
                  maxLines: 6,
                ),
                const SizedBox(height: 20),
                _PrimaryButton(
                  label: _isSubmitting ? '등록 중...' : '장소 공유하기',
                  onPressed: _isSubmitting || viewModel.isLoadingMarkers
                      ? null
                      : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkerSelector extends StatelessWidget {
  const _MarkerSelector({
    required this.markers,
    required this.value,
    required this.isLoading,
    required this.onChanged,
  });

  final List<CommunityMarker> markers;
  final CommunityMarker? value;
  final bool isLoading;
  final ValueChanged<CommunityMarker?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (markers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppDesign.lightGray,
          borderRadius: const BorderRadius.all(AppDesign.r12),
          border: Border.all(color: AppDesign.borderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.place_outlined, color: AppDesign.label3),
            SizedBox(width: 10),
            Expanded(
              child: Text('공유할 마커가 없습니다. 먼저 지도에서 장소를 저장해주세요.',
                  style: AppDesign.bodySmall),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<CommunityMarker>(
      initialValue: value,
      isExpanded: true,
      hint: const Text('공유할 마커 선택'),
      decoration: InputDecoration(
        labelText: '내 마커',
        labelStyle: AppDesign.bodySmall,
        filled: true,
        fillColor: AppDesign.lightGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppDesign.r12),
          borderSide: const BorderSide(color: AppDesign.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppDesign.r12),
          borderSide: const BorderSide(color: AppDesign.primary, width: 1.5),
        ),
      ),
      items: markers
          .map(
            (marker) => DropdownMenuItem(
              value: marker,
              child: Text(
                '${marker.title} · ${marker.address}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppDesign.bodyMedium,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ComposerField extends StatelessWidget {
  const _ComposerField({
    required this.controller,
    required this.label,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: AppDesign.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppDesign.bodySmall,
        alignLabelWithHint: minLines != null,
        filled: true,
        fillColor: AppDesign.lightGray,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppDesign.r12),
          borderSide: const BorderSide(color: AppDesign.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppDesign.r12),
          borderSide: const BorderSide(color: AppDesign.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.all(AppDesign.r12),
        onTap: onPressed,
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            gradient: enabled ? AppDesign.primaryGradient : null,
            color: enabled ? null : AppDesign.borderColor,
            borderRadius: const BorderRadius.all(AppDesign.r12),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
