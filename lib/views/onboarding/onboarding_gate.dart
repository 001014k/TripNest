import 'package:flutter/material.dart';
import '../../services/onboarding/onboarding_service.dart';
import 'onboarding_view.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, required this.child, this.shouldDefer});
  final Widget child;
  final bool Function()? shouldDefer;
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _seen;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    bool seen;
    try {
      seen = await OnboardingService().hasSeen(OnboardingService.introKey);
    } catch (_) {
      seen = true;
    } // Preference errors must never block app entry.
    if (mounted) {
      setState(() => _seen = seen || (widget.shouldDefer?.call() ?? false));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_seen == null) {
      return const Scaffold(backgroundColor: Color(0xFFFAFAFA));
    }
    if (_seen!) return widget.child;
    return OnboardingView(onFinished: () => setState(() => _seen = true));
  }
}
