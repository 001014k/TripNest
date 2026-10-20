import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/tripnest_navigation.dart';

class AppTabController extends ChangeNotifier {
  static const routes = [
    '/home',
    '/map',
    '/schedule',
    '/community',
    '/profile'
  ];
  String current = '/home';
  Route<dynamic>? shellRoute;

  void select(String route) {
    if (!routes.contains(route) || current == route) return;
    current = route;
    notifyListeners();
  }

  static Future<void> open(BuildContext context, String route) async {
    final controller = context.read<AppTabController?>();
    final shell = controller?.shellRoute;
    if (controller != null && shell != null && shell.isActive) {
      FocusScope.of(context).unfocus();
      Navigator.of(context)
          .popUntil((candidate) => identical(candidate, shell));
      controller.select(route);
    } else {
      await Navigator.pushNamed(context, route);
    }
  }
}

/// Descendants may refresh lightweight data when a retained tab becomes visible.
class AppTabVisibility extends InheritedWidget {
  const AppTabVisibility(
      {super.key, required this.active, required super.child});
  final bool active;
  static AppTabVisibility? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTabVisibility>();
  @override
  bool updateShouldNotify(AppTabVisibility oldWidget) =>
      active != oldWidget.active;
}

class AppTabShell extends StatefulWidget {
  const AppTabShell(
      {super.key,
      required this.controller,
      required this.builders,
      this.initialRoute = '/home'});
  final AppTabController controller;
  final Map<String, WidgetBuilder> builders;
  final String initialRoute;
  @override
  State<AppTabShell> createState() => _AppTabShellState();
}

class _AppTabShellState extends State<AppTabShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200), value: 1);
  late final Animation<double> _opacity =
      _fade.drive(CurveTween(curve: Curves.easeInOut));
  final Map<String, Widget> _pages = {};
  late String _current;
  String? _previous;
  Route<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _current = widget.initialRoute;
    widget.controller.current = _current;
    widget.controller.addListener(_select);
    _fade.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && _previous != null) {
        setState(() => _previous = null);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    widget.controller.shellRoute = _route;
    if (MediaQuery.disableAnimationsOf(context) && _fade.isAnimating) {
      _fade.value = 1;
    }
  }

  void _select() {
    if (_current == widget.controller.current) return;
    setState(() {
      _previous = _current;
      _current = widget.controller.current;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _previous = null;
      _fade.value = 1;
    } else {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_select);
    if (identical(widget.controller.shellRoute, _route)) {
      widget.controller.shellRoute = null;
    }
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pages.putIfAbsent(
        _current, () => Builder(builder: widget.builders[_current]!));
    return PopScope(
      canPop: _current == '/home',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.controller.select('/home');
      },
      child: Scaffold(
        bottomNavigationBar: TripNestNavigation(
            currentRoute: _current, onSelect: widget.controller.select),
        body: Stack(fit: StackFit.expand, children: [
          for (final entry in _pages.entries)
            Offstage(
              key: ValueKey(entry.key),
              offstage: entry.key != _current && entry.key != _previous,
              child: AppTabVisibility(
                active: entry.key == _current,
                child: TickerMode(
                  enabled: entry.key == _current,
                  child: HeroMode(
                    enabled: entry.key == _current,
                    child: ExcludeSemantics(
                      excluding: entry.key != _current,
                      child: IgnorePointer(
                        ignoring: entry.key != _current,
                        child: FadeTransition(
                          opacity: entry.key == _current
                              ? _opacity
                              : ReverseAnimation(_opacity),
                          child: entry.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
