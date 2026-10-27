import '../../services/community/story_saved_places.dart';
import '../../widgets/community/story_marker_flow.dart';
import '../../widgets/community/story_place_preview.dart';
import '../../widgets/community/post_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../design/app_design.dart';
import '../../models/community/community_post_model.dart';
import '../../viewmodels/community/community_post_detail_viewmodel.dart';
import '../../widgets/community/community_post_gallery.dart';
import '../../widgets/community/story_actions.dart';

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
  final _commentFocus = FocusNode();
  final _composerKey = GlobalKey();
  bool _newestFirst = true;
  bool _savingMarker = false;
  bool _markerSaved = false;
  @override
  void initState() {
    super.initState();
    StorySavedPlaces.revision.addListener(_savedPlacesChanged);
    StorySavedPlaces.refresh();
  }

  void _savedPlacesChanged() {
    if (mounted) setState(() {});
  }

  void _openComment() {
    final target = _composerKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target,
          duration: const Duration(milliseconds: 250), alignment: .3);
    }
    _commentFocus.requestFocus();
  }

  Future<void> _save(CommunityPostDetailViewModel vm) async {
    if (_savingMarker || _markerSaved || vm.isPlaceSaved) return;
    setState(() => _savingMarker = true);
    try {
      final saved = await createMarkerFromStory(context, widget.post);
      if (mounted) setState(() => _markerSaved = saved);
    } finally {
      if (mounted) setState(() => _savingMarker = false);
    }
  }

  @override
  void dispose() {
    StorySavedPlaces.revision.removeListener(_savedPlacesChanged);
    _commentFocus.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _deletePost(CommunityPostDetailViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const PostDeleteDialog(),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await viewModel.deletePost(widget.post.authorId);
    if (!mounted) return;
    if (deleted) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(viewModel.errorMessage ?? '본인이 작성한 글만 삭제할 수 있습니다.'),
      ));
    }
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
      backgroundColor: Colors.white,
      body: Column(children: [
        Expanded(
            child: RefreshIndicator(
                onRefresh: viewModel.load,
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Stack(children: [
                      SizedBox(
                          height: post.isMarkerShare
                              ? MediaQuery.sizeOf(context).width * .85 +
                                  MediaQuery.paddingOf(context).top
                              : 100,
                          width: double.infinity,
                          child: post.isMarkerShare
                              ? CommunityPostGallery(
                                  key: ValueKey(post.id), post: post)
                              : const ColoredBox(color: AppDesign.secondaryBg)),
                      SafeArea(
                          bottom: false,
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: IconButton.filled(
                                  tooltip: '뒤로가기',
                                  style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54),
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white)))),
                      if (viewModel.canDelete(post.authorId))
                        Positioned(
                            top: MediaQuery.paddingOf(context).top + 12,
                            right: 12,
                            child: Container(
                                decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle),
                                child: PopupMenuButton<String>(
                                    tooltip: '게시글 관리',
                                    icon: const Icon(Icons.more_vert,
                                        color: Colors.white),
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deletePost(viewModel);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                          if (viewModel
                                              .canDelete(post.authorId))
                                            PopupMenuItem(
                                                value: 'delete',
                                                enabled: !viewModel.isDeleting,
                                                child: const Text('게시글 삭제'))
                                        ]))),
                      Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 22,
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24))),
                          )),
                    ]),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppDesign.secondaryBg,
                                    child: Text(post.authorNickname.isEmpty
                                        ? '여'
                                        : post
                                            .authorNickname.characters.first)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(post.authorNickname,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      Text(
                                          '${DateFormat('M월 d일').format(post.createdAt.toLocal())} · ${post.isMarkerShare ? '장소 공유' : '여행 이야기'}',
                                          style: AppDesign.caption),
                                    ])),
                              ]),
                              const SizedBox(height: 22),
                              Text(post.placeTitle ?? post.title,
                                  style: const TextStyle(
                                      fontSize: 27,
                                      height: 1.25,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.6)),
                              if ((post.placeAddress ?? post.destination ?? '')
                                  .isNotEmpty) ...[
                                const SizedBox(height: 9),
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 17,
                                          color: AppDesign.secondaryText),
                                      const SizedBox(width: 5),
                                      Expanded(
                                          child: Text(
                                              post.placeAddress ??
                                                  post.destination!,
                                              style: AppDesign.bodySmall))
                                    ]),
                              ],
                              if (post.content.trim().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(post.content,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.75,
                                        color: Color(0xff55565d)))
                              ],
                              const SizedBox(height: 16),
                              StoryTags(post: post, showIcons: true),
                              const SizedBox(height: 18),
                              Row(children: [
                                Expanded(
                                    flex: 3,
                                    child: StoryActionButton(
                                        icon: viewModel.isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: viewModel.isLiked
                                            ? Colors.redAccent
                                            : Colors.black,
                                        label: '${viewModel.likeCount}',
                                        onPressed: () async {
                                          await viewModel.toggleLike();
                                          if (context.mounted &&
                                              viewModel.errorMessage != null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(viewModel
                                                        .errorMessage!)));
                                          }
                                        })),
                                const SizedBox(width: 7),
                                Expanded(
                                    flex: 3,
                                    child: StoryActionButton(
                                        icon: Icons.chat_bubble_outline,
                                        label: '${viewModel.comments.length}',
                                        onPressed: _openComment)),
                                const SizedBox(width: 8),
                                Container(
                                    width: 1,
                                    height: 20,
                                    color: const Color(0xffe9e9ee)),
                                const SizedBox(width: 8),
                                Expanded(
                                    flex: 4,
                                    child: StoryActionButton(
                                        icon: (_markerSaved ||
                                                StorySavedPlaces.contains(
                                                    post) ||
                                                viewModel.isPlaceSaved)
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        label: (_savingMarker ||
                                                viewModel.isSavingPlace)
                                            ? '저장 중'
                                            : (_markerSaved ||
                                                    StorySavedPlaces.contains(
                                                        post) ||
                                                    viewModel.isPlaceSaved)
                                                ? '저장됨'
                                                : '저장하기',
                                        onPressed: _savingMarker ||
                                                _markerSaved ||
                                                StorySavedPlaces.contains(
                                                    post) ||
                                                viewModel.isSavingPlace ||
                                                viewModel.isPlaceSaved ||
                                                !post.isMarkerShare
                                            ? null
                                            : () => _save(viewModel))),
                                const SizedBox(width: 7),
                                Expanded(
                                    flex: 4,
                                    child: StoryActionButton(
                                        icon: Icons.ios_share_outlined,
                                        label: '공유하기',
                                        onPressed: () =>
                                            shareStory(context, post))),
                              ]),
                              if (post.isMarkerShare) ...[
                                const SizedBox(height: 16),
                                StoryPlacePreview(
                                    key: ValueKey(post.id), post: post),
                              ],
                              const SizedBox(height: 24),
                              Row(children: [
                                Expanded(
                                    child: Text(
                                        '댓글 ${viewModel.comments.length}',
                                        style: AppDesign.headingSmall)),
                                PopupMenuButton<bool>(
                                    tooltip: '댓글 정렬',
                                    onSelected: (value) =>
                                        setState(() => _newestFirst = value),
                                    itemBuilder: (_) => const [
                                          PopupMenuItem(
                                              value: true, child: Text('최신순')),
                                          PopupMenuItem(
                                              value: false, child: Text('등록순'))
                                        ],
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Row(children: [
                                          Text(_newestFirst ? '최신순' : '등록순',
                                              style: AppDesign.caption),
                                          const Icon(Icons.keyboard_arrow_down,
                                              size: 18,
                                              color: AppDesign.secondaryText)
                                        ])))
                              ]),
                              _CommentComposer(
                                  key: _composerKey,
                                  controller: _commentController,
                                  focusNode: _commentFocus,
                                  isSubmitting: viewModel.isSubmittingComment,
                                  onSubmit: () => _submitComment(viewModel)),
                              if (viewModel.isLoading)
                                const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                        child: CircularProgressIndicator()))
                              else if (viewModel.comments.isEmpty)
                                const _EmptyComments()
                              else
                                ...(_newestFirst
                                        ? viewModel.comments.reversed
                                        : viewModel.comments)
                                    .map((comment) => Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: _CommentCard(comment: comment))),
                            ])),
                  ],
                ))),
      ]),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
            radius: 18,
            backgroundColor: AppDesign.secondaryBg,
            child: Text(comment.authorNickname.isEmpty
                ? '여'
                : comment.authorNickname.characters.first)),
        const SizedBox(width: 10),
        Expanded(
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
        ))
      ]),
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
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: AppDesign.cardBg,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
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
                  borderRadius: BorderRadius.circular(28),
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
