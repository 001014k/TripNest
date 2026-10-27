import 'package:flutter/material.dart';

/// Mirrors the list and grid layouts while a selected feed is loading.
class CommunityFeedSkeleton extends StatefulWidget {
  const CommunityFeedSkeleton({super.key, required this.tab});
  final int tab;

  @override
  State<CommunityFeedSkeleton> createState() => _CommunityFeedSkeletonState();
}

class _CommunityFeedSkeletonState extends State<CommunityFeedSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 850));
  late final Animation<double> _opacity =
      Tween<double>(begin: .45, end: 1).animate(_pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 1;
    } else {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _block(double height, {double? width}) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E9EC),
          borderRadius: BorderRadius.circular(8),
        ),
      );

  Widget _card(bool popular) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEEFF1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!popular) ...[
            Row(children: [
              _block(32, width: 32),
              const SizedBox(width: 10),
              _block(12, width: 90),
            ]),
            const SizedBox(height: 14),
          ],
          if (popular)
            Expanded(child: _block(double.infinity))
          else
            AspectRatio(aspectRatio: 1.6, child: _block(double.infinity)),
          const SizedBox(height: 16),
          FractionallySizedBox(widthFactor: .7, child: _block(16)),
          const SizedBox(height: 10),
          _block(12),
          const SizedBox(height: 14),
          _block(10, width: 64),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final popular = widget.tab == 1;
    final columns = MediaQuery.sizeOf(context).width < 360 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? 1
        : 2;
    return Semantics(
      label: '${['최근', '인기', '내 주변'][widget.tab]} 여행 이야기 불러오는 중',
      liveRegion: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _opacity,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (!popular)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _block(38),
                        )),
                    ]),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: popular
                    ? SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 290,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        delegate: SliverChildBuilderDelegate(
                            (_, __) => _card(true), childCount: 4),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _card(false),
                          ),
                          childCount: 3,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
