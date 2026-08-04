import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../router.dart';
import '../../../ui/empty_section_placeholder.dart';
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
      error: (_, _) => Padding(
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
      return PEmptySectionPlaceholder(
        subtitle: 'lobby.detail.noMembers'.tr(),
      );
    }

    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
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
    // Lobby mates are the highest-intent source of friend requests — people
    // you've actually played with — so the chip is a link to their page.
    return GestureDetector(
      onTap: () =>
          UserRoute(id: member.userId, $extra: member.username).push(context),
      child: Column(
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
              style: context.theme.typography.body.md.copyWith(
                color: context.theme.colors.secondaryForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            member.username,
            style: context.theme.typography.body.xs,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
