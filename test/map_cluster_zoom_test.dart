import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart' as clusters;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertrip/viewmodels/map/mapsample_viewmodel.dart';
import 'package:fluttertrip/models/places/place_model.dart';

final bounds = LatLngBounds(southwest: const LatLng(37, 126), northeast: const LatLng(38, 128));
class FakeMapPlatform extends GoogleMapsFlutterPlatform {
  @override
  Future<double> getZoomLevel({required int mapId}) async => 12;
  @override
  Future<LatLngBounds> getVisibleRegion({required int mapId}) async => bounds;
}
class FakeController extends Fake implements GoogleMapController {
  final updates = <CameraUpdate>[];
  @override
  int get mapId => 1;
  @override
  Future<double> getZoomLevel() async => 12;
  @override
  Future<void> animateCamera(CameraUpdate update, {Duration? duration}) async { updates.add(update); }
  @override
  Future<LatLngBounds> getVisibleRegion() async => bounds;
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Cluster taps zoom before and after restoring all places', () async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://example.supabase.co', publishableKey: 'test',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false));
    final previous = GoogleMapsFlutterPlatform.instance;
    GoogleMapsFlutterPlatform.instance = FakeMapPlatform();
    final vm = MapSampleViewModel();
    final controller = FakeController();
    vm.controller = controller;
    final places = [
      Place(id: '1', title: 'A', snippet: '', latLng: const LatLng(37.5, 127)),
      Place(id: '2', title: 'B', snippet: '', latLng: const LatLng(37.5001, 127)),
    ];
    // Seed the in-memory personal markers without touching the database.
    await vm.applyKeywords({});
    vm.filteredMarkers.addAll(places.map((p) => Marker(markerId: MarkerId(p.id), position: p.latLng)));
    vm.showAllMarkers();
    await vm.applyMarkersToCluster(controller);
    final cluster = clusters.Cluster<Place>.fromItems(places);
    final first = await vm.clusterManager!.markerBuilder(cluster);
    first.onTap!();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(controller.updates, hasLength(1));
    expect(controller.updates.last.toJson(), ['newLatLngZoom', [cluster.location.latitude, cluster.location.longitude], 14.0]);
    vm.setFilteredMarkers([Marker(markerId: const MarkerId('1'), position: places.first.latLng)]);
    vm.clearPolylines();
    vm.setSelectedListId(null);
    vm.showAllMarkers();
    expect(vm.filteredMarkers, hasLength(2));
    expect(identical(vm.controller, controller), isTrue);
    final restored = await vm.clusterManager!.markerBuilder(cluster);
    restored.onTap!();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(controller.updates, hasLength(2));
    expect(controller.updates.last.toJson(), controller.updates.first.toJson());
    vm.controller = null;
    vm.dispose();
    GoogleMapsFlutterPlatform.instance = previous;
  });
}
