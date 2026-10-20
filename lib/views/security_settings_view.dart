import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../viewmodels/security_settings_viewmodel.dart';
import '../widgets/tripnest_navigation.dart';

class SecuritySettingsView extends StatelessWidget {
  const SecuritySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = SecuritySettingsViewModel();
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 14),
            child: TripNestHeader(
              onBack: () => Navigator.pop(context),
              trailing: const SizedBox.shrink(),
            ),
          ),
          Expanded(
              child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('로그인 및 보안',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -1,
                      height: 1.3)),
              const SizedBox(height: 10),
              const Text('연결된 로그인 계정을 확인하세요.',
                  style:
                      TextStyle(fontSize: 16, color: _secondary, height: 1.5)),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F5),
                    borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Icon(Icons.verified_user_outlined,
                      size: 23, color: Colors.black),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Text('로그인 계정 ${vm.connectedCount}개 연결됨',
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF50535D)))),
                ]),
              ),
              const SizedBox(height: 36),
              const _SectionTitle('연결된 로그인 계정'),
              const SizedBox(height: 14),
              Container(
                decoration: _cardDecoration,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(children: [
                  _AccountRow(
                      title: '이메일',
                      connected: vm.providers.contains('email'),
                      description: '이메일 계정이 연결되어 있어요.',
                      detail: vm.providers.contains('email') ? vm.email : null,
                      icon: const Icon(Icons.mail_outline_rounded,
                          size: 31, color: Colors.black)),
                  const Divider(
                      height: 1, thickness: .7, color: Color(0xFFE4E5E8)),
                  _AccountRow(
                      title: 'Google',
                      connected: vm.providers.contains('google'),
                      description: 'Google 계정이 연결되어 있어요.',
                      icon: const SizedBox(
                          width: 31,
                          height: 31,
                          child: CustomPaint(painter: _GoogleMarkPainter()))),
                  const Divider(
                      height: 1, thickness: .7, color: Color(0xFFE4E5E8)),
                  _AccountRow(
                      title: 'Kakao',
                      connected: vm.providers.contains('kakao'),
                      description: '카카오 계정이 연결되어 있어요.',
                      icon: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset('assets/kakao_icon.png',
                              width: 38, height: 38))),
                ]),
              ),
              const SizedBox(height: 30),
              const _SectionTitle('계정 보호'),
              const SizedBox(height: 14),
              Container(
                decoration: _cardDecoration,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: const Row(children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 31, color: Colors.black),
                  SizedBox(width: 19),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('공용 기기에서는 로그아웃해 주세요.',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                letterSpacing: -.5,
                                height: 1.4)),
                        SizedBox(height: 5),
                        Text('낯선 로그인 내역이 있다면 계정 정보를 확인해 주세요.',
                            style: TextStyle(
                                fontSize: 12, color: _secondary, height: 1.5)),
                      ])),
                ]),
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}

const _secondary = Color(0xFF6B6E79);
final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(15),
  border: Border.all(color: const Color(0xFFECEDEF)),
  boxShadow: const [
    BoxShadow(color: Color(0x04000000), blurRadius: 18, offset: Offset(0, 5))
  ],
);

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: -.5));
}

class _AccountRow extends StatelessWidget {
  final String title;
  final String description;
  final String? detail;
  final bool connected;
  final Widget icon;
  const _AccountRow(
      {required this.title,
      required this.description,
      required this.connected,
      required this.icon,
      this.detail});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
          color: connected ? const Color(0xFF161616) : const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (connected) ...[
          const Icon(Icons.check_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 5),
        ],
        Text(connected ? '연결됨' : '미연결',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: connected ? Colors.white : const Color(0xFF5A5D67))),
      ]),
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(children: [
        SizedBox(width: 40, child: Center(child: icon)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.3)),
          const SizedBox(height: 4),
          Text(connected ? description : '연결된 계정이 없어요.',
              style: const TextStyle(
                  fontSize: 12, color: _secondary, height: 1.4)),
          if (detail?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(detail!,
                style: const TextStyle(
                    fontSize: 12, color: _secondary, height: 1.4)),
          ],
          if (largeText) ...[const SizedBox(height: 8), badge],
        ])),
        if (!largeText) ...[const SizedBox(width: 8), badge],
      ]),
    );
  }
}

/// Four-color G without the dark circular background of the sign-in asset.
class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    const rect = Rect.fromLTWH(4, 4, 24, 24);
    for (final segment in [
      (40.0, 95.0, const Color(0xFF34A853)),
      (135.0, 60.0, const Color(0xFFFBBC05)),
      (195.0, 115.0, const Color(0xFFEA4335)),
      (-5.0, 45.0, const Color(0xFF4285F4)),
    ]) {
      canvas.drawArc(rect, segment.$1 * math.pi / 180,
          segment.$2 * math.pi / 180, false, pen..color = segment.$3);
    }
    canvas.drawPath(
        Path()
          ..moveTo(17, 16)
          ..lineTo(29, 16)
          ..lineTo(29, 19),
        pen..color = const Color(0xFF4285F4));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
