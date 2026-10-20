import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../design/app_design.dart';
import '../models/community_post_model.dart';
import '../viewmodels/community_post_detail_viewmodel.dart';
import '../widgets/community_post_photo.dart';
import '../widgets/app_photo_hero.dart';
import '../widgets/tripnest_navigation.dart';

class CommunityPostDetailView extends StatelessWidget {
  const CommunityPostDetailView({required this.post, super.key});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommunityPostDetailViewModel(postId: post.id)..load(),
      child: _CommunityPostDetailBody(post: post),
    );
  }
}

class _CommunityPostDetailBody extends StatefulWidget {
  const _CommunityPostDetailBody({required this.post});

  final CommunityPost post;

  @override
  State<_CommunityPostDetailBody> createState() =>
      _CommunityPostDetailBodyState();
}

class _CommunityPostDetailBodyState extends State<_CommunityPostDetailBody> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(CommunityPostDetailViewModel viewModel) async {
    final created = await viewModel.addComment(_commentController.text);
    if (!mounted) return;

    if (created) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(viewModel.errorMessage ?? '댓글을 입력해주세요')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommunityPostDetailViewModel>();
    final post = widget.post;

    return Scaffold(
      backgroundColor: AppDesign.primaryBg,
      appBar: AppBar(
        backgroundColor: AppDesign.primaryBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: TripNestHeader(onBack: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: viewModel.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(post.isMarkerShare ? '마커 공유' : '여행 이야기',
                        style: AppDesign.headingLarge),
                    const SizedBox(height: 6),
                    Text('여행자가 남긴 장소와 이야기를 만나보세요.', style: AppDesign.bodySmall),
                    const SizedBox(height: 20),
                    _PostDetailCard(post: post),
                    const SizedBox(height: 12),
                    _InteractionBar(viewModel: viewModel),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('댓글', style: AppDesign.headingSmall),
                        const SizedBox(width: 6),
                        Text('${viewModel.comments.length}',
                            style: AppDesign.caption11),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (viewModel.isLoading && viewModel.comments.isEmpty)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ))
                    else if (viewModel.comments.isEmpty)
                      const _EmptyComments()
                    else
                      ...viewModel.comments.map(
                        (comment) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CommentCard(comment: comment),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _CommentComposer(
              controller: _commentController,
              isSubmitting: viewModel.isSubmittingComment,
              onSubmit: () => _submitComment(viewModel),
            ),
          ],
        ),
      ),
    );
  }
}

/// 게시글 상세 카드.
/// 마커 공유 게시글은 [사진 프리뷰] → [작성자/날짜] → [장소 정보: 제목·주소] →
/// [추천 이유] 순서로 섹션을 명확히 분리해서 보여줍니다.
class _PostDetailCard extends StatelessWidget {
  const _PostDetailCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: const BorderRadius.all(AppDesign.r16),
        border: Border.all(color: AppDesign.borderColor),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(AppDesign.r16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.isMarkerShare)
              AppPhotoHero(
                tag: 'community-photo-${post.id}',
                child: AspectRatio(
                    aspectRatio: 1.6, child: CommunityPostPhoto(post: post)),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AuthorRow(post: post),
                  const SizedBox(height: 18),
                  if (post.isMarkerShare) ...[
                    _PlaceInfoSection(post: post),
                    if (post.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppDesign.separator),
                      const SizedBox(height: 16),
                      Text('이 장소를 추천하는 이유',
                          style: AppDesign.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        post.content,
                        style: AppDesign.bodyLarge
                            .copyWith(color: AppDesign.secondaryText),
                      ),
                    ],
                  ] else ...[
                    Text(post.title, style: AppDesign.headingLarge),
                    const SizedBox(height: 14),
                    Text(
                      post.content,
                      style: AppDesign.bodyLarge
                          .copyWith(color: AppDesign.secondaryText),
                    ),
                    if (post.destination != null &&
                        post.destination!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DestinationTag(label: post.destination!),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy년 M월 d일').format(post.createdAt.toLocal());
    return Row(
      children: [
        CircleAvatar(
            radius: 18,
            backgroundColor: AppDesign.secondaryBg,
            child: Text(
                post.authorNickname.isEmpty
                    ? '여'
                    : post.authorNickname.characters.first,
                style: const TextStyle(
                    color: AppDesign.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14))),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(post.authorNickname,
              style:
                  AppDesign.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(date, style: AppDesign.caption),
        ])),
      ],
    );
  }
}

/// 장소 정보 섹션: 카테고리 라벨 → 제목 → 주소를 각각 한 줄씩 나눠 보여줍니다.
class _PlaceInfoSection extends StatelessWidget {
  const _PlaceInfoSection({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.placeCategory != null && post.placeCategory!.isNotEmpty) ...[
          Text(
            post.placeCategory!,
            style: AppDesign.caption.copyWith(color: AppDesign.secondaryText),
          ),
          const SizedBox(height: 4),
        ],
        Text(post.placeTitle ?? post.title, style: AppDesign.headingLarge),
        if (post.placeAddress != null && post.placeAddress!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: AppDesign.subtleText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(post.placeAddress!, style: AppDesign.bodySmall),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "탑승권" 스타일 목적지 태그 (일반 이야기 게시글용).
class _DestinationTag extends StatelessWidget {
  const _DestinationTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppDesign.secondaryBg,
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.place_outlined,
            size: 16, color: AppDesign.secondaryText),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: AppDesign.bodySmall)),
      ]),
    );
  }
}

class _InteractionBar extends StatelessWidget {
  const _InteractionBar({required this.viewModel});

  final CommunityPostDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: const BorderRadius.all(AppDesign.r12),
            onTap: viewModel.toggleLike,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: viewModel.isLiked
                    ? AppDesign.secondaryBg
                    : AppDesign.cardBg,
                border: Border.all(
                  color: viewModel.isLiked
                      ? AppDesign.primary
                      : AppDesign.borderColor,
                ),
                borderRadius: const BorderRadius.all(AppDesign.r12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    viewModel.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: viewModel.isLiked
                        ? AppDesign.primary
                        : AppDesign.label3,
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Text('좋아요 ${viewModel.likeCount}',
                      style: AppDesign.bodyMedium),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final CommunityComment comment;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('M월 d일').format(comment.createdAt.toLocal());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: const BorderRadius.all(AppDesign.r14),
        border: Border.all(color: AppDesign.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(comment.authorNickname,
                      style: AppDesign.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Text(date, style: AppDesign.caption11),
            ],
          ),
          const SizedBox(height: 7),
          Text(comment.content,
              style: AppDesign.bodyMedium
                  .copyWith(color: AppDesign.secondaryText)),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Text('첫 댓글을 남겨보세요', style: AppDesign.bodySmall),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      decoration: const BoxDecoration(
        color: AppDesign.cardBg,
        border: Border(top: BorderSide(color: AppDesign.separator)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSubmitting,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: '댓글을 남겨보세요',
                filled: true,
                fillColor: AppDesign.lightGray,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(AppDesign.r12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
                backgroundColor: AppDesign.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48)),
            tooltip: '댓글 등록',
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
