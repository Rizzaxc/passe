import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../router.dart';

class NotificationIconButton extends StatelessWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FButton.icon(
      variant: .ghost,
      child: const Icon(FIcons.bell, size: 20,),
      onPress: () => const NotificationRoute().push(context),
    );
  }
}
