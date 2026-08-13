import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/format.dart';
import '../ui/main.dart';
import 'course_controller.dart';
import 'model.dart';

/// Yes/no confirmation, in the shape the rest of the app uses
/// (`showFDialog` + `PConfirmDialog`).
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showFDialog<bool>(
    context: context,
    builder: (dialogCtx, style, animation) => PConfirmDialog(
      animation: animation,
      title: Text(title),
      body: Text(body),
      actions: [
        FButton(
          variant: .outline,
          onPress: () => Navigator.of(dialogCtx).pop(false),
          child: Text('course.cancel'.tr()),
        ),
        FButton(
          variant: destructive ? .destructive : .primary,
          onPress: () => Navigator.of(dialogCtx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Warn — never block — when a coach's new session overlaps one they already
/// have. Returns whether to proceed.
///
/// Same posture as the old booking sheet's conflict check: a coach may
/// legitimately double-book (a shared court, a session they know will run
/// short), and blocking would push them off-app to fix it. The dialog says
/// only that there's an overlap, never whose — a student proposing a slot
/// must not learn who else their coach teaches.
Future<bool> confirmCourseClash(
  BuildContext context, {
  required WidgetRef ref,
  required String professionalId,
  required DateTime start,
  required DateTime end,
}) async {
  final clashes = await ref.read(
    hasCourseConflictProvider(professionalId, start, end).future,
  );
  if (!clashes || !context.mounted) return true;

  return _confirm(
    context,
    title: 'course.clashTitle'.tr(),
    body: 'course.clashBody'.tr(),
    confirmLabel: 'course.clashProceed'.tr(),
  );
}

Future<void> showCourseInfoSheet(BuildContext context, CourseDetail course) =>
    showPSheet(
      context: context,
      maxHeightRatio: 1,
      builder: (_) => _CourseInfoSheet(course: course),
    );

class _CourseInfoSheet extends ConsumerWidget {
  final CourseDetail course;

  const _CourseInfoSheet({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(courseActionControllerProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(label: course.name ?? 'course.title'.tr()),
          if (course.description != null) ...[
            Text(course.description!, style: context.theme.typography.body.sm),
            const SizedBox(height: 16),
          ],
          if (course.targetSessionCount != null) ...[
            Text(
              'course.sessionProgress'.tr(
                namedArgs: {
                  'held': '${course.heldSessionCount}',
                  'target': '${course.targetSessionCount}',
                },
              ),
              style: context.theme.typography.body.sm,
            ),
            const SizedBox(height: 16),
          ],
          PSectionHeader(title: 'course.members'.tr()),
          for (final member in course.members)
            FTile(
              prefix: PUserAvatar(
                userId: member.userId,
                username: member.username,
                generatedAvatar: member.generatedAvatar,
                radius: 16,
              ),
              title: Text(
                member.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('course.status.${member.status.name}'.tr()),
              suffix: course.isCoach
                  ? FButton.icon(
                      variant: .ghost,
                      onPress: () async {
                        final confirmed = await _confirm(
                          context,
                          title: 'course.removeMemberTitle'.tr(),
                          body: 'course.removeMemberBody'.tr(),
                          confirmLabel: 'course.remove'.tr(),
                          destructive: true,
                        );
                        if (!confirmed) return;
                        await controller.removeMember(
                          course.courseId,
                          member.userId,
                        );
                      },
                      child: const Icon(FLucideIcons.userMinus),
                    )
                  : null,
            ),
          const SizedBox(height: 20),
          if (course.isCoach && course.status == CourseStatus.active) ...[
            FButton(
              onPress: () => showEnrollmentOfferSheet(context, course),
              child: Text('course.sendOffer'.tr()),
            ),
            const SizedBox(height: 8),
            // Only the coach can end a course; reaching the session target
            // prompts but never closes it.
            FButton(
              variant: .destructive,
              onPress: () async {
                final confirmed = await _confirm(
                  context,
                  title: 'course.endTitle'.tr(),
                  body: 'course.endBody'.tr(),
                  confirmLabel: 'course.end'.tr(),
                  destructive: true,
                );
                if (!confirmed) return;
                await controller.endCourse(course.courseId);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('course.end'.tr()),
            ),
          ],
          if (!course.isCoach)
            FButton(
              variant: .destructive,
              onPress: () async {
                final confirmed = await _confirm(
                  context,
                  title: 'course.leaveTitle'.tr(),
                  body: 'course.leaveBody'.tr(),
                  confirmLabel: 'course.leave'.tr(),
                  destructive: true,
                );
                if (!confirmed) return;
                await controller.leave(course.courseId);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('course.leave'.tr()),
            ),
        ],
      ),
    );
  }
}

Future<void> showEnrollmentOfferSheet(
  BuildContext context,
  CourseDetail course,
) => showPSheet(
  context: context,
  builder: (_) => _EnrollmentOfferSheet(course: course),
);

/// The coach's offer: a name, an optional description, an optional target
/// session count. Accepting it is what turns an inquiry into an enrollment.
class _EnrollmentOfferSheet extends ConsumerStatefulWidget {
  final CourseDetail course;

  const _EnrollmentOfferSheet({required this.course});

  @override
  ConsumerState<_EnrollmentOfferSheet> createState() =>
      _EnrollmentOfferSheetState();
}

class _EnrollmentOfferSheetState extends ConsumerState<_EnrollmentOfferSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _target = TextEditingController();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _name.text = widget.course.name ?? '';
    _target.text = widget.course.targetSessionCount?.toString() ?? '';
    // Default to whoever is still only inquiring — the common case is
    // promoting the person who just messaged.
    _userId = widget.course.members
        .where((m) => m.status == CourseMemberStatus.inquiring)
        .map((m) => m.userId)
        .firstOrNull;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.course.members
        .where((m) => m.status == CourseMemberStatus.inquiring)
        .toList();
    final busy = ref.watch(courseActionControllerProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(label: 'course.sendOffer'.tr()),
          if (candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('course.noCandidates'.tr()),
            )
          else
            for (final member in candidates)
              FTile(
                title: Text(
                  member.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                suffix: _userId == member.userId
                    ? const Icon(FLucideIcons.check)
                    : null,
                onPress: () => setState(() => _userId = member.userId),
              ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _name),
            label: Text('course.offerName'.tr()),
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _description),
            label: Text('course.offerDescription'.tr()),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _target),
            label: Text('course.offerTarget'.tr()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          FButton(
            onPress: busy || _userId == null || _name.text.trim().isEmpty
                ? null
                : () async {
                    try {
                      await ref
                          .read(courseActionControllerProvider.notifier)
                          .sendEnrollmentOffer(
                            courseId: widget.course.courseId,
                            userId: _userId!,
                            name: _name.text,
                            description: _description.text.trim().isEmpty
                                ? null
                                : _description.text,
                            targetSessionCount: int.tryParse(
                              _target.text.trim(),
                            ),
                          );
                      if (context.mounted) Navigator.pop(context);
                    } catch (_) {
                      if (context.mounted) {
                        showFToast(
                          context: context,
                          variant: .destructive,
                          title: Text('course.actionFailed'.tr()),
                        );
                      }
                    }
                  },
            child: Text('course.sendOffer'.tr()),
          ),
        ],
      ),
    );
  }
}

Future<void> showProposeSessionSheet(
  BuildContext context,
  CourseDetail course,
) => showPSheet(
  context: context,
  builder: (_) => _ProposeSessionSheet(course: course),
);

class _ProposeSessionSheet extends ConsumerStatefulWidget {
  final CourseDetail course;

  const _ProposeSessionSheet({required this.course});

  @override
  ConsumerState<_ProposeSessionSheet> createState() =>
      _ProposeSessionSheetState();
}

class _ProposeSessionSheetState extends ConsumerState<_ProposeSessionSheet> {
  final _note = TextEditingController();
  DateTime? _start;
  Duration _duration = const Duration(hours: 1);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _start = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(courseActionControllerProvider);
    final isCoach = widget.course.isCoach;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: isCoach
                ? 'course.scheduleSession'.tr()
                : 'course.proposeSession'.tr(),
          ),
          FTile(
            title: Text('course.startTime'.tr()),
            subtitle: Text(
              _start == null
                  ? 'course.pickTime'.tr()
                  : formatMatchDateTime(_start!),
            ),
            onPress: _pick,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final hours in const [1, 2, 3])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FButton(
                    variant: _duration.inHours == hours ? .primary : .outline,
                    size: .sm,
                    onPress: () => setState(
                      () => _duration = Duration(hours: hours),
                    ),
                    child: Text('course.hours'.plural(hours)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _note),
            label: Text('course.note'.tr()),
            maxLines: 2,
          ),
          if (!isCoach) ...[
            const SizedBox(height: 12),
            Text(
              'course.proposalNeedsApproval'.tr(),
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FButton(
            onPress: busy || _start == null ? null : _submit,
            child: Text('course.submit'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final start = _start!;
    final end = start.add(_duration);

    // A coach scheduling directly commits to the time immediately, so warn
    // about their own overlaps here too.
    if (widget.course.isCoach) {
      final proceed = await confirmCourseClash(
        context,
        ref: ref,
        professionalId: widget.course.professionalId,
        start: start,
        end: end,
      );
      if (!proceed) return;
    }

    try {
      await ref
          .read(courseActionControllerProvider.notifier)
          .proposeSession(
            courseId: widget.course.courseId,
            start: start,
            end: end,
            note: _note.text.trim().isEmpty ? null : _note.text,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('course.actionFailed'.tr()),
        );
      }
    }
  }
}

Future<void> showSessionActionsSheet(
  BuildContext context,
  CourseDetail course,
  CourseSession session,
) => showPSheet(
  context: context,
  builder: (_) => Consumer(
    builder: (context, ref, _) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PSheetTitle(label: formatMatchDateTime(session.startTime)),
        // Rescheduling clears every RSVP server-side, so say so before they do it.
        Text(
          'course.rescheduleWarning'.tr(),
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),
        FButton(
          variant: .destructive,
          onPress: () async {
            await ref
                .read(courseActionControllerProvider.notifier)
                .cancelSession(session.activityId, courseId: course.courseId);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text('course.cancelSession'.tr()),
        ),
      ],
    ),
  ),
);

Future<void> showSessionReportSheet(
  BuildContext context,
  CourseDetail course,
  CourseSession session,
) => showPSheet(
  context: context,
  builder: (_) => _SessionReportSheet(course: course, session: session),
);

/// One report per student per session, written by the coach, readable only by
/// that student. **Final on submit** — no edit, no delete — so the sheet says
/// so before the button.
class _SessionReportSheet extends ConsumerStatefulWidget {
  final CourseDetail course;
  final CourseSession session;

  const _SessionReportSheet({required this.course, required this.session});

  @override
  ConsumerState<_SessionReportSheet> createState() =>
      _SessionReportSheetState();
}

class _SessionReportSheetState extends ConsumerState<_SessionReportSheet> {
  final _body = TextEditingController();
  String? _studentId;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only students who RSVP'd going can be written up; the server enforces
    // it too, but showing an ineligible name would just produce an error.
    final written = widget.course.reports
        .where((r) => r.activityId == widget.session.activityId)
        .map((r) => r.studentId)
        .toSet();
    final candidates = widget.course.members
        .where((m) => m.status.isEnrolled && !written.contains(m.userId))
        .toList();
    final busy = ref.watch(courseActionControllerProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(label: 'course.writeReport'.tr()),
          for (final member in candidates)
            FTile(
              title: Text(
                member.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              suffix: _studentId == member.userId
                  ? const Icon(FLucideIcons.check)
                  : null,
              onPress: () => setState(() => _studentId = member.userId),
            ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _body),
            label: Text('course.reportBody'.tr()),
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          Text(
            'course.reportFinal'.tr(),
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          FButton(
            onPress: busy || _studentId == null || _body.text.trim().isEmpty
                ? null
                : () async {
                    try {
                      await ref
                          .read(courseActionControllerProvider.notifier)
                          .submitReport(
                            activityId: widget.session.activityId,
                            studentId: _studentId!,
                            body: _body.text,
                            courseId: widget.course.courseId,
                          );
                      if (context.mounted) Navigator.pop(context);
                    } catch (_) {
                      if (context.mounted) {
                        showFToast(
                          context: context,
                          variant: .destructive,
                          title: Text('course.actionFailed'.tr()),
                        );
                      }
                    }
                  },
            child: Text('course.submit'.tr()),
          ),
        ],
      ),
    );
  }
}

Future<void> showCourseReviewSheet(
  BuildContext context,
  CourseDetail course,
) => showPSheet(
  context: context,
  builder: (_) => _CourseReviewSheet(course: course),
);

class _CourseReviewSheet extends ConsumerStatefulWidget {
  final CourseDetail course;

  const _CourseReviewSheet({required this.course});

  @override
  ConsumerState<_CourseReviewSheet> createState() => _CourseReviewSheetState();
}

class _CourseReviewSheetState extends ConsumerState<_CourseReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(courseActionControllerProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(label: 'course.writeReview'.tr()),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating
                        ? FLucideIcons.star
                        : FLucideIcons.starOff,
                    color: context.theme.colors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _comment),
            label: Text('course.reviewComment'.tr()),
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          Text(
            'course.reviewFinal'.tr(),
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          FButton(
            onPress: busy
                ? null
                : () async {
                    try {
                      await ref
                          .read(courseActionControllerProvider.notifier)
                          .submitReview(
                            courseId: widget.course.courseId,
                            rating: _rating,
                            comment: _comment.text.trim().isEmpty
                                ? null
                                : _comment.text,
                          );
                      if (context.mounted) Navigator.pop(context);
                    } catch (_) {
                      if (context.mounted) {
                        showFToast(
                          context: context,
                          variant: .destructive,
                          title: Text('course.actionFailed'.tr()),
                        );
                      }
                    }
                  },
            child: Text('course.submit'.tr()),
          ),
        ],
      ),
    );
  }
}
