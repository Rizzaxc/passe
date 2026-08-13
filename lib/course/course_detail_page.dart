import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_controller.dart';
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
      // All 3 tabs are visible to anyone with course access, inquiring
      // students included — an inquiring student can already see scheduled
      // sessions via the feed's system messages, so hiding Planner/History
      // outright bought no real privacy, just an inconsistent, confusing
      // surface. Actions (propose, RSVP, write a report/review) stay gated
      // on `canManage` inside each tab instead.
      child: async.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (_, _) => Center(child: Text('course.loadFailed'.tr())),
        data: (course) => FTabs(
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
    final hasInquirer = course.members.any(
      (m) => m.status == CourseMemberStatus.inquiring,
    );

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
                    // Right above the composer, not buried in the info
                    // sheet — the coach is already looking at this exact
                    // student's messages when the decision to enroll them
                    // comes up.
                    composerAccessory:
                        course.isCoach &&
                            course.status == CourseStatus.active &&
                            hasInquirer
                        ? _EnrollInquirerChip(course: course)
                        : null,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Opens the enrollment-offer sheet scoped to just the inquiring member(s)
/// already in this thread — no search, since the whole point is "this
/// person is right here, enroll them" (search stays behind the info
/// sheet's own "Send enrollment offer" for the rarer cold-invite case).
class _EnrollInquirerChip extends StatelessWidget {
  final CourseDetail course;

  const _EnrollInquirerChip({required this.course});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () =>
            showEnrollmentOfferSheet(context, course, allowSearch: false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FLucideIcons.userPlus,
                size: 14,
                color: colors.primaryForeground,
              ),
              const SizedBox(width: 6),
              Text(
                'course.enrollChip'.tr(),
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.primaryForeground,
                ),
              ),
            ],
          ),
        ),
      ),
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
    // withdraw_course_proposal is proposer-only server-side; only show the
    // button to the one viewer it would actually work for. Everyone else
    // (including another inquiring/enrolled student who isn't the proposer)
    // just reads the row.
    final isMine = session.proposedBy == ref.watch(currentUserIdProvider);

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
          : isMine
          ? FButton(
              variant: .outline,
              size: .sm,
              onPress: busy
                  ? null
                  : () => controller.withdrawProposal(
                      session.activityId,
                      courseId: course.courseId,
                    ),
              child: Text('course.withdraw'.tr()),
            )
          : null,
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

/// Mirrors the lobby hub's Planner tab shape: a section header with an
/// always-reachable "+" rather than a full-width button buried in the list,
/// and a card-style empty state instead of a bare placeholder line. Unlike
/// the lobby version there's no "member has no button" branch to handle —
/// this tab only mounts for `course.canManage` (coach or enrolled student,
/// see course_detail_page.dart's tab gating), and both of those may propose
/// a session, so the CTA is unconditional here.
class _PlannerTab extends ConsumerWidget {
  final CourseDetail course;

  const _PlannerTab({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = course.upcoming;
    // Both tabs now show to every viewer with course access, including an
    // inquiring student — but only the coach and an enrolled student may
    // actually schedule/propose.
    final canPropose = course.status == CourseStatus.active && course.canManage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: PSectionHeader(
            title: 'course.tab.planner'.tr(),
            suffix: canPropose
                ? FButton.icon(
                    variant: .ghost,
                    onPress: () => showProposeSessionSheet(context, course),
                    child: const Icon(FLucideIcons.plus),
                  )
                : null,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.refresh(courseDetailProvider(course.courseId).future),
            child: upcoming.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      _PlannerEmptyState(
                        course: course,
                        canPropose: canPropose,
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: upcoming.length,
                    itemBuilder: (context, i) =>
                        _SessionCard(course: course, session: upcoming[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PlannerEmptyState extends StatelessWidget {
  final CourseDetail course;
  final bool canPropose;

  const _PlannerEmptyState({required this.course, required this.canPropose});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FLucideIcons.calendarDays,
                  size: 22,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'course.noUpcoming'.tr(),
              textAlign: TextAlign.center,
              style: context.theme.typography.body.md.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (canPropose) ...[
              const SizedBox(height: 12),
              FButton(
                size: .sm,
                onPress: () => showProposeSessionSheet(context, course),
                child: Text(
                  course.isCoach
                      ? 'course.scheduleSession'.tr()
                      : 'course.proposeSession'.tr(),
                ),
              ),
            ],
          ],
        ),
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
              course.canManage &&
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
