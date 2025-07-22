import 'package:flutter/material.dart';
import 'package:fluttertrip/views/login_option_view.dart';
import 'package:fluttertrip/views/mapsample_view.dart';
import 'package:fluttertrip/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreenView extends StatefulWidget {
  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStartupLogic();
    });
  }

  Future<void> _handleStartupLogic() async {
    await Future.delayed(const Duration(seconds: 2));
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    final user = session?.user;

    if (!mounted) return;

    if (user != null) {
      final hasNickname = await UserService().hasNickname(user.id);
      if (!mounted) return;
      if (hasNickname) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MapSampleView()),
        );
      }
    } else {
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
