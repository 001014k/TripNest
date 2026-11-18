import 'screen_guide_target.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/onboarding/onboarding_service.dart';

class SharedLinkGuideButton extends StatefulWidget {
  const SharedLinkGuideButton(
      {super.key,
      required this.onPressed,
      this.forceGuide = false,
      this.enabled = true,
      this.floating = false});
  final VoidCallback onPressed;
  final bool forceGuide, enabled;
  final bool floating;
  @override
  State<SharedLinkGuideButton> createState() => _SharedLinkGuideButtonState();
}

class _SharedLinkGuideButtonState extends State<SharedLinkGuideButton> {
  final _anchor = GlobalKey();
  bool _checked = false;
  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant SharedLinkGuideButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) _schedule();
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _showIfNeeded());
  }

  Future<void> _showIfNeeded() async {
    if (!mounted || !widget.enabled || _checked) return;
    final service = OnboardingService();
    try {
      if (!widget.forceGuide &&
          await service.hasSeen(OnboardingService.sharedLinkKey)) {
        _checked = true;
        return;
      }
    } catch (_) {
      return;
    }
    if (!mounted ||
        !widget.enabled ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final target = _anchor.currentContext;
    if (target == null || !target.mounted) return;
    final box = target.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    _checked = true;
    final action = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '안내 닫기',
        barrierColor: Colors.transparent,
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        pageBuilder: (dialogContext, animation, secondaryAnimation) =>
            _SharedLinkCoach(
                rect: rect,
                replay: widget.forceGuide,
                floating: widget.floating));
    try {
      await service.markSeen(OnboardingService.sharedLinkKey);
    } catch (_) {/* 다음 방문 시 다시 시도합니다. */}
    if (mounted && action == true) {
      if (widget.forceGuide) {
        await ScreenGuide.start(context);
      } else {
        widget.onPressed();
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.floating
      ? FloatingActionButton(
          key: _anchor,
          heroTag: 'shared-link-add',
          tooltip: '링크 추가하기',
          elevation: 3,
          shape: const CircleBorder(),
          onPressed: widget.enabled ? widget.onPressed : null,
          backgroundColor: widget.enabled
              ? Colors.white
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: widget.enabled
              ? const Color(0xFF202020)
              : Theme.of(context).disabledColor,
          child: const Icon(Icons.add, size: 27),
        )
      : FilledButton.icon(
          key: _anchor,
          onPressed: widget.enabled ? widget.onPressed : null,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('링크 추가하기'));
}

class _SharedLinkCoach extends StatefulWidget {
  const _SharedLinkCoach(
      {required this.rect, this.replay = false, this.floating = false});
  final bool floating;
  final bool replay;
  final Rect rect;
  @override
  State<_SharedLinkCoach> createState() => _SharedLinkCoachState();
}

class _SharedLinkCoachState extends State<_SharedLinkCoach> {
  int _step = 0;
  @override
  Widget build(BuildContext context) => Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(builder: (context, constraints) {
        final rect = widget.rect.inflate(6);
        final above = rect.center.dy > constraints.maxHeight / 2;
        final top = above
            ? MediaQuery.paddingOf(context).top + 12
            : math.max(MediaQuery.paddingOf(context).top + 12,
                math.min(rect.bottom + 18, constraints.maxHeight * .45));
        return Stack(children: [
          Positioned.fill(
              child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: CustomPaint(painter: _Spotlight(rect)))),
          Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: widget.floating
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius:
                          widget.floating ? null : BorderRadius.circular(16)),
                  child: widget.floating
                      ? const Icon(Icons.add,
                          size: 27, color: Color(0xFF202020))
                      : const Text('+  링크 추가하기',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222))))),
          Positioned(
              left: rect.center.dx.clamp(36.0, constraints.maxWidth - 36) - 7,
              top: above ? rect.top - 25 : top - 7,
              child: Transform.rotate(
                  angle: math.pi / 4,
                  child:
                      Container(width: 14, height: 14, color: Colors.white))),
          Positioned(
              left: 20,
              right: 20,
              top: top,
              bottom: above
                  ? constraints.maxHeight - rect.top + 18
                  : MediaQuery.paddingOf(context).bottom + 20,
              child: Align(
                  alignment:
                      above ? Alignment.bottomCenter : Alignment.topCenter,
                  child: SingleChildScrollView(
                      child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20)),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _step == 0
                                        ? '링크로 장소를 가져오세요'
                                        : '다른 앱에서 바로 공유해도 돼요',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 14),
                                Text(
                                    _step == 0
                                        ? '인스타그램·Threads·블로그 글을\n붙여넣으면 장소를 찾아드려요.'
                                        : '게시물의 공유 버튼을 누르고\nTripNest를 선택해보세요.',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: Color(0xFF77777D))),
                                const SizedBox(height: 22),
                                Row(children: [
                                  Text('${_step + 1} / 2',
                                      style: const TextStyle(
                                          color: Color(0xFF77777D))),
                                  const Spacer(),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('닫기')),
                                  FilledButton(
                                      onPressed: () {
                                        if (_step == 0) {
                                          setState(() => _step = 1);
                                        } else {
                                          Navigator.pop(context, true);
                                        }
                                      },
                                      child: Text(_step == 0
                                          ? '다음'
                                          : widget.replay
                                              ? '다음 화면'
                                              : '링크 추가'))
                                ]),
                              ]))))),
        ]);
      }));
}

class _Spotlight extends CustomPainter {
  const _Spotlight(this.rect);
  final Rect rect;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .48));
  }

  @override
  bool shouldRepaint(_Spotlight oldDelegate) => rect != oldDelegate.rect;
}
