import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class LobbyDetailPage extends StatelessWidget {
  final String lobbyId;
  final String? lobbyName;

  const LobbyDetailPage({
    super.key,
    required this.lobbyId,
    this.lobbyName,
  });

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: Text(lobbyName ?? lobbyId),
        suffixes: [
          FHeaderAction.back(onPress: () => context.pop()),
        ],
      ),
      child: Center(
        child: Text(
          lobbyName ?? lobbyId,
          style: context.theme.typography.xl2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
