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
    final canPropose = course.status == CourseStatus.active;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatMatchDateTime(session.startTime),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (course.isCoach)
                FButton.icon(
                  variant: .ghost,
                  onPress: busy
                      ? null
                      : () => showSessionActionsSheet(context, course, session),
                  child: const Icon(FLucideIcons.ellipsis),
                ),
            ],
          ),
          if (session.venueName != null) ...[
            const SizedBox(height: 4),
            Text(
              session.venueName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          ],
          if (session.note != null) ...[
            const SizedBox(height: 6),
            Text(session.note!, style: context.theme.typography.body.sm),
          ],
          const SizedBox(height: 12),
          // No quorum on a course session: RSVP is attendance intent, and
          // nothing is gated on the count.
          Row(
            children: [
              for (final option in const ['going', 'maybe', 'out'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FButton(
                    variant: session.myAttendance == option
                        ? .primary
                        : .outline,
                    size: .sm,
                    onPress: busy
                        ? null
                        : () => controller.rsvp(
                            session.activityId,
                            option,
                            courseId: course.courseId,
                          ),
                    child: Text('course.rsvp.$option'.tr()),
                  ),
                ),
              const Spacer(),
              Text(
                'course.goingCount'.plural(session.goingCount),
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ],
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
