import 'package:flutter/material.dart';
import 'package:fluttertrip/views/login_option_view.dart';
import 'package:fluttertrip/views/mapsample_view.dart';
import 'package:fluttertrip/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';
import '../shared_receiver_controller.dart';

class SplashScreenView extends StatefulWidget {
  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _handleStartupLogic();
  }

  Future<void> _handleStartupLogic() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    final user = session?.user;
    final uri = await getInitialUri();

    // 1. 공유 URI가 있으면 -> 공유 뷰로 이동
    if (uri != null && uri.scheme == "fluttertrip" && uri.host == "share") {
      final sharedText = uri.queryParameters['text'];
      if (sharedText != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SharedReceiverController(sharedText: sharedText),
          ),
        );
        return;
      }
    }

    // 2. 자동 로그인 상태면
    if (user != null) {
      final hasNickname = await UserService().hasNickname(user.id);
      if (hasNickname) {
        // ✅ 닉네임 존재 → 홈
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // ✅ 닉네임 없음 → 맵 화면에서 다이얼로그 뜨도록
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MapSampleView()),
        );
      }
    } else {
      // 3. 로그인 안되어 있으면 로그인 화면
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CombinedLoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 75.0,
              backgroundColor: Colors.black,
              backgroundImage: AssetImage('assets/kmj.png'),
            ),
            const SizedBox(height: 20),
            const Text(
              'FlutterTrip',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
