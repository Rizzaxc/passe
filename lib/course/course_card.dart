import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../core/format.dart';
import 'model.dart';

/// The card's one-line preview of the thread's last message.
///
/// A system message's body is a stable code ('member_left',
/// 'enrollment_accepted', …), not prose — localised here the same way the
/// chat thread's own system rows are (`messaging.system.<code>`, named args
/// from the payload), never rendered raw. An unknown/unresolved code shows
/// nothing rather than leaking the code onto the card.
String? _previewText(CourseSummary course) {
  final body = course.lastMessageBody;
  if (body == null) return null;
  if (course.lastMessageKind != 'system') return body;

  final key = 'messaging.system.$body';
  final payload = course.lastMessagePayload;
  final args = payload?.map((k, v) => MapEntry(k, v.toString())) ?? const {};
  final text = key.tr(namedArgs: args);
  return text == key ? null : text;
}

/// One course (or coach inquiry) in the hub / inbox lists.
///
/// The same card serves both sides — a player sees the coach's name and their
/// own enrollment state, a coach sees the roster size and their to-do counts.
class CourseCard extends StatelessWidget {
  final CourseSummary course;
  final bool coachSide;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.coachSide = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    // An inquiry has no name yet; fall back to the counterpart so the row is
    // never blank.
    final title =
        course.name ??
        (coachSide
            ? 'course.newInquiry'.tr()
            : course.coachName ?? 'course.newInquiry'.tr());
    final preview = _previewText(course);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
                // Title and unread badge both vary in length; only the title
                // may shrink, so the badge never gets clipped away.
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.md.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (course.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  _Badge(label: '${course.unreadCount}'),
                ],
                if (course.status == CourseStatus.ended) ...[
                  const SizedBox(width: 8),
                  Text(
                    'course.ended'.tr(),
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
            if (!coachSide && course.coachName != null) ...[
              const SizedBox(height: 2),
              Text(
                course.coachName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
            if (preview != null) ...[
              const SizedBox(height: 8),
              Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
            if (course.progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: course.progress,
                  minHeight: 5,
                  backgroundColor: colors.border,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'course.sessionProgress'.tr(
                  namedArgs: {
                    'held': '${course.heldSessionCount}',
                    'target': '${course.targetSessionCount}',
                  },
                ),
                style: typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
            if (course.nextStartTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    FLucideIcons.calendarDays,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      formatMatchDateTime(course.nextStartTime!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_chips.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: _chips),
            ],
          ],
        ),
      ),
    );
  }

  /// The actionable state of the card: what the viewer still owes.
  List<Widget> get _chips => [
    if (course.pendingOfferId != null)
      _Badge(label: 'course.offerPending'.tr(), highlight: true),
    if (course.pendingRsvpCount > 0)
      _Badge(
        label: 'course.rsvpPending'.plural(course.pendingRsvpCount),
        highlight: true,
      ),
    if (course.pendingProposalCount > 0)
      _Badge(
        label: 'course.proposalsPending'.plural(course.pendingProposalCount),
        highlight: true,
      ),
    if (course.pendingReportCount > 0)
      _Badge(label: 'course.reportsPending'.plural(course.pendingReportCount)),
    if (coachSide && course.studentCount > 0)
      _Badge(label: 'course.studentCount'.plural(course.studentCount)),
    if (coachSide && course.inquiringCount > 0)
      _Badge(label: 'course.inquiringCount'.plural(course.inquiringCount)),
  ];
}

class _Badge extends StatelessWidget {
  final String label;
  final bool highlight;

  const _Badge({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? colors.primary : colors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.theme.typography.body.xs.copyWith(
          color: highlight ? colors.primaryForeground : colors.mutedForeground,
        ),
      ),
    );
  }
}
