import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../core/format.dart';
import '../ui/main.dart';
import 'model.dart';

/// The card's one-line preview of the thread's last message.
String? _previewText(CourseSummary course) {
  final body = course.lastMessageBody;
  if (body == null) return null;
  if (course.lastMessageKind != 'system') return body;

  final key = 'messaging.system.$body';
  final payload = course.lastMessagePayload;
  final args =
      payload?.map((key, value) => MapEntry(key, value.toString())) ?? const {};
  final text = key.tr(namedArgs: args);
  return text == key ? null : text;
}

/// A Course hub entity card using the same visual structure as
/// [ManageLobbyCard]: identity, compact metadata, next-event board, and a
/// clear primary action. Course-specific progress and inbox state stay inside
/// that structure instead of creating a separate dashboard language.
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

  String get _title =>
      course.name ??
      (coachSide
          ? 'course.newInquiry'.tr()
          : course.coachName ?? 'course.newInquiry'.tr());

  Color _frameColor() {
    if (course.status == CourseStatus.ended) return pbGreen;
    if (course.hasAction) return pbCoral;
    if (course.memberStatus == CourseMemberStatus.inquiring) return pbAmber;
    return pbBlueDeep;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final radius = BorderRadius.circular(16);
    final preview = _previewText(course);

    return POffsetFrame(
      offsetColor: _frameColor(),
      borderRadius: radius,
      child: FTappable(
        onPress: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: pbInk.withValues(alpha: 0.16)),
            borderRadius: radius,
            boxShadow: context.theme.style.shadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CourseAvatar(
                      name: _title,
                      ended: course.status == CourseStatus.ended,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          _CourseRoleBadge(
                            coachSide: coachSide,
                            status: course.status,
                            memberStatus: course.memberStatus,
                          ),
                          Text(
                            _title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.typography.body.lg.copyWith(
                              color: pbInk,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (!coachSide && course.coachName != null)
                      _MetaPill(
                        icon: FLucideIcons.graduationCap,
                        label: course.coachName!,
                      ),
                    if (coachSide && course.studentCount > 0)
                      _MetaPill(
                        icon: FLucideIcons.users,
                        label: 'course.studentCount'.plural(
                          course.studentCount,
                        ),
                      ),
                    if (coachSide && course.inquiringCount > 0)
                      _MetaPill(
                        icon: FLucideIcons.userRoundSearch,
                        label: 'course.inquiringCount'.plural(
                          course.inquiringCount,
                        ),
                      ),
                    if (course.unreadCount > 0)
                      _MetaPill(
                        icon: FLucideIcons.messageCircle,
                        label: '${course.unreadCount}',
                        highlighted: true,
                      ),
                  ],
                ),
                if (preview != null) _MessagePreview(text: preview),
                if (course.progress != null) _CourseProgress(course: course),
                _NextSessionBoard(start: course.nextStartTime),
                if (_actionBadges.isNotEmpty)
                  Wrap(spacing: 6, runSpacing: 6, children: _actionBadges),
                FButton(
                  size: .sm,
                  style: FButtonStyleExtension.accentBlueStyle(
                    context.theme.buttonStyles.primary.base,
                  ),
                  onPress: onTap,
                  prefix: const Icon(FLucideIcons.arrowRight, size: 16),
                  child: Text('course.viewCourse'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> get _actionBadges => [
    if (course.pendingOfferId != null)
      _ActionBadge(label: 'course.offerPending'.tr()),
    if (course.pendingRsvpCount > 0)
      _ActionBadge(label: 'course.rsvpPending'.plural(course.pendingRsvpCount)),
    if (course.pendingProposalCount > 0)
      _ActionBadge(
        label: 'course.proposalsPending'.plural(course.pendingProposalCount),
      ),
    if (course.pendingReportCount > 0)
      _ActionBadge(
        label: 'course.reportsPending'.plural(course.pendingReportCount),
        secondary: true,
      ),
  ];
}

class _CourseAvatar extends StatelessWidget {
  final String name;
  final bool ended;

  const _CourseAvatar({required this.name, required this.ended});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: ended ? context.theme.colors.muted : pbAmber,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: context.theme.typography.body.lg.copyWith(
          color: ended ? context.theme.colors.mutedForeground : pbInk,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _CourseRoleBadge extends StatelessWidget {
  final bool coachSide;
  final CourseStatus status;
  final CourseMemberStatus? memberStatus;

  const _CourseRoleBadge({
    required this.coachSide,
    required this.status,
    required this.memberStatus,
  });

  @override
  Widget build(BuildContext context) {
    final ended = status == CourseStatus.ended;
    final label = ended
        ? 'course.ended'.tr()
        : coachSide
        ? 'course.coachCourse'.tr()
        : memberStatus == CourseMemberStatus.inquiring
        ? 'course.status.inquiring'.tr()
        : 'course.status.enrolled'.tr();
    final color = ended ? context.theme.colors.muted : pbAmber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: ended ? 1 : 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(
            ended ? FLucideIcons.archive : FLucideIcons.graduationCap,
            size: 10,
            color: ended ? context.theme.colors.mutedForeground : pbInk,
          ),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.xs.copyWith(
                color: ended ? context.theme.colors.mutedForeground : pbInk,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted
            ? pbCoral.withValues(alpha: 0.2)
            : pbInk.withValues(alpha: 0.055),
        border: Border.all(
          color: highlighted
              ? pbCoral.withValues(alpha: 0.5)
              : pbInk.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(icon, size: 11, color: pbBlueDeep),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.xs.copyWith(
                color: pbInk,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  final String text;

  const _MessagePreview({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          FLucideIcons.messageCircle,
          size: 13,
          color: context.theme.colors.mutedForeground,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CourseProgress extends StatelessWidget {
  final CourseSummary course;

  const _CourseProgress({required this.course});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 5,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'course.sessionProgress'.tr(
                  namedArgs: {
                    'held': '${course.heldSessionCount}',
                    'target': '${course.targetSessionCount}',
                  },
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${((course.progress ?? 0) * 100).round()}%',
              style: context.theme.typography.body.xs.copyWith(
                color: pbBlueDeep,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: course.progress,
            minHeight: 5,
            backgroundColor: colors.border,
            color: pbBlueDeep,
          ),
        ),
      ],
    );
  }
}

class _NextSessionBoard extends StatelessWidget {
  final DateTime? start;

  const _NextSessionBoard({required this.start});

  @override
  Widget build(BuildContext context) {
    final session = start;
    if (session == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: pbInk.withValues(alpha: 0.055),
          border: Border.all(color: pbInk.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(FLucideIcons.calendarClock, size: 18, color: pbBlueDeep),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'course.noNextSession'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.sm.copyWith(
                  color: pbInk.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PMatchBoard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  'course.nextSession'.tr().toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.xs.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  formatMatchDateTime(session).split(' · ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.sm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatTimeOfDay(session),
            style: context.theme.typography.body.xl2.copyWith(
              color: pbAmber,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  final String label;
  final bool secondary;

  const _ActionBadge({required this.label, this.secondary = false});

  @override
  Widget build(BuildContext context) {
    final foreground = secondary ? const Color(0xFF8E5D1F) : pbInk;
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: secondary
            ? pbAmber.withValues(alpha: 0.22)
            : pbCoral.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.theme.typography.body.xs.copyWith(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CourseCardSkeleton extends StatelessWidget {
  const CourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    Widget block(double height, {double? width}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return POffsetFrame(
      offsetColor: colors.muted,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              children: [
                block(58, width: 58),
                const SizedBox(width: 12),
                Expanded(child: block(17, width: 160)),
              ],
            ),
            block(12, width: 220),
            block(58),
            block(36),
          ],
        ),
      ),
    );
  }
}
