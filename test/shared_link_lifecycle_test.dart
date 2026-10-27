import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/viewmodels/shared_links/shared_link_viewmodel.dart';
import 'package:fluttertrip/views/shared_links/shared_link_view.dart';

class _LifecycleViewModel extends SharedLinkViewModel {
  final phases = <SchedulerPhase>[];
  @override
  void subscribeToChanges() {}
  @override
  Future<void> loadSharedLinks() async {
    phases.add(SchedulerBinding.instance.schedulerPhase);
    isLoadingLinks = true;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    isLoadingLinks = false;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false, detectSessionInUri: false),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  testWidgets('Initial load and page re-entry notify only after build',
      (tester) async {
    for (final name in [
      'receive_sharing_intent/messages',
      'receive_sharing_intent/events-media'
    ]) {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
    final vm = _LifecycleViewModel();
    final visible = ValueNotifier(true);
    await tester.pumpWidget(ChangeNotifierProvider<SharedLinkViewModel>.value(
      value: vm,
      child: MaterialApp(
          home: Consumer<SharedLinkViewModel>(
        builder: (_, model, child) => ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, show, child) =>
              show ? const SharedLinkView() : const SizedBox(),
        ),
      )),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    visible.value = false;
    await tester.pumpAndSettle();
    visible.value = true;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(vm.phases,
        [SchedulerPhase.postFrameCallbacks, SchedulerPhase.postFrameCallbacks]);
    await tester.pumpWidget(const SizedBox());
    visible.dispose();
    vm.dispose();
  });
}
