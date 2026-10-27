import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fluttertrip/navigation/app_page_route.dart';
import 'package:fluttertrip/navigation/app_tab_shell.dart';
import 'package:fluttertrip/widgets/common/app_photo_hero.dart';
import 'package:fluttertrip/widgets/navigation/tripnest_navigation.dart';

class _Observer extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}

class _Tab extends StatefulWidget {
  const _Tab(this.name, this.created);
  final String name;
  final VoidCallback created;
  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  int count = 0;
  @override
  void initState() {
    super.initState();
    widget.created();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: TripNestNavigation(currentRoute: widget.name),
        body: ListView(children: [
          Text('${widget.name}:$count'),
          TextButton(
              onPressed: () => setState(() => count++),
              child: const Text('증가')),
          const AppPhotoHero(
              tag: 'shared-photo',
              child:
                  SizedBox(height: 80, child: ColoredBox(color: Colors.blue))),
          TextButton(
              child: const Text('상세 열기'),
              onPressed: () => Navigator.push(
                  context,
                  AppPageRoute(
                      builder: (_) => const Scaffold(
                            bottomNavigationBar:
                                TripNestNavigation(currentRoute: '/detail'),
                            body: AppPhotoHero(
                                tag: 'shared-photo',
                                child: SizedBox(
                                    height: 200,
                                    child: ColoredBox(color: Colors.blue))),
                          )))),
          for (var i = 0; i < 40; i++)
            SizedBox(height: 40, child: Text('${widget.name} item $i')),
        ]),
      );
}

void main() {
  testWidgets(
      'Tabs are lazy, preserve state and scrolling, fade, and do not push routes',
      (tester) async {
    final controller = AppTabController();
    final observer = _Observer();
    final created = <String, int>{};
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
          navigatorObservers: [observer],
          home: AppTabShell(
            controller: controller,
            builders: {
              for (final name in AppTabController.routes)
                name: (_) =>
                    _Tab(name, () => created[name] = (created[name] ?? 0) + 1),
            },
          )),
    ));
    await tester.pumpAndSettle();
    expect(created, {'/home': 1});
    expect(find.text('홈'), findsOneWidget);
    await tester.tap(find.text('증가'));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    await tester.tap(find.text('지도'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(
        find
            .byType(FadeTransition)
            .evaluate()
            .map((e) => (e.widget as FadeTransition).opacity.value)
            .any((value) => value > 0 && value < 1),
        isTrue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        position);
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.text('/home:1'), findsOneWidget);
    expect(created, {'/home': 1, '/map': 1});
    expect(observer.pushes, 1);
    // Retained inactive tabs contain the same Hero tag but must not participate.
    await tester.tap(find.text('상세 열기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('일정'));
    await tester.pumpAndSettle();
    expect(find.text('/schedule:0'), findsOneWidget);
    expect(observer.pushes, 2); // Only the detail page was pushed.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('/home:1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('Editor routes animate and preserve typed results',
      (tester) async {
    bool? saved;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      child: const Text('작성'),
                      onPressed: () async {
                        saved = await Navigator.push<bool>(
                            context,
                            AppPageRoute<bool>(
                                motion: AppMotion.editor,
                                builder: (context) => Scaffold(
                                    body: TextButton(
                                        child: const Text('저장'),
                                        onPressed: () =>
                                            Navigator.pop(context, true)))));
                      }),
                ))));
    await tester.tap(find.text('작성'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    expect(find.byType(SlideTransition), findsWidgets);
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(saved, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion disables tab fades and photo Heroes',
      (tester) async {
    final controller = AppTabController();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!),
          home: AppTabShell(controller: controller, builders: {
            for (final name in AppTabController.routes)
              name: (_) => _Tab(name, () {}),
          })),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이야기'));
    await tester.pump();
    expect(find.text('/community:0'), findsOneWidget);
    expect(find.byType(Hero), findsNothing);
    expect(
        find
            .byType(FadeTransition)
            .evaluate()
            .map((e) => (e.widget as FadeTransition).opacity.value)
            .any((value) => value > 0 && value < 1),
        isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
