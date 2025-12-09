import 'package:flutter/material.dart';

class HealthTab extends StatelessWidget {
  const HealthTab({super.key});

  static final instance = HealthTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
      ),
      body: const Center(
        child: Text('Health Content'),
      ),
    );
  }
}
