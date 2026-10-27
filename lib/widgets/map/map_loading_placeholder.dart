import 'package:flutter/material.dart';
import '../home/home_skeleton.dart';

class MapLoadingPlaceholder extends StatelessWidget {
  const MapLoadingPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF3F4F5),
    child: Stack(fit: StackFit.expand, children: [
      CustomPaint(painter: _RoadsPainter()),
      Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.location_on_outlined, size: 30),
          SizedBox(height: 10),
          Text('지도를 준비하고 있어요', style: TextStyle(fontSize: 14, color: Color(0xFF777B84))),
        ]),
      )),
    ]),
  );
}

class _RoadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = Colors.white..strokeWidth = 16..style = PaintingStyle.stroke;
    for (final fraction in [.2, .5, .8]) {
      canvas.drawPath(Path()..moveTo(0, size.height * fraction)
        ..lineTo(size.width * .35, size.height * fraction)
        ..lineTo(size.width * .55, size.height * (fraction + .1))
        ..lineTo(size.width, size.height * (fraction + .1)), road);
    }
    canvas.drawLine(Offset(size.width * .28, 0), Offset(size.width * .4, size.height), road);
    canvas.drawLine(Offset(size.width * .78, 0), Offset(size.width * .65, size.height), road);
  }
  @override
  bool shouldRepaint(_RoadsPainter oldDelegate) => false;
}

class MapPlaceLoadingSheet extends StatelessWidget {
  const MapPlaceLoadingSheet({super.key});
  @override
  Widget build(BuildContext context) => const SafeArea(top: false,
    child: Padding(padding: EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      HomeSkeleton(height: 150),
      SizedBox(height: 12),
      HomeSkeleton(height: 60),
    ])),
  );
}
