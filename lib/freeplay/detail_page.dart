import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/guest_prompt.dart';
import '../router.dart';
import '../ui/main.dart';
import 'card.dart';
import 'chat_sheet.dart';
import 'model.dart';
import 'repository.dart';

class FreeplayDetailPage extends ConsumerWidget {
  final String id;
  const FreeplayDetailPage({required this.id, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(freeplayDetailProvider(id));
    return FScaffold(
      header: FHeader.nested(
        title: Text('freeplay.activityDetails'.tr()),
        prefixes: [
          FHeaderAction.back(
            onPress: () => context.canPop()
                ? context.pop()
                : const HomeFreeplayRoute().go(context),
          ),
        ],
      ),
      child: detail.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (_, _) =>
            Center(child: Text('freeplay.activityLoadFailed'.tr())),
        data: (activity) => activity == null
            ? Center(child: Text('freeplay.activityClosed'.tr()))
            : _Body(activity: activity),
      ),
    );
  }
}

class FreeplayChatLandingPage extends StatefulWidget {
  final String activityId;
  final String requestId;
  const FreeplayChatLandingPage({
    required this.activityId,
    required this.requestId,
    super.key,
  });

  @override
  State<FreeplayChatLandingPage> createState() =>
      _FreeplayChatLandingPageState();
}

class _FreeplayChatLandingPageState extends State<FreeplayChatLandingPage> {
  bool _opened = false;
  @override
  Widget build(BuildContext context) {
    if (!_opened) {
      _opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showFreeplayChatSheet(context, widget.requestId);
        }
      });
    }
    return FreeplayDetailPage(id: widget.activityId);
  }
}

class _Body extends ConsumerStatefulWidget {
  final FreeplayActivity activity;
  const _Body({required this.activity});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  Future<void> _request() async {
    if (!ensureSignedIn(context, ref) || _busy) return;
    final message = TextEditingController();
    await showFDialog<void>(
      context: context,
      builder: (dialogContext, style, animation) => PConfirmDialog(
        animation: animation,
        title: Text('freeplay.requestSeat'.tr()),
        body: FTextField(
          control: FTextFieldControl.managed(controller: message),
          hint: 'freeplay.requestMessageHint'.tr(),
          maxLines: 3,
        ),
        actions: [
          FButton(
            variant: .ghost,
            onPress: () => Navigator.pop(dialogContext),
            child: Text('freeplay.later'.tr()),
          ),
          FButton(
            onPress: () async {
              Navigator.pop(dialogContext);
              setState(() => _busy = true);
              try {
                final requestId = await ref
                    .read(freeplayRepositoryProvider)
                    .requestSeat(widget.activity.id, message: message.text);
                ref.invalidate(freeplayDetailProvider(widget.activity.id));
                ref.invalidate(freeplayFeedProvider);
                if (mounted) await showFreeplayChatSheet(context, requestId);
              } catch (_) {
                if (mounted) {
                  showFToast(
                    context: context,
                    variant: .destructive,
                    title: Text('freeplay.requestFailed'.tr()),
                  );
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
            child: Text('freeplay.sendRequest'.tr()),
          ),
        ],
      ),
    );
    message.dispose();
  }

  Future<void> _cancel() async {
    final requestId = widget.activity.myRequestId;
    if (requestId == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(freeplayRepositoryProvider).cancelRequest(requestId);
      ref.invalidate(freeplayDetailProvider(widget.activity.id));
      ref.invalidate(freeplayFeedProvider);
      ref.invalidate(myFreeplayProvider(false));
    } catch (_) {
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('freeplay.cancelRequestFailed'.tr()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final status = a.myRequestStatus;
    final accepted = status == FreeplayRequestStatus.accepted;
    final pending = status == FreeplayRequestStatus.pending;
    final now = DateTime.now();
    final ended = !now.isBefore(a.endTime);
    final viewerHostId = ref.watch(linkedFreeplayHostProvider).value?.id;
    final isHost = viewerHostId == a.hostId;
    final chatWritable =
        a.myRequestId != null &&
        ((pending && !ended) ||
            ((accepted || status == FreeplayRequestStatus.hostCancelled) &&
                now.isBefore(a.endTime.add(const Duration(days: 7)))));
    final canCancel = (pending || accepted) && !ended;
    final canRequest =
        !isHost &&
        !ended &&
        !a.isFull &&
        (status == null || status == FreeplayRequestStatus.cancelled);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(freeplayDetailProvider(a.id));
        await ref.read(freeplayDetailProvider(a.id).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          FreeplayActivitySummaryCard(
            activity: a,
            compact: true,
            showHost: false,
            showAddress: true,
            showMetadata: false,
          ),
          const SizedBox(height: 12),
          FTappable(
            onPress: () => FreeplayHostRoute(id: a.hostId).push(context),
            child: PCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: pbAmber,
                    backgroundImage: a.hostAvatarUrl == null
                        ? null
                        : NetworkImage(a.hostAvatarUrl!),
                    child: a.hostAvatarUrl == null
                        ? const Icon(FLucideIcons.ticket, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.hostName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.theme.typography.body.lg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'freeplay.verifiedHost'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.theme.typography.body.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    FLucideIcons.chevronRight,
                    color: context.theme.colors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PCard(
            child: Column(
              children: [
                _Line(
                  icon: FLucideIcons.users,
                  title: 'freeplay.peopleCount'.tr(
                    namedArgs: {
                      'accepted': '${a.acceptedCount}',
                      'capacity': '${a.capacity}',
                    },
                  ),
                  subtitle: a.isFull
                      ? 'freeplay.full'.tr()
                      : 'freeplay.seatsLeft'.tr(
                          namedArgs: {'count': '${a.seatsLeft}'},
                        ),
                ),
                Divider(height: 1, color: context.theme.colors.border),
                _Line(
                  icon: FLucideIcons.badgeDollarSign,
                  title: 'freeplay.prices'.tr(
                    namedArgs: {
                      'male': _formatVnd(context, a.malePrice),
                      'female': _formatVnd(context, a.femalePrice),
                    },
                  ),
                  subtitle: 'freeplay.payHostDirectly'.tr(),
                ),
                Divider(height: 1, color: context.theme.colors.border),
                _Line(
                  icon: FLucideIcons.gauge,
                  title: a.recommendedSkills
                      .map((skill) => 'freeplay.skill.$skill'.tr())
                      .join(' · '),
                  subtitle:
                      a.mySkill != null &&
                          !a.recommendedSkills.contains(a.mySkill)
                      ? 'freeplay.skillMismatch'.tr()
                      : 'freeplay.selfAssessedSkill'.tr(),
                ),
              ],
            ),
          ),
          if (a.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            PCard(
              title: Text('freeplay.description'.tr()),
              child: Text(a.description),
            ),
          ],
          if (accepted && a.roster.isNotEmpty) ...[
            const SizedBox(height: 12),
            PCard(
              title: Text('freeplay.participants'.tr()),
              child: Column(
                children: [
                  for (var i = 0; i < a.roster.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: context.theme.colors.border),
                    _ParticipantRow(member: a.roster[i]),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (chatWritable)
            FButton(
              onPress: () => showFreeplayChatSheet(context, a.myRequestId!),
              child: Text('freeplay.openChat'.tr()),
            ),
          if (chatWritable && canCancel) const SizedBox(height: 8),
          if (canCancel)
            FButton(
              variant: .outline,
              onPress: _busy ? null : _cancel,
              child: Text(
                accepted
                    ? 'freeplay.cancelSpot'.tr()
                    : 'freeplay.cancelRequest'.tr(),
              ),
            ),
          if (canRequest)
            FButton(
              onPress: _busy ? null : _request,
              child: Text('freeplay.requestSeat'.tr()),
            ),
          if (isHost)
            Text('freeplay.youAreHost'.tr(), textAlign: TextAlign.center),
          if (!isHost && !chatWritable && !canCancel && !canRequest)
            Text(
              ended
                  ? 'freeplay.state.ended'.tr()
                  : a.isFull && status == null
                  ? 'freeplay.state.full'.tr()
                  : switch (status) {
                      FreeplayRequestStatus.declined =>
                        'freeplay.state.declined'.tr(),
                      FreeplayRequestStatus.hostCancelled =>
                        'freeplay.state.hostCancelled'.tr(),
                      FreeplayRequestStatus.lapsed =>
                        'freeplay.state.lapsed'.tr(),
                      FreeplayRequestStatus.blocked =>
                        'freeplay.state.blocked'.tr(),
                      _ => 'freeplay.state.inactive'.tr(),
                    },
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

String _formatVnd(BuildContext context, num amount) =>
    NumberFormat.simpleCurrency(
      locale: context.locale.toLanguageTag(),
      name: 'VND',
      decimalDigits: 0,
    ).format(amount);

class _Line extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Line({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.theme.colors.mutedForeground),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ParticipantRow extends StatelessWidget {
  final FreeplayRosterMember member;

  const _ParticipantRow({required this.member});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: context.theme.colors.secondary,
          child: const Icon(FLucideIcons.user, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (member.skill != null)
                Text(
                  'freeplay.skill.${member.skill}'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
