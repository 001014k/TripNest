import 'dart:async';
import 'package:provider/provider.dart';
import 'feature_guide_example.dart';
import 'keyword_guide_card.dart';
import 'route_guide_card.dart';
import 'collaboration_guide_card.dart';
import 'nearby_guide_card.dart';
import 'unsaved_place_guide_card.dart';
import 'story_save_guide_card.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/onboarding/feature_guide.dart';
import '../../navigation/app_tab_shell.dart';
import '../../services/onboarding/onboarding_service.dart';

export '../../models/onboarding/feature_guide.dart';

/// 실제 조작 요소를 강조하고 별도의 로컬 예시도 제공합니다.
/// 사용자 데이터가 없거나 대상을 불러올 수 없어도 예시를 사용할 수 있습니다.
class ScreenGuide {
  static final _targets = <_ScreenGuideTargetState>{};
  static bool _running = false;
  static FeatureGuide? followup;
  static const order = [
    FeatureGuide.keywords,
    FeatureGuide.routeOrder,
    FeatureGuide.nearby,
    FeatureGuide.storySave,
    FeatureGuide.temporaryMarker,
    FeatureGuide.collaboration
  ];

  static void prepare(BuildContext context, FeatureGuide guide) {
    final route = switch (guide) {
      FeatureGuide.routeOrder || FeatureGuide.collaboration => '/list',
      FeatureGuide.storySave || FeatureGuide.temporaryMarker => '/shared_link',
      FeatureGuide.keywords => '/map',
      FeatureGuide.nearby => '/community',
    };
    if (AppTabController.routes.contains(route)) {
      unawaited(AppTabController.open(context, route));
    } else {
      unawaited(Navigator.of(context).pushNamed(route));
    }
  }

  static Future<void> start(BuildContext context, {FeatureGuide? only}) async {
    if (_running) return;
    _running = true;
    final navigator = Navigator.of(context);
    try {
      final steps = only == null ? order : [only];
      for (var i = 0; i < steps.length; i++) {
        final guide = steps[i];
        final route = switch (guide) {
          FeatureGuide.keywords || FeatureGuide.routeOrder => '/map',
          FeatureGuide.collaboration => '/list',
          _ => '/community',
        };
        if (!navigator.mounted) break;
        if (AppTabController.routes.contains(route)) {
          unawaited(AppTabController.open(navigator.context, route));
        } else {
          unawaited(navigator.pushNamed(route));
        }
        // 안내를 시작한 화면이 아니라 이동이 끝난 목적지 화면을 기준으로 잡습니다.
        // 대상이 없다고 해서 다른 화면에 예시를 표시해서는 안 됩니다.
        Route<dynamic>? destination;
        navigator.popUntil((candidate) {
          destination = candidate;
          return true; // 경로를 닫지 않고 최상단 경로를 확인합니다.
        });
        final tabs = navigator.context.read<AppTabController?>();
        final expectedTab = tabs == null
            ? null
            : AppTabController.routes.contains(route)
                ? route
                : tabs.current;
        bool destinationIsCurrent() =>
            navigator.mounted &&
            destination?.isCurrent == true &&
            tabs?.current == expectedTab;
        _ScreenGuideTargetState? target;
        // 화면 이동과 비동기 데이터 로딩, 지연 생성 목록 항목의 배치가 끝날 때까지 기다립니다.
        for (var attempt = 0; attempt < 30; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          if (!destinationIsCurrent()) return;
          final candidates = _targets
              .where((t) =>
                  t.mounted &&
                  t.widget.guide == guide &&
                  ModalRoute.of(t.context)?.isCurrent == true &&
                  (AppTabVisibility.maybeOf(t.context)?.active ?? true))
              .toList()
            ..sort((a, b) => b.widget.priority.compareTo(a.widget.priority));
          if (candidates.isNotEmpty &&
              attempt >= 3 &&
              (candidates.first.widget.priority >= 0 || attempt >= 19)) {
            target = candidates.first;
            break;
          }
        }
        if (!navigator.mounted || !destinationIsCurrent()) return;
        final last = i == steps.length - 1;
        final result = target == null
            ? await FeatureGuideExample.show(navigator.context, guide,
                last: last, canTry: true)
            : await target.showGuide('${i + 1} / ${steps.length}', last);
        if (target == null && result == 'try' && navigator.mounted) {
          prepare(navigator.context, guide);
        }
        if (result != 'next') break;
      }
    } finally {
      _running = false;
    }
  }
}

class ScreenGuideTarget extends StatefulWidget {
  const ScreenGuideTarget(
      {super.key,
      required this.guide,
      required this.child,
      this.description,
      this.onTry,
      this.priority = 0,
      this.showOnArrival = false});
  final FeatureGuide? guide;
  final Widget child;
  final String? description;
  final VoidCallback? onTry;
  final int priority;
  final bool showOnArrival;
  @override
  State<ScreenGuideTarget> createState() => _ScreenGuideTargetState();
}

class _ScreenGuideTargetState extends State<ScreenGuideTarget> {
  final _anchor = GlobalKey();
  @override
  void initState() {
    super.initState();
    ScreenGuide._targets.add(this);
    if (widget.showOnArrival) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _introduce());
    }
  }

  @override
  void didUpdateWidget(covariant ScreenGuideTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showOnArrival && widget.showOnArrival) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _introduce());
    }
  }

  @override
  void dispose() {
    ScreenGuide._targets.remove(this);
    super.dispose();
  }

  bool get _isVisible =>
      mounted &&
      ModalRoute.of(context)?.isCurrent == true &&
      (AppTabVisibility.maybeOf(context)?.active ?? true);

  Future<void> _introduce() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final guide = widget.guide;
    if (!mounted || guide == null || ScreenGuide._running || !_isVisible) {
      return;
    }
    final force = ScreenGuide.followup == guide;
    try {
      if (!force && await OnboardingService().hasSeen(guide.storageKey)) {
        return;
      }
    } catch (_) {}
    if (!_isVisible || ScreenGuide._running) return;
    ScreenGuide.followup = null;
    ScreenGuide._running = true;
    try {
      final result = await showGuide('1 / 1', true);
      if (result != null) {
        await OnboardingService().markSeen(guide.storageKey);
      }
    } catch (_) {
      // 환경설정을 불러올 수 없어도 기능 자체는 사용할 수 있게 합니다.
    } finally {
      ScreenGuide._running = false;
    }
  }

  Future<String?> showGuide(String progress, bool last) async {
    if (!mounted || !_isVisible) return null;
    final anchorContext = _anchor.currentContext;
    if (anchorContext == null) return null;
    await Scrollable.ensureVisible(anchorContext,
        alignment: .2,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200));
    if (!mounted || !_isVisible) return null;
    final box = _anchor.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    var result = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '안내 닫기',
        barrierColor: Colors.transparent,
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) => _Coach(
            rect: rect,
            keywordGuide: widget.guide == FeatureGuide.keywords,
            routeGuide: widget.guide == FeatureGuide.routeOrder,
            storySaveGuide:
                widget.guide == FeatureGuide.storySave && widget.priority >= 0,
            nearbyGuide: widget.guide == FeatureGuide.nearby,
            unsavedGuide: widget.guide == FeatureGuide.temporaryMarker &&
                widget.priority >= 0,
            inDetail: widget.priority == 0,
            collaborationGuide: widget.guide == FeatureGuide.collaboration &&
                widget.priority == 2,
            title: widget.guide!.title,
            description: widget.description ?? widget.guide!.description,
            progress: progress,
            last: last,
            canTry: widget.onTry != null || widget.priority < 0));
    if (!mounted || !_isVisible) return null;
    if (result == 'example') {
      result = await FeatureGuideExample.show(context, widget.guide!,
          last: last, canTry: widget.onTry != null || widget.priority < 0);
    }
    if (mounted && _isVisible && result == 'try') {
      ScreenGuide.followup = widget.guide;
      if (widget.onTry != null) {
        widget.onTry!();
      } else {
        ScreenGuide.prepare(context, widget.guide!);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(key: _anchor, child: widget.child);
}

class _Coach extends StatelessWidget {
  const _Coach(
      {required this.rect,
      this.keywordGuide = false,
      this.routeGuide = false,
      this.nearbyGuide = false,
      this.unsavedGuide = false,
      this.storySaveGuide = false,
      this.inDetail = false,
      this.collaborationGuide = false,
      required this.title,
      required this.description,
      required this.progress,
      required this.last,
      required this.canTry});
  final Rect rect;
  final bool keywordGuide,
      routeGuide,
      collaborationGuide,
      nearbyGuide,
      unsavedGuide,
      storySaveGuide,
      inDetail;
  final String title, description, progress;
  final bool last, canTry;
  @override
  Widget build(BuildContext context) => Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(builder: (context, constraints) {
        final safe = MediaQuery.paddingOf(context);
        final hole = rect.inflate(5).intersect(Rect.fromLTWH(8, safe.top,
            constraints.maxWidth - 16, constraints.maxHeight - safe.vertical));
        final below = constraints.maxHeight - safe.bottom - hole.bottom;
        final cardBelow = below >= 280;
        return Stack(children: [
          Positioned.fill(
              child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CustomPaint(painter: _Shade(hole)))),
          if (keywordGuide)
            Positioned.fill(
                child:
                    KeywordGuideCard(target: hole, last: last, canTry: canTry)),
          if (routeGuide)
            Positioned.fill(
                child:
                    RouteGuideCard(target: hole, last: last, canTry: canTry)),
          if (collaborationGuide)
            Positioned.fill(
                child: CollaborationGuideCard(
                    target: hole, last: last, canTry: canTry)),
          if (nearbyGuide)
            Positioned.fill(
                child:
                    NearbyGuideCard(target: hole, last: last, canTry: canTry)),
          if (unsavedGuide)
            Positioned.fill(
                child: UnsavedPlaceGuideCard(
                    target: hole,
                    last: last,
                    canTry: canTry,
                    inDetail: inDetail)),
          if (storySaveGuide)
            Positioned.fill(
                child: StorySaveGuideCard(
                    target: hole, last: last, canTry: canTry)),
          if (!storySaveGuide &&
              !unsavedGuide &&
              !keywordGuide &&
              !routeGuide &&
              !collaborationGuide &&
              !nearbyGuide)
            Positioned(
                left: 20,
                right: 20,
                top: cardBelow ? hole.bottom + 16 : safe.top + 12,
                bottom: cardBelow
                    ? safe.bottom + 12
                    : math.max(constraints.maxHeight - hole.top + 16,
                        safe.bottom + 12),
                child: Align(
                    alignment: cardBelow
                        ? Alignment.topCenter
                        : Alignment.bottomCenter,
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
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child: Text(title,
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w700))),
                                        const SizedBox(width: 8),
                                        IconButton(
                                            tooltip: '안내 닫기',
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            icon: const Icon(Icons.close,
                                                size: 22)),
                                      ]),
                                  const SizedBox(height: 12),
                                  Text(description,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.6,
                                          color: Color(0xff77777d))),
                                  const SizedBox(height: 16),
                                  Text(progress,
                                      style: const TextStyle(
                                          color: Color(0xff77777d))),
                                  const SizedBox(height: 12),
                                  IntrinsicHeight(
                                      child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                        Expanded(
                                            child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                    minimumSize:
                                                        const Size(0, 48),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 12)),
                                                onPressed: () => Navigator.pop(
                                                    context, 'example'),
                                                child: const Text('예시로 보기',
                                                    textAlign:
                                                        TextAlign.center))),
                                        if (canTry) ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                      minimumSize:
                                                          const Size(0, 48),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 12)),
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, 'try'),
                                                  child: const Text('직접 해보기',
                                                      textAlign:
                                                          TextAlign.center))),
                                        ],
                                      ])),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                          style: FilledButton.styleFrom(
                                              minimumSize: const Size(0, 50)),
                                          onPressed: () =>
                                              Navigator.pop(context, 'next'),
                                          child: Text(last ? '완료' : '다음'))),
                                ]))))),
        ]);
      }));
}

class _Shade extends CustomPainter {
  const _Shade(this.rect);
  final Rect rect;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)));
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .55));
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_Shade oldDelegate) => oldDelegate.rect != rect;
}
