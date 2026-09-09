import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/format.dart';
import '../../core/model/challenge.dart';
import '../../logger/talker.dart';
import '../../ui/main.dart';
import 'feed_controller.dart';
import 'friendly_offer_feed_controller.dart';

/// Confirm the terms and commit your own side.
///
/// A challenge is not fire-and-forget: sending one immediately creates a real
/// fixture in the challenger's own planner, and the handshake only reaches the
/// other lobby once enough of THEIR OWN members have RSVP'd. So this sheet does
/// two jobs — restate the terms they are accepting (they cannot negotiate; the
/// home lobby published these), and take the one number that is genuinely
/// theirs to choose: how many players must commit before the other lobby is
/// asked at all.
Future<void> showConfirmFriendlyChallengeSheet(
  BuildContext context,
  FriendlyOffer offer,
) {
  return showPSheet(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => _ConfirmSheet(offer: offer),
  );
}

class _ConfirmSheet extends ConsumerStatefulWidget {
  final FriendlyOffer offer;
  const _ConfirmSheet({required this.offer});

  @override
  ConsumerState<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends ConsumerState<_ConfirmSheet> {
  final _note = TextEditingController();
  int? _threshold;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send(String lobbyId, int memberCount) async {
    final threshold = _threshold ?? _defaultThreshold(memberCount);
    try {
      await ref
          .read(sendFriendlyChallengeControllerProvider(lobbyId).notifier)
          .send(
            offerId: widget.offer.offerId,
            threshold: threshold,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: Text('challenge.send.sent'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      talker.handle(e, st, 'send friendly challenge failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text(friendlyChallengeErrorMessage(e)),
        alignment: .bottomCenter,
      );
    }
  }

  /// Half the roster, at least two — the same shape the refereed flow computes
  /// server-side, offered here as a starting point the manager can move.
  static int _defaultThreshold(int memberCount) =>
      memberCount <= 1 ? 1 : ((memberCount + 1) ~/ 2).clamp(2, memberCount);

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final ctx = ref.watch(contextLobbyProvider).value;
    final memberCount = ctx == null
        ? 0
        : (ref.watch(contextLobbyMemberCountProvider(ctx.id)).value ?? 0);
    final busy = ctx == null
        ? false
        : ref.watch(sendFriendlyChallengeControllerProvider(ctx.id));
    final threshold = _threshold ?? _defaultThreshold(memberCount);

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          PSheetTitle(
            label: 'challenge.send.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),

          // The terms, restated. They are not negotiable — the home lobby
          // published them and the server snapshots them onto the challenge —
          // so the honest framing is "here is what you are agreeing to".
          PSheetSectionLabel(label: 'challenge.send.termsLabel'.tr()),
          PCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                _Term(
                  icon: FLucideIcons.shield,
                  text: o.lobbyName,
                  bold: true,
                ),
                _Term(
                  icon: FLucideIcons.calendar,
                  text: formatMatchDateTime(o.kickoff),
                ),
                if ((o.locationName ?? '').isNotEmpty)
                  _Term(icon: FLucideIcons.mapPin, text: o.locationName!),
                _Term(
                  icon: FLucideIcons.scrollText,
                  text: o.ruleset.getLocalizedName(
                    context,
                    param: o.rulesetParam,
                  ),
                ),
                // Everything below resolves from the AWAY side: this sheet is
                // only ever opened by the prospective challenger.
                if (o.handicapSide != ChallengeHandicapSide.none)
                  _Term(
                    icon: FLucideIcons.scale,
                    text: o.handicapSide.getLocalizedLabel(
                          context,
                          weAreHome: false,
                          amount: o.handicapAmount,
                        ) ??
                        '',
                  ),
                if (o.venueCost != null && o.venueCost! > 0)
                  _Term(
                    icon: FLucideIcons.wallet,
                    text:
                        '${formatVnd(o.venueCost!)} · '
                        '${o.costSplit.getLocalizedLabel(context, weAreHome: false)}',
                  ),
                if (o.bountyKind.isSet && o.bountyAmount != null)
                  _Term(
                    icon: FLucideIcons.trophy,
                    text:
                        '${o.bountyKind.getLocalizedName(context)}: '
                        '${formatVnd(o.bountyAmount!)}',
                  ),
                if ((o.termsNote ?? '').trim().isNotEmpty)
                  _Term(
                    icon: FLucideIcons.messageSquare,
                    text: o.termsNote!,
                  ),
              ],
            ),
          ),

          // The number that is actually theirs to choose.
          PSheetSectionLabel(label: 'challenge.send.thresholdLabel'.tr()),
          Text(
            'challenge.send.thresholdExplainer'.tr(),
            style: typography.body.sm.copyWith(color: colors.mutedForeground),
          ),
          Row(
            spacing: 12,
            children: [
              FButton.icon(
                variant: .outline,
                onPress: threshold <= 1
                    ? null
                    : () => setState(() => _threshold = threshold - 1),
                child: const Icon(FLucideIcons.minus),
              ),
              Expanded(
                child: Text(
                  'challenge.send.thresholdValue'.tr(
                    namedArgs: {
                      'n': '$threshold',
                      'total': '$memberCount',
                    },
                  ),
                  textAlign: TextAlign.center,
                  style: typography.body.md.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FButton.icon(
                variant: .outline,
                onPress: threshold >= memberCount
                    ? null
                    : () => setState(() => _threshold = threshold + 1),
                child: const Icon(FLucideIcons.plus),
              ),
            ],
          ),

          FTextField.multiline(
            label: Text('challenge.send.noteLabel'.tr()),
            hint: 'challenge.send.noteHint'.tr(),
            control: FTextFieldControl.managed(controller: _note),
            maxLines: 2,
          ),

          // What actually happens next, so nobody expects an instant match.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colors.primary.withValues(alpha: 0.08),
              border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Icon(FLucideIcons.info, size: 16, color: colors.primary),
                Expanded(
                  child: Text(
                    'challenge.send.whatHappensNext'.tr(
                      namedArgs: {'n': '$threshold'},
                    ),
                    style: typography.body.sm,
                  ),
                ),
              ],
            ),
          ),

          FButton(
            onPress: (ctx == null || busy || memberCount < 1)
                ? null
                : () => _send(ctx.id, memberCount),
            child: busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('challenge.send.confirm'.tr()),
          ),
        ],
      ),
    );
  }
}

class _Term extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;
  const _Term({required this.icon, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: colors.mutedForeground),
        ),
        Expanded(
          child: Text(
            text,
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
