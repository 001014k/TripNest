import 'package:flutter/material.dart';

class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key, this.photo = false, this.height = 108});
  final bool photo;
  final double height;
  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _opacity = Tween<double>(begin: .4, end: 1).animate(_controller);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Widget _block(double height, {double? width}) => Container(
    height: height, width: width,
    decoration: BoxDecoration(color: const Color(0xFFE8EAED), borderRadius: BorderRadius.circular(10)),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: '불러오는 중',
    child: ExcludeSemantics(child: Container(
      height: widget.height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEEF0))),
      child: FadeTransition(opacity: _opacity,
        child: widget.photo
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _block(double.infinity)),
              const SizedBox(height: 14),
              FractionallySizedBox(widthFactor: .7, child: _block(15)),
              const SizedBox(height: 8),
              FractionallySizedBox(widthFactor: .9, child: _block(11)),
            ])
          : Row(children: [
              _block(72, width: 68),
              const SizedBox(width: 14),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FractionallySizedBox(widthFactor: .75, child: _block(17)),
                  const SizedBox(height: 12),
                  _block(12),
                  const SizedBox(height: 8),
                  FractionallySizedBox(widthFactor: .5, child: _block(10)),
                ])),
            ]),
      ),
    )),
  );
}

class HomePhotoSkeletons extends StatelessWidget {
  const HomePhotoSkeletons({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 220,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => const SizedBox(width: 230,
        child: HomeSkeleton(photo: true, height: 220)),
    ),
  );
}
