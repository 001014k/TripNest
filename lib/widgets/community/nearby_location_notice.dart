import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Location recovery stays scrollable on smaller screens and with larger text.
class NearbyLocationNotice extends StatelessWidget {
  const NearbyLocationNotice({super.key, required this.onRetry});
  final VoidCallback onRetry;

  Future<void> _showHelp(BuildContext context) async {
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('위치 설정 방법',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Text(
                    ios
                        ? '1. 설정 > 개인정보 보호 및 보안 > 위치 서비스에서 위치 서비스를 켜주세요.\n\n2. TripNest의 위치 접근을 “앱을 사용하는 동안”으로 설정해주세요.'
                        : '1. 설정 > 위치에서 위치 사용을 켜주세요.\n\n2. 앱 > TripNest > 권한 > 위치에서 “앱 사용 중에만 허용”을 선택해주세요.',
                    style: const TextStyle(fontSize: 15, height: 1.6)),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: () async {
                      final enabled =
                          await Geolocator.isLocationServiceEnabled();
                      final opened = enabled
                          ? await Geolocator.openAppSettings()
                          : await Geolocator.openLocationSettings();
                      if (!sheetContext.mounted) return;
                      if (!opened) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    '설정을 열 수 없어요. 기기의 설정 앱에서 직접 확인해주세요.')));
                      }
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff202020),
                        minimumSize: const Size.fromHeight(50)),
                    child: const Text('위치 설정 열기')),
              ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 14),
                          const SizedBox(
                              width: 240,
                              height: 180,
                              child: CustomPaint(
                                  painter: _LocationIllustration())),
                          const SizedBox(height: 20),
                          const Text('현재 위치를 확인할 수 없어요',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.6)),
                          const SizedBox(height: 10),
                          const Text('내 주변의 여행 이야기를 보여드리기 위해\n위치 서비스가 필요해요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: Color(0xff85858d))),
                          const SizedBox(height: 18),
                          Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: const Color(0xfff5f5f6),
                                  borderRadius: BorderRadius.circular(20)),
                              child: LayoutBuilder(builder: (context, box) {
                                final instructions = [
                                  _Hint(
                                      icon: Icons.location_on_outlined,
                                      text: ios
                                          ? '설정 > 개인정보 보호\n> 위치 서비스에서'
                                          : '설정 > 위치에서\n위치 사용을 켜고'),
                                  const _Hint(
                                      icon: Icons.my_location,
                                      text: 'TripNest의 위치 접근을\n허용해주세요.'),
                                ];
                                if (box.maxWidth < 310 ||
                                    MediaQuery.textScalerOf(context).scale(1) >
                                        1.2) {
                                  return Column(children: [
                                    instructions[0],
                                    const Divider(
                                        height: 22, color: Color(0xffdddddf)),
                                    instructions[1]
                                  ]);
                                }
                                return IntrinsicHeight(
                                    child: Row(children: [
                                  Expanded(child: instructions[0]),
                                  const VerticalDivider(
                                      width: 18, color: Color(0xffdddddf)),
                                  Expanded(child: instructions[1])
                                ]));
                              })),
                          const SizedBox(height: 16),
                          SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                  onPressed: onRetry,
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 24),
                                  label: const Text('다시 시도하기',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600)),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xff202020),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(54),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(17))))),
                          const SizedBox(height: 6),
                          TextButton(
                              onPressed: () => _showHelp(context),
                              child: const Text('위치 설정 방법 보기',
                                  style: TextStyle(
                                      color: Color(0xff77777f),
                                      decoration: TextDecoration.underline,
                                      fontSize: 14))),
                        ]),
                  )),
            ));
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: const Color(0xff353539))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, height: 1.5, color: Color(0xff77777f))))
      ]);
}

class _LocationIllustration extends CustomPainter {
  const _LocationIllustration();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 240, size.height / 180);
    Path polygon(List<Offset> points) => Path()..addPolygon(points, true);
    final map = polygon([
      const Offset(14, 119),
      const Offset(67, 90),
      const Offset(125, 111),
      const Offset(181, 82),
      const Offset(229, 129),
      const Offset(177, 164),
      const Offset(120, 150),
      const Offset(64, 172)
    ]);
    canvas.drawShadow(map, Colors.black26, 8, true);
    canvas.drawPath(map, Paint()..color = const Color(0xffefeff0));
    canvas.drawPath(
        map,
        Paint()
          ..color = const Color(0xffdfdfe2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.save();
    canvas.clipPath(map);
    canvas.drawPath(
        polygon([
          const Offset(30, 119),
          const Offset(70, 103),
          const Offset(102, 119),
          const Offset(66, 155)
        ]),
        Paint()..color = const Color(0xffd8e5d5));
    canvas.drawPath(
        polygon([
          const Offset(146, 116),
          const Offset(178, 96),
          const Offset(203, 119),
          const Offset(174, 139)
        ]),
        Paint()..color = const Color(0xffdae7d6));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 5;
    canvas.drawLine(const Offset(70, 89), const Offset(64, 175), road);
    canvas.drawLine(const Offset(125, 108), const Offset(119, 154), road);
    canvas.drawLine(const Offset(180, 82), const Offset(178, 165), road);
    canvas.drawLine(const Offset(22, 125), const Offset(215, 146), road);
    canvas.drawLine(const Offset(89, 173), const Offset(164, 85), road);
    canvas.restore();
    final pin = Path()
      ..moveTo(120, 116)
      ..cubicTo(109, 102, 87, 73, 87, 57)
      ..cubicTo(87, 15, 153, 15, 153, 57)
      ..cubicTo(153, 75, 134, 103, 120, 116)
      ..close();
    canvas.drawShadow(pin, Colors.black38, 5, true);
    canvas.drawPath(
        pin,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff929399), Color(0xff55565c)])
              .createShader(const Rect.fromLTWH(87, 25, 66, 92)));
    canvas.drawCircle(const Offset(120, 57), 12, Paint()..color = Colors.white);
    canvas.drawCircle(
        const Offset(120, 57), 4, Paint()..color = const Color(0xff6c6d73));
    canvas.drawLine(
        const Offset(99, 37),
        const Offset(147, 91),
        Paint()
          ..color = const Color(0xffededee)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    for (final point in [const Offset(42, 58), const Offset(185, 30)]) {
      final p = Paint()..color = const Color(0xffe9e9eb);
      canvas.drawCircle(point, 9, p);
      canvas.drawCircle(point.translate(10, -5), 11, p);
      canvas.drawCircle(point.translate(22, 1), 8, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
