import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../design/app_design.dart';
import '../models/community_post_model.dart';
import '../viewmodels/community_board_viewmodel.dart';
import '../widgets/dashed_border.dart';

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
      backgroundColor: AppDesign.primaryBg,
      appBar: AppBar(
        backgroundColor: AppDesign.primaryBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppDesign.spacing16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('TRAVEL JOURNAL', style: AppDesign.overline),
            const SizedBox(height: 2),
            Text('여행 이야기', style: AppDesign.journalTitle),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDesign.spacing16),
            child: Tooltip(
              message: '새 여행 이야기',
              child: InkWell(
                borderRadius: const BorderRadius.all(AppDesign.r12),
                onTap: () => _showPostComposer(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppDesign.primary,
                    borderRadius: BorderRadius.all(AppDesign.r12),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: RefreshIndicator(
          onRefresh: viewModel.loadPosts,
          child: Builder(
            builder: (context) {
              if (viewModel.isLoading && viewModel.posts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.errorMessage != null && viewModel.posts.isEmpty) {
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: viewModel.posts.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  if (index == 0) {
                    return _BoardIntroBanner(postCount: viewModel.posts.length);
                  }
                  return _PostCard(post: viewModel.posts[index - 1]);
                },
              );
            },
          ),
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

/// 게시판 상단 소개 배너. 순수 정보성 요소이므로 탭 가능한 카드처럼 보이지
/// 않도록 그라데이션 배너 형태로 표현하고, 별도의 인터랙션을 두지 않습니다.
/// 글쓰기는 AppBar의 편집 아이콘 하나로만 진입하도록 통일했습니다.
class _BoardIntroBanner extends StatelessWidget {
  const _BoardIntroBanner({required this.postCount});

  final int postCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: AppDesign.greenGradient,
        borderRadius: const BorderRadius.all(AppDesign.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '여행자들의 추천 마커',
            style: AppDesign.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$postCount개의 장소가 공유되어 있어요',
            style: AppDesign.journalTitleSmall.copyWith(
              color: Colors.white,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('M월 d일').format(post.createdAt.toLocal());
    final accent =
        post.isMarkerShare ? AppDesign.travelStamp : AppDesign.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: const BorderRadius.all(AppDesign.r16),
        border: Border.all(color: AppDesign.separator),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PostAvatar(
                nickname: post.authorNickname,
                accent: accent,
                stamped: post.isMarkerShare,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(post.authorNickname, style: AppDesign.bodyMedium),
              ),
              Text(
                post.isMarkerShare ? '$formattedDate · 마커 공유' : formattedDate,
                style: AppDesign.caption11,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (post.isMarkerShare) _SharedMarkerPreview(post: post),
          if (!post.isMarkerShare) ...[
            Text(post.title, style: AppDesign.journalTitleSmall),
            const SizedBox(height: 8),
            Text(
              post.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppDesign.bodyMedium.copyWith(
                color: AppDesign.secondaryText,
                height: 1.5,
              ),
            ),
          ],
          if (!post.isMarkerShare &&
              post.destination != null &&
              post.destination!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _DestinationTag(label: post.destination!),
          ],
          if (post.isMarkerShare &&
              post.destination != null &&
              post.destination!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DestinationTag(label: post.destination!),
          ],
        ],
      ),
    );
  }
}

/// 마커 공유 게시글은 점선 원형(우표 모티프) 아바타로, 일반 이야기는
/// 기존 색상 채움 아바타로 구분해 게시글 유형을 한눈에 알 수 있게 합니다.
class _PostAvatar extends StatelessWidget {
  const _PostAvatar({
    required this.nickname,
    required this.accent,
    required this.stamped,
  });

  final String nickname;
  final Color accent;
  final bool stamped;

  @override
  Widget build(BuildContext context) {
    final initial = Text(
      nickname.characters.first,
      style: TextStyle(
        color: accent,
        fontWeight: FontWeight.w700,
        fontSize: stamped ? 11 : 14,
      ),
    );

    if (stamped) {
      return DashedCircleBorder(color: accent, size: 38, child: initial);
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: initial,
    );
  }
}

/// "탑승권" 스타일 목적지 태그. 점선 필 테두리로 여행 소재를 살리면서도
/// 눌리지 않는 정보성 라벨임을 명확히 합니다.
class _DestinationTag extends StatelessWidget {
  const _DestinationTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DashedPillBorder(
      color: AppDesign.travelBlue.withValues(alpha: 0.5),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppDesign.travelBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flight_takeoff_rounded,
                  size: 11, color: AppDesign.travelBlue),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppDesign.bodySmall.copyWith(
                  color: AppDesign.travelBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedMarkerPreview extends StatelessWidget {
  const _SharedMarkerPreview({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppDesign.lightGray,
        borderRadius: const BorderRadius.all(AppDesign.r14),
        border: Border.all(color: AppDesign.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppDesign.travelBlue.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(AppDesign.r12),
            ),
            child: const Icon(Icons.place_outlined,
                color: AppDesign.travelBlue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.placeCategory != null &&
                    post.placeCategory!.isNotEmpty)
                  Text(
                    post.placeCategory!,
                    style: AppDesign.caption11.copyWith(
                      color: AppDesign.travelBlue,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(post.placeTitle!, style: AppDesign.bodyMedium),
                if (post.placeAddress != null && post.placeAddress!.isNotEmpty)
                  Text(
                    post.placeAddress!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppDesign.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: AppDesign.label3),
                const SizedBox(height: 14),
                Text(message, style: AppDesign.bodyMedium),
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
                const Text('마커 공유하기', style: AppDesign.headingMedium),
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
                  label: _isSubmitting ? '등록 중...' : '마커 등록하기',
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
