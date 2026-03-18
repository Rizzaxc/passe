import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'controller.dart';

class MembersSection extends ConsumerWidget {
  final String lobbyId;

  const MembersSection({super.key, required this.lobbyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(lobbyMembersControllerProvider(lobbyId));

    return membersAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'errorGeneric'.tr(),
          style: TextStyle(color: Colors.red),
        ),
      ),
      data: (members) => _MembersRow(members: members),
    );
  }
}

class _MembersRow extends StatelessWidget {
  final List<LobbyMemberInfo> members;

  const _MembersRow({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'lobby.detail.noMembers'.tr(),
          style: context.theme.typography.sm
              .copyWith(color: context.theme.colors.mutedForeground),
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _MemberChip(member: members[i]),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final LobbyMemberInfo member;

  const _MemberChip({required this.member});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: context.theme.colors.secondary,
          child: Text(
            member.username.isNotEmpty
                ? member.username[0].toUpperCase()
                : '?',
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.secondaryForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          member.username,
          style: context.theme.typography.xs,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
