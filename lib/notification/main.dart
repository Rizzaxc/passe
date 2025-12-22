import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: const Text('Notifications'),
        suffixes: [
          FHeaderAction(
            icon: Icon(FIcons.x),
            onPress: () {
              if (context.canPop()) context.pop();
            },
          ),
        ],
      ),
      child: const Center(child: Text('Notification Page')),
    );
  }
}
