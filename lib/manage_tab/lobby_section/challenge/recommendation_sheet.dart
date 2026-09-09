import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/model/challenge.dart';
import '../../../logger/talker.dart';
import '../../../ui/main.dart';
import 'recommendation_controller.dart';

/// Post-match verdict on the lobby you just played.
///
/// Five typed tiles rather than a thumbs up/down: the kinds have no mechanical
/// difference beyond their sign, and exist so a lobby's profile reads as
/// "12 thân thiện · 2 smurf" instead of a bare integer. `smurfing` in
/// particular is the only verdict that accuses the LADDER rather than the
/// conduct — if it gets used a lot, that is the instrument telling you
/// self-declared `elo_seed` is being abused.
Future<void> showRecommendationSheet(
  BuildContext context, {
  required String matchId,
  required String subjectLobbyId,
  required String subjectLobbyName,
}) {
  return showPSheet(
    context: context,
    builder: (_) => _RecommendationSheet(
      matchId: matchId,
      subjectLobbyId: subjectLobbyId,
      subjectLobbyName: subjectLobbyName,
    ),
  );
}

class _RecommendationSheet extends ConsumerWidget {
  final String matchId;
  final String subjectLobbyId;
  final String subjectLobbyName;

  const _RecommendationSheet({
    required this.matchId,
    required this.subjectLobbyId,
    required this.subjectLobbyName,
  });

  Future<void> _cast(
    BuildContext context,
    WidgetRef ref,
    LobbyRecommendationKind kind,
  ) async {
    try {
      await ref
          .read(recommendLobbyControllerProvider(matchId).notifier)
          .cast(subjectLobbyId: subjectLobbyId, kind: kind);
      if (!context.mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: Text('challenge.verdictSheet.saved'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      talker.handle(e, st, 'recommend lobby failed');
      if (!context.mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text(recommendErrorMessage(e)),
        alignment: .bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final current = ref.watch(myRecommendationProvider(matchId)).value;
    final busy = ref.watch(recommendLobbyControllerProvider(matchId));

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'challenge.verdictSheet.title'.tr(
              namedArgs: {'lobby': subjectLobbyName},
            ),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          Text(
            'challenge.verdictSheet.explainer'.tr(),
            style: typography.body.sm.copyWith(color: colors.mutedForeground),
          ),

          PSheetSectionLabel(label: 'challenge.verdictSheet.positive'.tr()),
          for (final k in LobbyRecommendationKind.positives)
            _VerdictTile(
              kind: k,
              selected: current == k,
              enabled: !busy,
              onTap: () => _cast(context, ref, k),
            ),

          PSheetSectionLabel(label: 'challenge.verdictSheet.negative'.tr()),
          for (final k in LobbyRecommendationKind.negatives)
            _VerdictTile(
              kind: k,
              selected: current == k,
              enabled: !busy,
              onTap: () => _cast(context, ref, k),
            ),

          Text(
            'challenge.verdictSheet.changeable'.tr(),
            style: typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _VerdictTile extends StatelessWidget {
  final LobbyRecommendationKind kind;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _VerdictTile({
    required this.kind,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    // Positive and negative are toned differently so a denouncement can never
    // be cast by muscle memory while aiming for the tile above it.
    final tone = kind.isPositive ? colors.primary : colors.destructive;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? tone.withValues(alpha: 0.08) : null,
          border: Border.all(
            color: selected ? tone : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          spacing: 10,
          children: [
            Icon(
              selected ? FLucideIcons.circleCheck : FLucideIcons.circle,
              size: 18,
              color: selected ? tone : colors.mutedForeground,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    kind.getLocalizedName(context),
                    style: typography.body.md.copyWith(
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    kind.getLocalizedDescription(context),
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            // The points are on the tile so nobody casts a denouncement
            // without knowing it costs the other lobby something.
            Text(
              kind.points > 0 ? '+${kind.points}' : '${kind.points}',
              style: typography.body.sm.copyWith(
                color: tone,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
