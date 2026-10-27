import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/places/address_photo_preview.dart';
import '../../services/community/story_saved_places.dart';
import '../../widgets/community/community_feed_skeleton.dart';
import '../../widgets/community/community_marker_picker.dart';
import '../../widgets/community/nearby_location_notice.dart';
import '../../services/community/community_nearby_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/places/place_keyword_icon.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/community/story_actions.dart';
import '../../navigation/app_page_route.dart';
import '../../widgets/community/community_post_photo.dart';
import '../../widgets/common/app_photo_hero.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../design/app_design.dart';
import '../../models/community/community_post_model.dart';
import '../../viewmodels/community/community_board_viewmodel.dart';
import '../../widgets/navigation/tripnest_navigation.dart';
import 'community_post_detail_view.dart';

class CommunityBoardView extends StatelessWidget {
  const CommunityBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        StorySavedPlaces.refresh();
        return CommunityBoardViewModel()..loadPosts();
      },
      child: const _CommunityBoardBody(),
    );
  }
}

class _CommunityBoardBody extends StatefulWidget {
  const _CommunityBoardBody();
  @override
  State<_CommunityBoardBody> createState() => _CommunityBoardBodyState();
}

class _CommunityBoardBodyState extends State<_CommunityBoardBody> {
  int _tab = 0;
  String _topic = '전체';
  final _nearby = CommunityNearbyService();
  Map<String, double> _distances = {};
  int _nearbyRequest = 0;
  bool _locating = false;
  String? _locationError;
  Future<void> _selectTab(int tab) async {
    final vm = context.read<CommunityBoardViewModel>();
    StorySavedPlaces.refresh();
    final reload = vm.loadPosts();
    final request = ++_nearbyRequest;
    setState(() {
      _tab = tab;
      _topic = '전체';
      _locating = tab == 2;
    });
    if (tab != 2) {
      await reload;
      return;
    }
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('위치 서비스를 켜주세요.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('내 주변 이야기를 보려면 위치 권한이 필요해요.');
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(timeLimit: Duration(seconds: 15)));
      await reload;
      if (!mounted || request != _nearbyRequest) return;
      final distances = await _nearby.distances(
          vm.posts, LatLng(position.latitude, position.longitude));
      if (mounted && request == _nearbyRequest) {
        setState(() => _distances = distances);
      }
    } catch (_) {
      if (mounted && request == _nearbyRequest) {
        setState(
            () => _locationError = '현재 위치를 확인할 수 없어요. 위치 서비스와 권한을 확인해주세요.');
      }
    } finally {
      if (mounted && request == _nearbyRequest) {
        setState(() => _locating = false);
      }
      await reload;
    }
  }

  List<CommunityPost> _filtered(CommunityBoardViewModel vm) {
    final posts = vm.posts.where((p) {
      if (_tab == 2 &&
          (_distances[p.id] == null || _distances[p.id]! > 20000)) {
        return false;
      }
      return _matchesKeyword(p, _topic);
    }).toList();
    if (_tab == 1) {
      posts.sort((a, b) =>
          (vm.likeCounts[b.id] ?? 0).compareTo(vm.likeCounts[a.id] ?? 0));
    }
    if (_tab == 2) {
      posts.sort((a, b) => _distances[a.id]!.compareTo(_distances[b.id]!));
    }
    return posts;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommunityBoardViewModel>();
    final posts = _filtered(viewModel);

    return Scaffold(
      bottomNavigationBar: const TripNestNavigation(currentRoute: '/community'),
      backgroundColor: AppDesign.primaryBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppDesign.primaryBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const TripNestHeader(trailing: TripNestSocialActions()),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xfff4f4f5),
                    borderRadius: BorderRadius.circular(30)),
                child: Row(
                    children: List.generate(
                        3,
                        (i) => Expanded(
                            child: Semantics(
                                selected: _tab == i,
                                child: InkWell(
                                    borderRadius: BorderRadius.circular(30),
                                    onTap: () => _selectTab(i),
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 11),
                                        decoration: BoxDecoration(
                                            color: _tab == i
                                                ? AppDesign.primary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(30)),
                                        child: Text(['최근', '인기', '내 주변'][i],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: _tab == i
                                                    ? Colors.white
                                                    : AppDesign
                                                        .secondaryText)))))))),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _selectTab(_tab),
                child: Builder(
                  builder: (context) {
                    if (viewModel.isLoading || (_tab == 2 && _locating)) {
                      return CommunityFeedSkeleton(
                          key: ValueKey(_tab), tab: _tab);
                    }

                    if (_tab == 2 && _locationError != null) {
                      return NearbyLocationNotice(onRetry: () => _selectTab(2));
                    }

                    if (viewModel.errorMessage != null) {
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
                        onAction: () => _selectTab(_tab),
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

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (_tab != 1)
                          SliverToBoxAdapter(
                              child: _TopicFilters(
                                  posts: viewModel.posts,
                                  selected: _topic,
                                  onChanged: (topic) =>
                                      setState(() => _topic = topic))),
                        if (posts.isEmpty)
                          SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                  child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                          _tab == 2
                                              ? '주변 20km 이내에 공유된 이야기가 없어요.'
                                              : '이 주제의 이야기가 아직 없어요.',
                                          textAlign: TextAlign.center,
                                          style: AppDesign.bodySmall)))),
                        SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: _tab == 1
                                ? SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                        (context, i) => _PopularCard(
                                            key: ValueKey(posts[i].id),
                                            post: posts[i]),
                                        childCount: posts.length),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            MediaQuery.sizeOf(context).width < 360 || MediaQuery.textScalerOf(context).scale(1) > 1.3
                                                ? 1
                                                : 2,
                                        mainAxisExtent: 290,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10))
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                        (context, i) => Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: _PostCard(key: ValueKey(posts[i].id), post: posts[i])),
                                        childCount: posts.length))),
                      ],
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

const _placeKeywords = [
  '전체',
  '카페',
  '음식점',
  '호텔',
  '사진',
  '전시회',
  '자연',
  '관광명소',
  '쇼핑',
  '체험'
];

bool _matchesKeyword(CommunityPost post, String keyword) =>
    keyword == '전체' || post.placeCategory?.trim() == keyword;

class _TopicFilters extends StatelessWidget {
  const _TopicFilters(
      {required this.posts, required this.selected, required this.onChanged});
  final List<CommunityPost> posts;
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 96,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _placeKeywords.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final label = _placeKeywords[i];
            final matches = posts.where((p) => _matchesKeyword(p, label));
            return InkWell(
                onTap: () => onChanged(label),
                borderRadius: BorderRadius.circular(30),
                child: SizedBox(
                    width: 52,
                    child: Column(children: [
                      Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: selected == label
                                      ? Colors.black
                                      : const Color(0xffeeeeef),
                                  width: selected == label ? 1.5 : 1)),
                          child: ClipOval(
                              child: label != '전체' && matches.isNotEmpty
                                  ? CommunityPostPhoto(post: matches.first)
                                  : ColoredBox(
                                      color: const Color(0xfff0f3f5),
                                      child: Icon(
                                          label == '전체'
                                              ? Icons.flight
                                              : placeKeywordIcon(label),
                                          size: 23)))),
                      const SizedBox(height: 7),
                      Text(label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected == label
                                  ? FontWeight.w700
                                  : FontWeight.w400)),
                    ])));
          }));
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({super.key, required this.post});
  final CommunityPost post;
  @override
  Widget build(BuildContext context) {
    final board = context.watch<CommunityBoardViewModel>();
    return Material(
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xff333333),
        child: InkWell(
            onTap: () => _PostCard(post: post)._open(context),
            child: Stack(fit: StackFit.expand, children: [
              CommunityPostPhoto(post: post),
              const DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Color(0x44000000),
                    Colors.transparent,
                    Color(0xdd000000)
                  ],
                          stops: [
                    0,
                    .4,
                    1
                  ]))),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _PostAvatar(nickname: post.authorNickname),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(post.authorNickname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600))),
                          StorySaveButton(
                              key: ValueKey(post.id),
                              post: post,
                              color: Colors.white),
                        ]),
                        const Spacer(),
                        Text(post.placeTitle ?? post.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const SizedBox(height: 7),
                        Text(
                            '⌖ ${post.placeAddress ?? post.destination ?? '여행 이야기'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                        const SizedBox(height: 10),
                        Row(children: [
                          Icon(
                              board.likedPosts.contains(post.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.white,
                              size: 19),
                          const SizedBox(width: 5),
                          Text('${board.likeCounts[post.id] ?? 0}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          const SizedBox(width: 16),
                          const Icon(Icons.chat_bubble_outline,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 5),
                          Text('${board.commentCounts[post.id] ?? 0}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12))
                        ]),
                      ])),
            ])));
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({super.key, required this.post});
  final CommunityPost post;

  Future<void> _open(BuildContext context) async {
    final board = context.read<CommunityBoardViewModel>();
    await Navigator.of(context).push(
        AppPageRoute(builder: (_) => CommunityPostDetailView(post: post)));
    if (context.mounted) {
      await StorySavedPlaces.refresh();
      await board.loadPosts();
    }
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
              AppPhotoHero(
                tag: 'community-photo-${post.id}',
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                        aspectRatio: 1.85,
                        child: CommunityPostPhoto(post: post))),
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
            StoryTags(post: post, showIcons: true),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
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
                    foregroundColor: board.likedPosts.contains(post.id)
                        ? Colors.redAccent
                        : AppDesign.primary),
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
              StorySaveButton(key: ValueKey('save-${post.id}'), post: post),
              IconButton(
                  tooltip: '이야기 공유',
                  onPressed: () => shareStory(context, post),
                  icon: const Icon(Icons.ios_share_outlined, size: 21)),
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
    if (_isSubmitting) return;
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
            borderRadius: BorderRadius.circular(28),
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
                Row(children: [
                  const Expanded(
                      child: Text('장소 공유하기',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.8))),
                  IconButton.filledTonal(
                      tooltip: '닫기',
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                          backgroundColor: const Color(0xfff2f2f5)),
                      icon: const Icon(Icons.close))
                ]),
                const SizedBox(height: AppDesign.spacing6),
                Text('내가 저장한 장소를 다른 여행자에게 추천해보세요', style: AppDesign.bodySmall),
                const SizedBox(height: AppDesign.spacing20),
                _MarkerSelector(
                  enabled: !_isSubmitting,
                  markers: viewModel.myMarkers,
                  value: _selectedMarker,
                  isLoading: viewModel.isLoadingMarkers,
                  onChanged: (marker) =>
                      setState(() => _selectedMarker = marker),
                ),
                const SizedBox(height: 12),
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xfff6f6f8),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('추천 이유 (선택)',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xff747481))),
                          const SizedBox(height: 12),
                          TextField(
                              controller: _contentController,
                              enabled: !_isSubmitting,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 200,
                              style: AppDesign.bodyMedium,
                              decoration: InputDecoration(
                                  hintText: '이 장소를 추천하는 이유를 적어보세요.',
                                  hintStyle: const TextStyle(
                                      fontSize: 14, color: Color(0xff9999a5)),
                                  prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 42),
                                      child: Icon(Icons.edit_outlined,
                                          size: 21, color: Color(0xff9999a5))),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(14),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Color(0xffe6e6ec))),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Color(0xffe6e6ec))))),
                        ])),
                const SizedBox(height: 18),
                FilledButton.icon(
                    onPressed: _isSubmitting ||
                            viewModel.isLoadingMarkers ||
                            _selectedMarker == null
                        ? null
                        : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.near_me, size: 23),
                    label: Text(_isSubmitting ? '등록 중…' : '장소 공유하기',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff222222),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(58),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)))),
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
    this.enabled = true,
    required this.markers,
    required this.value,
    required this.isLoading,
    required this.onChanged,
  });

  final bool enabled;
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

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: !enabled
          ? null
          : () async {
              final selected = await showModalBottomSheet<CommunityMarker>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      CommunityMarkerPicker(markers: markers, selected: value));
              if (selected != null && context.mounted) onChanged(selected);
            },
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xfff6f6f8),
              borderRadius: BorderRadius.circular(20)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('내 마커',
                style: TextStyle(fontSize: 14, color: Color(0xff747481))),
            const SizedBox(height: 12),
            Row(children: [
              if (value != null) ...[
                ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: SizedBox(
                        width: 66,
                        height: 76,
                        child: value!.imagePath?.startsWith('http') == true
                            ? CachedNetworkImage(
                                imageUrl: value!.imagePath!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    AddressPhotoPreview(
                                        address: value!.address,
                                        title: value!.title,
                                        size: 76))
                            : AddressPhotoPreview(
                                address: value!.address,
                                title: value!.title,
                                size: 76))),
                const SizedBox(width: 12),
              ],
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(value?.title ?? '공유할 마커 선택',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    if (value != null) ...[
                      const SizedBox(height: 6),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: Color(0xff858591)),
                            const SizedBox(width: 3),
                            Expanded(
                                child: Text(value!.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xff858591))))
                          ]),
                      if (value!.category?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: const Color(0xffebebf0),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('#${value!.category}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xff747481))))
                      ],
                    ]
                  ])),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down),
            ]),
          ])),
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
