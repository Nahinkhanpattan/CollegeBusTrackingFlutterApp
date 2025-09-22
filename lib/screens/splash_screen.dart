import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            SizedBox(
              width: 150,
              height: 150,
              child: Image.asset('assets/images/upashtit-logo-new.png'),
            ),
            const SizedBox(height: 32),
            // Horizontal loading bar
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                color: Colors.blue,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}