import 'package:flutter/material.dart';
import '../ui/logo.dart';

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
            PLogo(variant: PLogoVariant.stacked, size: 72),
            SizedBox(height: 44),
            CircularProgressIndicator(strokeWidth: 1.5),
          ],
        ),
      ),
    );
  }
}
