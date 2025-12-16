import 'package:flutter/material.dart';

/// splash page shown while we check authentication status
class SplashScreen extends StatelessWidget {
  /// splash page shown while we check authentication status
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            CircularProgressIndicator(strokeWidth: 1.5),
          ],
        ),
      ),
    );
  }
}
