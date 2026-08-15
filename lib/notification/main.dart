import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../manage_tab/lobby_section/activity/activity_at_risk_response_controller.dart';
import '../manage_tab/lobby_section/lobby_invite_response_controller.dart';
import '../notifications/notification_kind.dart';
import '../notifications/notification_router.dart';
import '../router.dart';
import '../ui/main.dart';
import 'notification_center_controller.dart';
import 'notification_item.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  void _confirmClearRead(BuildContext context, WidgetRef ref) {
    showFDialog(
      context: context,
      builder: (dialogCtx, style, animation) => PConfirmDialog(
        animation: animation,
        title: Text('notification.clearRead.title'.tr()),
        body: Text('notification.clearRead.message'.tr()),
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(),
            child: Text('notification.clearRead.cancel'.tr()),
          ),
          FButton(
            variant: .destructive,
            onPress: () {
              Navigator.of(dialogCtx).pop();
              ref
                  .read(notificationCenterControllerProvider.notifier)
                  .clearRead();
            },
            child: Text('notification.clearRead.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(notificationCenterControllerProvider);
    final items = itemsAsync.value ?? const <NotificationItem>[];
    final hasUnread = items.any((i) => i.isUnread);
    final hasRead = items.any((i) => !i.isUnread);

    return FScaffold(
      header: FHeader(
        title: Text('notification.title'.tr()),
        suffixes: [
          if (hasRead)
            FHeaderAction(
              icon: const Icon(FLucideIcons.trash2),
              onPress: () => _confirmClearRead(context, ref),
            ),
          if (hasUnread)
            FHeaderAction(
              icon: const Icon(FLucideIcons.checkCheck),
              onPress: () => ref
                  .read(notificationCenterControllerProvider.notifier)
                  .markAllRead(),
            ),
          FHeaderAction(
            icon: const Icon(FLucideIcons.x),
            onPress: () {
              if (context.canPop()) context.pop();
            },
          ),
        ],
      ),
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            PEmptySectionPlaceholder(
              hero: Icon(
                FLucideIcons.bellOff,
                size: 64,
                color: context.theme.colors.mutedForeground,
              ),
              subtitle: 'errorGeneric'.tr(),
            ),
          ],
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                PEmptySectionPlaceholder(
                  hero: Icon(
                    FLucideIcons.bellOff,
                    size: 64,
                    color: context.theme.colors.mutedForeground,
                  ),
                  title: 'notification.empty.title'.tr(),
                  subtitle: 'notification.empty.subtitle'.tr(),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationCenterControllerProvider);
              await ref.read(notificationCenterControllerProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _NotificationRow(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

IconData _iconFor(NotificationKind? kind) => switch (kind) {
  NotificationKind.activityScheduled => FLucideIcons.calendarPlus,
  NotificationKind.activityConfirmed => FLucideIcons.calendarCheck,
  NotificationKind.proSessionReminder => FLucideIcons.clock,
  NotificationKind.challengerConfirmed ||
  NotificationKind.challengeReceived ||
  NotificationKind.challengeDeclined ||
  NotificationKind.challengeScheduled => FLucideIcons.swords,
  NotificationKind.challengeLapsed => FLucideIcons.calendarX,
  NotificationKind.matchResultRecorded => FLucideIcons.trophy,
  NotificationKind.lobbyInvite => FLucideIcons.users,
  NotificationKind.lobbyJoinRequest => FLucideIcons.userPlus,
  NotificationKind.lobbyJoinRequestApproved => FLucideIcons.userCheck,
  NotificationKind.lobbyJoinRequestDenied => FLucideIcons.userX,
  NotificationKind.memberKicked => FLucideIcons.userMinus,
  NotificationKind.professionalBookingRequested ||
  NotificationKind.professionalBookingConfirmed ||
  NotificationKind.professionalBookingRejected => FLucideIcons.briefcase,
  NotificationKind.friendRequest ||
  NotificationKind.friendAccepted => FLucideIcons.userPlus,
  NotificationKind.paymentRequested ||
  NotificationKind.debtCollected => FLucideIcons.wallet,
  NotificationKind.freeplayRequestReceived ||
  NotificationKind.freeplayRequestAccepted ||
  NotificationKind.freeplayRequestDeclined ||
  NotificationKind.freeplayRequestCancelled ||
  NotificationKind.freeplayActivityCancelled ||
  NotificationKind.freeplayChatMessage => FLucideIcons.ticket,
  // A course message reads as a message; everything else about a course
  // reads as coaching.
  NotificationKind.courseMessage => FLucideIcons.messageCircle,
  NotificationKind.courseEnrollmentOffer ||
  NotificationKind.courseEnrollmentAccepted ||
  NotificationKind.courseActivityProposed ||
  NotificationKind.courseActivityApproved ||
  NotificationKind.courseActivityChanged ||
  NotificationKind.courseSessionReport ||
  NotificationKind.courseEnded ||
  NotificationKind.courseMemberRemoved => FLucideIcons.graduationCap,
  NotificationKind.activityAtRiskOrganizer ||
  NotificationKind.activityAtRiskMember => FLucideIcons.calendarClock,
  NotificationKind.activityCancelledLowTurnout => FLucideIcons.calendarX,
  null => FLucideIcons.bell,
};

String _relativeTime(BuildContext context, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'notification.time.justNow'.tr();
  if (diff.inMinutes < 60) {
    return 'notification.time.minutesAgo'.plural(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return 'notification.time.hoursAgo'.plural(diff.inHours);
  }
  if (diff.inDays < 7) {
    return 'notification.time.daysAgo'.plural(diff.inDays);
  }
  return DateFormat.yMd(context.locale.toLanguageTag()).format(dt);
}

class _NotificationRow extends ConsumerWidget {
  final NotificationItem item;

  const _NotificationRow({required this.item});

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref, {
    String? lobbyInviteStatus,
  }) async {
    if (item.isUnread) {
      await ref
          .read(notificationCenterControllerProvider.notifier)
          .markRead(item.id);
    }

    // The in-app list already watches this invite's status for its inline
    // Accept/Reject — reuse it to shortcut straight to the lobby (or do
    // nothing on decline) instead of round-tripping through the preview
    // page, which is the generic fallback for OS push taps that can't do
    // this cheap a check before routing.
    if (item.kind == NotificationKind.lobbyInvite) {
      if (lobbyInviteStatus == 'declined') return;
      if (lobbyInviteStatus == 'accepted') {
        final lobbyId = item.data['lobby_id'] as String?;
        if (lobbyId != null && context.mounted) {
          context.go(LobbyDetailRoute(id: lobbyId).location);
        }
        return;
      }
    }

    final location = resolveNotificationLocation({
      ...item.data,
      'kind': item.kind?.value,
    });
    if (location == null || !context.mounted) return;
    // go(), not push(), for most kinds: they resolve to a page nested under
    // the bottom-tab shell (e.g. LobbyDetailRoute under /manage/lobby/:id).
    // Pushing a full nested shell path on top of a root-level screen like
    // this one collides with the shell's own preserved branch state
    // (go_router throws a duplicate-GlobalKey assertion) — go() replaces the
    // stack instead of appending to it, so it can't collide.
    // Push-only routes (e.g. UserRoute, LobbyInvitePreviewRoute) are the
    // opposite: they're never part of the shell tree, so go() would discard
    // the shell instead.
    if (isPushOnlyNotificationLocation(location)) {
      context.push(location);
    } else {
      context.go(location);
    }
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(notificationCenterControllerProvider.notifier)
          .delete(item.id);
    } catch (e, st) {
      Talker().handle(e, st, 'notification deletion failed');
      if (!context.mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('errorGeneric'.tr()),
        alignment: .bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    final recordId = item.kind == NotificationKind.lobbyInvite
        ? item.data['record_id'] as String?
        : null;
    final lobbyInviteStatus = recordId == null
        ? null
        : ref.watch(lobbyInviteStatusProvider(recordId)).value;

    final atRiskActivityId =
        (item.kind == NotificationKind.activityAtRiskOrganizer ||
            item.kind == NotificationKind.activityAtRiskMember)
        ? item.data['target_id'] as String?
        : null;
    final radius = BorderRadius.circular(14);
    final frameColor = item.isUnread
        ? pbBlueDeep.withValues(alpha: 0.28)
        : colors.border.withValues(alpha: 0.72);

    return POffsetFrame(
      offsetColor: frameColor,
      borderRadius: radius,
      offset: 2,
      child: FTappable(
        onPress: () =>
            _onTap(context, ref, lobbyInviteStatus: lobbyInviteStatus),
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(
              color: item.isUnread
                  ? pbBlueDeep.withValues(alpha: 0.16)
                  : pbInk.withValues(alpha: 0.10),
            ),
            borderRadius: radius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.isUnread
                            ? pbBlueDeep.withValues(alpha: 0.09)
                            : colors.muted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _iconFor(item.kind),
                        size: 18,
                        color: item.isUnread
                            ? pbBlueDeep
                            : colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 3,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: typography.body.sm.copyWith(
                                    color: pbInk,
                                    fontWeight: item.isUnread
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              if (item.isUnread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 5),
                                  decoration: const BoxDecoration(
                                    color: pbBlueDeep,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text.rich(
                            TextSpan(
                              children: _notificationBodySpans(
                                item,
                                regularStyle: typography.body.xs.copyWith(
                                  color: colors.mutedForeground,
                                  height: 1.35,
                                ),
                                primaryEmphasisStyle: typography.body.xs
                                    .copyWith(
                                      color: pbGreen,
                                      fontWeight: FontWeight.w800,
                                      height: 1.35,
                                    ),
                                secondaryEmphasisStyle: typography.body.xs
                                    .copyWith(
                                      color: pbBlueDeep,
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _relativeTime(context, item.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.body.xs.copyWith(
                              color: colors.mutedForeground.withValues(
                                alpha: 0.78,
                              ),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'notification.delete'.tr(),
                      child: FButton.icon(
                        variant: .ghost,
                        size: .xs,
                        onPress: () => unawaited(_onDelete(context, ref)),
                        child: Icon(
                          FLucideIcons.trash2,
                          size: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                if (recordId != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _LobbyInviteActions(recordId: recordId),
                  ),
                ] else if (atRiskActivityId != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ActivityAtRiskActions(
                      activityId: atRiskActivityId,
                      isOrganizer:
                          item.kind == NotificationKind.activityAtRiskOrganizer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _BodyEmphasis { none, primary, secondary }

typedef _PresentationField = ({String key, _BodyEmphasis emphasis});

/// Highlights only exact semantic values snapshotted by the notification
/// emitter. There is deliberately no text inference here: legacy rows and new
/// notification kinds without an explicit presentation contract stay plain.
List<InlineSpan> _notificationBodySpans(
  NotificationItem item, {
  required TextStyle regularStyle,
  required TextStyle primaryEmphasisStyle,
  required TextStyle secondaryEmphasisStyle,
}) {
  final body = item.body;
  if (body.isEmpty) return [TextSpan(text: body, style: regularStyle)];
  final emphasis = List<_BodyEmphasis>.filled(body.length, _BodyEmphasis.none);
  final rawPresentation = item.data['presentation'];
  if (rawPresentation is! Map) {
    return [TextSpan(text: body, style: regularStyle)];
  }
  final presentation = rawPresentation.cast<String, dynamic>();

  void emphasizeExact(String key, _BodyEmphasis level) {
    final value = presentation[key];
    if (value is! String || value.trim().isEmpty) return;
    var start = body.indexOf(value);
    while (start >= 0) {
      for (var i = start; i < start + value.length; i++) {
        if (emphasis[i] == _BodyEmphasis.none) emphasis[i] = level;
      }
      start = body.indexOf(value, start + value.length);
    }
  }

  final fields = _presentationFieldsFor(item.kind);
  // Entity/location values use the primary brand color and take precedence
  // over secondary date/money values if two exact strings overlap.
  for (final field in fields.where(
    (field) => field.emphasis == _BodyEmphasis.primary,
  )) {
    emphasizeExact(field.key, field.emphasis);
  }
  for (final field in fields.where(
    (field) => field.emphasis == _BodyEmphasis.secondary,
  )) {
    emphasizeExact(field.key, field.emphasis);
  }

  if (!emphasis.any((level) => level != _BodyEmphasis.none)) {
    return [TextSpan(text: body, style: regularStyle)];
  }

  final spans = <InlineSpan>[];
  var start = 0;
  var current = emphasis.first;
  for (var i = 1; i <= body.length; i++) {
    final next = i == body.length ? null : emphasis[i];
    if (next == current) continue;
    spans.add(
      TextSpan(
        text: body.substring(start, i),
        style: switch (current) {
          _BodyEmphasis.none => regularStyle,
          _BodyEmphasis.primary => primaryEmphasisStyle,
          _BodyEmphasis.secondary => secondaryEmphasisStyle,
        },
      ),
    );
    start = i;
    if (next != null) current = next;
  }
  return spans;
}

const _lobby = (key: 'lobby_name', emphasis: _BodyEmphasis.primary);
const _username = (key: 'username', emphasis: _BodyEmphasis.primary);
const _weekday = (key: 'weekday', emphasis: _BodyEmphasis.secondary);
const _time = (key: 'time', emphasis: _BodyEmphasis.secondary);
const _amount = (key: 'amount', emphasis: _BodyEmphasis.secondary);
const _location = (key: 'location_name', emphasis: _BodyEmphasis.primary);
const _address = (key: 'address', emphasis: _BodyEmphasis.primary);

List<_PresentationField> _presentationFieldsFor(NotificationKind? kind) =>
    switch (kind) {
      NotificationKind.activityScheduled => const [
        _lobby,
        _weekday,
        _time,
        _location,
        _address,
      ],
      NotificationKind.activityConfirmed => const [
        _lobby,
        _weekday,
        _time,
        _location,
        _address,
      ],
      NotificationKind.lobbyInvite => const [_username, _lobby],
      NotificationKind.lobbyJoinRequestApproved ||
      NotificationKind.lobbyJoinRequestDenied ||
      NotificationKind.memberKicked => const [_lobby],
      NotificationKind.challengerConfirmed ||
      NotificationKind.challengeReceived ||
      NotificationKind.challengeDeclined ||
      NotificationKind.challengeScheduled ||
      NotificationKind.challengeLapsed ||
      NotificationKind.matchResultRecorded => const [
        _lobby,
        _weekday,
        _time,
        _amount,
        _location,
        _address,
      ],
      NotificationKind.lobbyJoinRequest => const [_username, _lobby],
      NotificationKind.professionalBookingRequested ||
      NotificationKind.professionalBookingConfirmed ||
      NotificationKind.professionalBookingRejected ||
      NotificationKind.proSessionReminder => const [
        _username,
        _weekday,
        _time,
        _amount,
        _location,
        _address,
      ],
      NotificationKind.friendRequest ||
      NotificationKind.friendAccepted => const [_username],
      NotificationKind.paymentRequested ||
      NotificationKind.debtCollected => const [_username, _lobby, _amount],
      NotificationKind.freeplayRequestReceived ||
      NotificationKind.freeplayRequestAccepted ||
      NotificationKind.freeplayRequestDeclined ||
      NotificationKind.freeplayRequestCancelled ||
      NotificationKind.freeplayActivityCancelled ||
      NotificationKind.freeplayChatMessage => const [
        _username,
        _weekday,
        _time,
        _amount,
        _location,
        _address,
      ],
      _ => const [],
    };

/// Inline Accept/Reject for a `lobby_invite` notification, or (once
/// resolved) a small hint of what tapping the card now does. This is the
/// primary accept surface — the old Manage▸Lobby mail-icon sheet is retired.
class _LobbyInviteActions extends ConsumerWidget {
  final String recordId;

  const _LobbyInviteActions({required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(lobbyInviteStatusProvider(recordId));
    final colors = context.theme.colors;

    return statusAsync.when(
      loading: () => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) => switch (status) {
        'accepted' => Icon(
          FLucideIcons.chevronRight,
          size: 18,
          color: colors.primary,
        ),
        'declined' => Text(
          'lobby.invites.declined'.tr(),
          style: context.theme.typography.body.xs.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        _ => _LobbyInvitePendingButtons(recordId: recordId),
      },
    );
  }
}

class _LobbyInvitePendingButtons extends ConsumerStatefulWidget {
  final String recordId;

  const _LobbyInvitePendingButtons({required this.recordId});

  @override
  ConsumerState<_LobbyInvitePendingButtons> createState() =>
      _LobbyInvitePendingButtonsState();
}

class _LobbyInvitePendingButtonsState
    extends ConsumerState<_LobbyInvitePendingButtons> {
  bool _loading = false;

  Future<void> _respond(bool accept) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(lobbyInviteResponseControllerProvider.notifier)
          .respond(widget.recordId, accept: accept);
    } catch (e, st) {
      Talker().handle(e, st, 'lobby invite response failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('errorGeneric'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        FButton(
          variant: .ghost,
          size: .xs,
          onPress: () => _respond(false),
          child: Text('lobby.inviteReview.reject'.tr()),
        ),
        FButton(
          variant: .secondary,
          size: .xs,
          onPress: () => _respond(true),
          child: Text('lobby.inviteReview.accept'.tr()),
        ),
      ],
    );
  }
}

/// Inline action for an `activity_at_risk_organizer` / `activity_at_risk_member`
/// notification — the deadline-passed "commit or cancel" prompt (see
/// schema/activity_threshold_enforcement.sql). Watches the activity's own
/// resolution state so the buttons disappear the moment it's resolved from
/// any surface (this card, or the same prompt landing on another device).
class _ActivityAtRiskActions extends ConsumerWidget {
  final String activityId;
  final bool isOrganizer;

  const _ActivityAtRiskActions({
    required this.activityId,
    required this.isOrganizer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(activityAtRiskStatusProvider(activityId));
    final colors = context.theme.colors;

    return statusAsync.when(
      loading: () => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) => switch (status) {
        ActivityAtRiskStatus.confirmed => Text(
          'lobbyHub.activity.atRiskResolvedConfirmed'.tr(),
          style: context.theme.typography.body.xs.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        ActivityAtRiskStatus.cancelled => Text(
          'lobbyHub.activity.atRiskResolvedCancelled'.tr(),
          style: context.theme.typography.body.xs.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        ActivityAtRiskStatus.pending => isOrganizer
            ? _ActivityAtRiskOrganizerButtons(activityId: activityId)
            : _ActivityAtRiskMemberButtons(activityId: activityId),
      },
    );
  }
}

/// Organizer-tier action: override-confirm (accept the low turnout) or
/// cancel outright — `resolve_at_risk_activity_organizer`.
class _ActivityAtRiskOrganizerButtons extends ConsumerStatefulWidget {
  final String activityId;

  const _ActivityAtRiskOrganizerButtons({required this.activityId});

  @override
  ConsumerState<_ActivityAtRiskOrganizerButtons> createState() =>
      _ActivityAtRiskOrganizerButtonsState();
}

class _ActivityAtRiskOrganizerButtonsState
    extends ConsumerState<_ActivityAtRiskOrganizerButtons> {
  bool _loading = false;

  Future<void> _respond(bool confirm) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(activityAtRiskResponseControllerProvider.notifier)
          .respondOrganizer(widget.activityId, confirm: confirm);
    } catch (e, st) {
      Talker().handle(e, st, 'activity at-risk organizer response failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('errorGeneric'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        FButton(
          variant: .ghost,
          size: .xs,
          onPress: () => _respond(false),
          child: Text('lobbyHub.activity.cancelAction'.tr()),
        ),
        FButton(
          variant: .secondary,
          size: .xs,
          onPress: () => _respond(true),
          child: Text('lobbyHub.activity.atRiskConfirmAnyway'.tr()),
        ),
      ],
    );
  }
}

/// Member-tier action for a "maybe"/never-responded lobby member: commit to
/// going or out — `resolve_at_risk_activity_rsvp`.
class _ActivityAtRiskMemberButtons extends ConsumerStatefulWidget {
  final String activityId;

  const _ActivityAtRiskMemberButtons({required this.activityId});

  @override
  ConsumerState<_ActivityAtRiskMemberButtons> createState() =>
      _ActivityAtRiskMemberButtonsState();
}

class _ActivityAtRiskMemberButtonsState
    extends ConsumerState<_ActivityAtRiskMemberButtons> {
  bool _loading = false;

  Future<void> _respond(bool going) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(activityAtRiskResponseControllerProvider.notifier)
          .respondMember(widget.activityId, going: going);
    } catch (e, st) {
      Talker().handle(e, st, 'activity at-risk member response failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('errorGeneric'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        FButton(
          variant: .ghost,
          size: .xs,
          onPress: () => _respond(false),
          child: Text('lobbyHub.activity.out'.tr()),
        ),
        FButton(
          variant: .secondary,
          size: .xs,
          onPress: () => _respond(true),
          child: Text('lobbyHub.activity.going'.tr()),
        ),
      ],
    );
  }
}
