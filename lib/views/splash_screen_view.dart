import 'package:flutter/material.dart';
import 'package:fluttertrip/views/login_option_view.dart';
import 'package:provider/provider.dart';
import '../viewmodels/splash_viewmodel.dart';

class SplashScreenView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SplashViewModel()..startSplash(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CombinedLoginView()),
        );
      }),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<SplashViewModel>(
          builder: (context, viewModel, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 75.0,
                    backgroundColor: Colors.black,
                    backgroundImage: AssetImage('assets/kmj.png'),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'FlutterTrip',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  viewModel.isLoading ? CircularProgressIndicator() : Container(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
