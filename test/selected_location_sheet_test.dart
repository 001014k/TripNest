import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fluttertrip/widgets/map/selected_location_sheet.dart';

void main() {
  testWidgets('Selected location shows real details and both entry points work',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opens = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Align(
                alignment: Alignment.bottomCenter,
                child: SelectedLocationSheet(
                  marker: const Marker(
                      markerId: MarkerId('test'),
                      position: LatLng(37.5, 127),
                      infoWindow: InfoWindow(
                          title: '대림창고', snippet: '서울특별시 성동구 성수동1가 685-700')),
                  metadata: const {
                    'rating': 4.3,
                    'userRatingCount': 1234,
                    'primaryTypeDisplayName': {'text': '복합문화공간'}
                  },
                  onAdd: () => opens++,
                )))));
    await tester.pumpAndSettle();
    expect(find.text('4.3 (1,234)'), findsOneWidget);
    expect(find.text('복합문화공간'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    await tester.tap(find.text('대림창고'));
    await tester.tap(find.text('이 장소로 추가하기'));
    expect(opens, 2);
    expect(tester.takeException(), isNull);
  });
}
