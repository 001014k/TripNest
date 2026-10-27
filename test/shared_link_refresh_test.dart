import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/services/shared_links/shared_link_service.dart';
import 'package:fluttertrip/viewmodels/shared_links/shared_link_viewmodel.dart';
import 'package:fluttertrip/models/shared_links/shared_link_model.dart';
import 'package:fluttertrip/models/shared_links/link_place_preview_model.dart';

class _Service extends SharedLinkService {
  final requests = <Completer<List<SharedLinkModel>>>[];
  @override
  Future<List<SharedLinkModel>> loadSharedLinks() {
    final request = Completer<List<SharedLinkModel>>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<void> saveSharedLinkPlace(
      String url, String platform, LinkPlacePreview preview) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-key',
        authOptions: const FlutterAuthClientOptions(
            autoRefreshToken: false, detectSessionInUri: false));
  });
  tearDownAll(() => Supabase.instance.dispose());
  test(
      'Saving refreshes listeners and late initial response cannot remove new cards',
      () async {
    final service = _Service();
    final vm = SharedLinkViewModel(service: service);
    addTearDown(vm.dispose);
    var displayed = <String>[];
    vm.addListener(() =>
        displayed = vm.sharedLinks.map((p) => p.placeTitle ?? '').toList());
    final initial = vm.loadSharedLinks();
    final save = vm.saveMultiplePlaces('https://blog.naver.com/trip/1', [
      LinkPlacePreview(
          url: '',
          title: '서울숲',
          address: '서울 성동구',
          latitude: 37,
          longitude: 127),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(service.requests.length, 2);
    service.requests.last.complete([
      SharedLinkModel(
          id: '1',
          userId: 'user',
          url: 'https://blog.naver.com/trip/1',
          platform: 'Naver',
          createdAt: DateTime(2026),
          placeTitle: '서울숲')
    ]);
    await save;
    expect(displayed, ['서울숲']);
    service.requests.first.complete([]);
    await initial;
    expect(displayed, ['서울숲']);
    expect(vm.isLoadingLinks, isFalse);
    expect(vm.errorMessage, isNull);
  });
}
