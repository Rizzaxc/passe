import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/format.dart';
import '../messaging/conversation_view.dart';
import '../ui/main.dart';
import 'course_controller.dart';
import 'course_sheets.dart';
import 'model.dart';

/// One course: **Feed** (the shared thread + pending proposals), **Planner**
/// (approved upcoming sessions + RSVP) and **History** (finished sessions and
/// the viewer's own private reports).
///
/// Mirrors the lobby detail page's three-tab shape deliberately — the two
/// screens do the same job for different groups.
class CourseDetailPage extends ConsumerStatefulWidget {
  final String id;

  const CourseDetailPage({super.key, required this.id});

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(courseDetailProvider(widget.id));

    return FScaffold(
      header: FHeader.nested(
        title: Text(
          async.value?.name ?? 'course.title'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        prefixes: [FHeaderAction.back(onPress: () => context.pop())],
        suffixes: [
          if (async.value != null)
            FHeaderAction(
              icon: const Icon(FLucideIcons.info),
              onPress: () => showCourseInfoSheet(context, async.value!),
            ),
        ],
      ),
      // An inquiring (unenrolled) student has nothing to plan or attend yet —
      // the coach hasn't accepted them — so Planner/History would be two
      // permanently-empty tabs. Feed (the thread) is the whole inquiry.
      child: async.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (_, _) => Center(child: Text('course.loadFailed'.tr())),
        data: (course) => !course.canManage
            ? _FeedTab(course: course)
            : FTabs(
                expands: true,
                contentPhysics: const NeverScrollableScrollPhysics(),
                control: FTabControl.lifted(
                  index: _tab,
                  onChange: (i) => setState(() => _tab = i),
                ),
                children: [
                  FTabEntry(
                    label: Text('course.tab.feed'.tr()),
                    child: _FeedTab(course: course),
                  ),
                  FTabEntry(
                    label: Text('course.tab.planner'.tr()),
                    child: _PlannerTab(course: course),
                  ),
                  FTabEntry(
                    label: Text('course.tab.history'.tr()),
                    child: _HistoryTab(course: course),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The thread, plus the coach's approve/reject queue above it — a pending
/// proposal is a thing to act on, not just a message to read.
class _FeedTab extends ConsumerWidget {
  final CourseDetail course;

  const _FeedTab({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = course.conversationId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (course.pendingProposals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PSectionHeader(title: 'course.pendingProposals'.tr()),
                for (final session in course.pendingProposals)
                  _ProposalRow(course: course, session: session),
              ],
            ),
          ),
        Expanded(
          child: conversationId == null
              ? Center(child: Text('course.noThread'.tr()))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ConversationView(
                    conversationId: conversationId,
                    // A course is a group thread even when it currently has
                    // one student — the coach may add more at any time.
                    showSenderNames: true,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProposalRow extends ConsumerWidget {
  final CourseDetail course;
  final CourseSession session;

  const _ProposalRow({required this.course, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(courseActionControllerProvider.notifier);
    final busy = ref.watch(courseActionControllerProvider);

    return FTile(
      title: Text(
        formatMatchDateTime(session.startTime),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: session.note == null
          ? null
          : Text(session.note!, maxLines: 2, overflow: TextOverflow.ellipsis),
      suffix: course.isCoach
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FButton.icon(
                  variant: .ghost,
                  onPress: busy
                      ? null
                      : () => _approve(context, ref, controller, true),
                  child: const Icon(FLucideIcons.check),
                ),
                FButton.icon(
                  variant: .ghost,
                  onPress: busy
                      ? null
                      : () => _approve(context, ref, controller, false),
                  child: const Icon(FLucideIcons.x),
                ),
              ],
            )
          : FButton(
              variant: .outline,
              size: .sm,
              onPress: busy
                  ? null
                  : () => controller.withdrawProposal(
                      session.activityId,
                      courseId: course.courseId,
                    ),
              child: Text('course.withdraw'.tr()),
            ),
    );
  }

  /// Approving is the moment the coach commits to the time, so the clash
  /// check runs here as well as when they schedule directly. It warns and
  /// lets them continue — a coach may legitimately double-book.
  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    CourseActionController controller,
    bool approve,
  ) async {
    if (approve) {
      final proceed = await confirmCourseClash(
        context,
        ref: ref,
        professionalId: course.professionalId,
        start: session.startTime,
        end: session.endTime ?? session.startTime,
      );
      if (!proceed) return;
    }
    await controller.respondToProposal(
      session.activityId,
      approve,
      courseId: course.courseId,
    );
  }
}

class _PlannerTab extends ConsumerWidget {
  final CourseDetail course;

  const _PlannerTab({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = course.upcoming;
    final canPropose = course.status == CourseStatus.active && course.canManage;

    return RefreshIndicator(
      onRefresh: () =>
          ref.refresh(courseDetailProvider(course.courseId).future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (canPropose)
            FButton(
              onPress: () => showProposeSessionSheet(context, course),
              child: Text(
                course.isCoach
                    ? 'course.scheduleSession'.tr()
                    : 'course.proposeSession'.tr(),
              ),
            ),
          const SizedBox(height: 16),
          if (upcoming.isEmpty)
            PEmptySectionPlaceholder(subtitle: 'course.noUpcoming'.tr())
          else
            for (final session in upcoming)
              _SessionCard(course: course, session: session),
        ],
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final CourseDetail course;
  final CourseSession session;

  const _SessionCard({required this.course, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final controller = ref.watch(courseActionControllerProvider.notifier);
    final busy = ref.watch(courseActionControllerProvider);
    final start = session.startTime.toLocal();
    final end = session.endTime?.toLocal();
    final weekdays = [
      'lobbyHub.schedule.weekdaysShort.monday'.tr(),
      'lobbyHub.schedule.weekdaysShort.tuesday'.tr(),
      'lobbyHub.schedule.weekdaysShort.wednesday'.tr(),
      'lobbyHub.schedule.weekdaysShort.thursday'.tr(),
      'lobbyHub.schedule.weekdaysShort.friday'.tr(),
      'lobbyHub.schedule.weekdaysShort.saturday'.tr(),
      'lobbyHub.schedule.weekdaysShort.sunday'.tr(),
    ];
    final dateLabel =
        '${weekdays[start.weekday - 1]}, '
        '${start.day}/${start.month}';
    final startLabel = formatTimeOfDay(start);
    final timeLabel = end == null
        ? startLabel
        : '$startLabel – ${formatTimeOfDay(end)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 3, child: ColoredBox(color: _courseCrimson)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.xl3.copyWith(
                    color: const Color(0xFF09090B),
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.md.copyWith(
                    color: _courseCrimson,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (session.venueName != null) ...[
                  const SizedBox(height: 10),
                  _CourseSessionDetailRow(
                    icon: FLucideIcons.mapPin,
                    text: session.venueName!,
                  ),
                ],
                if (session.note != null) ...[
                  const SizedBox(height: 8),
                  _CourseSessionDetailRow(
                    icon: FLucideIcons.stickyNote,
                    text: session.note!,
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      FLucideIcons.circleCheck,
                      size: 14,
                      color: session.goingCount > 0
                          ? _courseGreen
                          : colors.mutedForeground,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'course.goingCount'.plural(session.goingCount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.typography.body.sm.copyWith(
                          color: session.goingCount > 0
                              ? _courseGreen
                              : colors.secondaryForeground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (course.canManage) ...[
                  const SizedBox(height: 10),
                  _CourseRsvpControl(
                    value: session.myAttendance ?? '',
                    enabled: !busy,
                    onChange: (option) => controller.rsvp(
                      session.activityId,
                      option,
                      courseId: course.courseId,
                    ),
                  ),
                ],
                if (course.isCoach) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      label: 'course.cancelSession'.tr(),
                      child: FButton.icon(
                        variant: .outline,
                        size: .sm,
                        onPress: busy
                            ? null
                            : () => showSessionActionsSheet(
                                context,
                                course,
                                session,
                              ),
                        child: const Icon(FLucideIcons.ellipsis, size: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _courseCrimson = Color(0xFFDC143C);
const _courseGreen = Color(0xFF959D54);
const _courseGreenTint = Color(0xFFEEF2E4);

class _CourseSessionDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _CourseSessionDetailRow({
    required this.icon,
    required this.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(
          icon,
          size: 14,
          color: context.theme.colors.mutedForeground,
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.secondaryForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

class _CourseRsvpControl extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onChange;

  const _CourseRsvpControl({
    required this.value,
    required this.enabled,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          _CourseRsvpButton(
            id: 'going',
            label: 'course.rsvp.going'.tr(),
            icon: FLucideIcons.check,
            active: value == 'going',
            positive: true,
            enabled: enabled,
            onTap: onChange,
          ),
          _CourseRsvpButton(
            id: 'maybe',
            label: 'course.rsvp.maybe'.tr(),
            icon: FLucideIcons.circleHelp,
            active: value == 'maybe',
            enabled: enabled,
            onTap: onChange,
          ),
          _CourseRsvpButton(
            id: 'out',
            label: 'course.rsvp.out'.tr(),
            icon: FLucideIcons.x,
            active: value == 'out',
            enabled: enabled,
            onTap: onChange,
          ),
        ],
      ),
    );
  }
}

class _CourseRsvpButton extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool active;
  final bool positive;
  final bool enabled;
  final ValueChanged<String> onTap;

  const _CourseRsvpButton({
    required this.id,
    required this.label,
    required this.icon,
    required this.active,
    required this.enabled,
    required this.onTap,
    this.positive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final activeForeground = positive
        ? _courseGreen
        : colors.secondaryForeground;
    final activeBackground = positive ? _courseGreenTint : colors.secondary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        enabled: enabled,
        label: label,
        child: FTappable(
          onPress: enabled ? () => onTap(id) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: active ? activeBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: active ? activeForeground : colors.mutedForeground,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.sm.copyWith(
                      color: active
                          ? activeForeground
                          : colors.secondaryForeground,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Finished sessions, and the private reports the viewer is entitled to.
/// A student sees only their own; the coach sees all of them and can write
/// the ones still missing.
class _HistoryTab extends ConsumerWidget {
  final CourseDetail course;

  const _HistoryTab({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final past = course.past;

    return RefreshIndicator(
      onRefresh: () =>
          ref.refresh(courseDetailProvider(course.courseId).future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (course.status == CourseStatus.ended &&
              !course.isCoach &&
              course.myReviewRating == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FButton(
                onPress: () => showCourseReviewSheet(context, course),
                child: Text('course.writeReview'.tr()),
              ),
            ),
          if (past.isEmpty)
            PEmptySectionPlaceholder(subtitle: 'course.noHistory'.tr())
          else
            for (final session in past)
              _PastSessionTile(course: course, session: session),
        ],
      ),
    );
  }
}

class _PastSessionTile extends StatelessWidget {
  final CourseDetail course;
  final CourseSession session;

  const _PastSessionTile({required this.course, required this.session});

  @override
  Widget build(BuildContext context) {
    final reports = course.reports
        .where((r) => r.activityId == session.activityId)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FTile(
            title: Text(
              formatMatchDateTime(session.startTime),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: session.venueName == null
                ? null
                : Text(
                    session.venueName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            suffix: course.isCoach
                ? FButton(
                    variant: .outline,
                    size: .sm,
                    onPress: () =>
                        showSessionReportSheet(context, course, session),
                    child: Text('course.writeReport'.tr()),
                  )
                : null,
          ),
          for (final report in reports)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.theme.colors.muted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  report.body,
                  style: context.theme.typography.body.sm,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
