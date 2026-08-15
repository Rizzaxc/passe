import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/format.dart';
import '../core/location_repository.dart';
import '../manage_tab/lobby_section/feed/home_ground_selector.dart';
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
  CourseDetail course, {
  bool allowSearch = true,
}) => showPSheet(
  context: context,
  builder: (_) =>
      _EnrollmentOfferSheet(course: course, allowSearch: allowSearch),
);

class _EnrollCandidate {
  final String userId;
  final String username;
  final String? tagNumber;
  final String? generatedAvatar;

  const _EnrollCandidate({
    required this.userId,
    required this.username,
    this.tagNumber,
    this.generatedAvatar,
  });
}

/// The coach's offer: a name, an optional description, an optional target
/// session count. Accepting it is what turns an inquiry into an enrollment.
///
/// Candidates come from two places — anyone already `inquiring` in this
/// course (the common case: promoting whoever just messaged), and, when
/// [allowSearch] is on, a username/tag search for anyone else.
/// `send_enrollment_offer` adds a not-yet-member as `inquiring` itself
/// (course.sql), so search is the only way to enroll someone who hasn't
/// messaged first. The Feed tab's "Chấp nhận học viên" chip opens this with
/// search off — that entry point exists precisely because someone is
/// already inquiring right there in the thread, so search would just be
/// noise; the info sheet's own "Send enrollment offer" keeps search on for
/// the rarer proactive-invite case.
class _EnrollmentOfferSheet extends ConsumerStatefulWidget {
  final CourseDetail course;
  final bool allowSearch;

  const _EnrollmentOfferSheet({required this.course, this.allowSearch = true});

  @override
  ConsumerState<_EnrollmentOfferSheet> createState() =>
      _EnrollmentOfferSheetState();
}

class _EnrollmentOfferSheetState extends ConsumerState<_EnrollmentOfferSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _target = TextEditingController();
  final _search = TextEditingController();
  String? _userId;
  _EnrollCandidate? _searchSelection;
  List<_EnrollCandidate>? _searchResults;
  bool _searching = false;

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
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final raw = _search.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _searching = true;
      _searchResults = null;
    });

    try {
      final tagOnly = raw.startsWith('#');
      final parts = raw.split('#');
      final username = tagOnly ? null : parts[0].trim();
      final tagNumber = parts.length > 1
          ? parts[1].trim()
          : (tagOnly ? parts[0].replaceAll('#', '').trim() : null);

      // Never surface the coach themselves, or anyone already inquiring/
      // enrolled — those are already one-tap picks in the list above.
      final activeIds = widget.course.members
          .where(
            (m) =>
                m.status != CourseMemberStatus.left &&
                m.status != CourseMemberStatus.removed,
          )
          .map((m) => m.userId)
          .toSet();
      final myId = ref.read(currentUserIdProvider);

      var query = Supabase.instance.client
          .from('user')
          .select('id, username, tag_number, details');
      if (username != null && username.isNotEmpty) {
        query = query.ilike('username', '%$username%');
      }
      if (tagNumber != null && tagNumber.isNotEmpty) {
        query = query.eq('tag_number', tagNumber);
      }
      if (myId != null) query = query.neq('id', myId);
      final rows = await query.limit(10).timeout(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() {
        _searchResults = (rows as List)
            .map((r) {
              final details = r['details'] as Map<String, dynamic>?;
              return _EnrollCandidate(
                userId: r['id'] as String,
                username: r['username'] as String,
                tagNumber: r['tag_number']?.toString(),
                generatedAvatar: details?['generatedAvatar'] as String?,
              );
            })
            .where((c) => !activeIds.contains(c.userId))
            .toList();
      });
    } catch (e, st) {
      Talker().handle(e, st, 'Course user search failed');
      if (!mounted) return;
      showFToast(
        context: context,
        variant: .destructive,
        title: Text('course.actionFailed'.tr()),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
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
                onPress: () => setState(() {
                  _userId = member.userId;
                  _searchSelection = null;
                }),
              ),
          if (widget.allowSearch) ...[
            const SizedBox(height: 16),
            PSectionHeader(title: 'course.enrollUser.label'.tr()),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: FTextField(
                    hint: 'course.enrollUser.hint'.tr(),
                    control: FTextFieldControl.managed(controller: _search),
                  ),
                ),
                const SizedBox(width: 8),
                FButton(
                  variant: .outline,
                  onPress: _searching ? null : _runSearch,
                  child: _searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('course.enrollUser.search'.tr()),
                ),
              ],
            ),
            if (_searchResults != null) ...[
              const SizedBox(height: 8),
              if (_searchResults!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'course.enrollUser.notFound'.tr(
                      namedArgs: {'name': _search.text.trim()},
                    ),
                    style: context.theme.typography.body.sm.copyWith(
                      color: colors.mutedForeground,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: context.theme.style.borderRadius.md,
                    border: Border.all(color: colors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _searchResults!.length; i++) ...[
                        FTile(
                          prefix: PUserAvatar(
                            userId: _searchResults![i].userId,
                            username: _searchResults![i].username,
                            generatedAvatar: _searchResults![i].generatedAvatar,
                            radius: 16,
                          ),
                          title: Text(
                            _searchResults![i].tagNumber == null
                                ? _searchResults![i].username
                                : '${_searchResults![i].username} #${_searchResults![i].tagNumber}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          suffix: _userId == _searchResults![i].userId
                              ? const Icon(FLucideIcons.check)
                              : null,
                          onPress: () => setState(() {
                            _userId = _searchResults![i].userId;
                            _searchSelection = _searchResults![i];
                          }),
                        ),
                        if (i < _searchResults!.length - 1)
                          Divider(
                            height: 1,
                            indent: 48,
                            color: colors.border.withValues(alpha: 0.5),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
            if (_searchSelection != null) ...[
              const SizedBox(height: 8),
              Text(
                'course.enrollUser.selected'.tr(
                  namedArgs: {'username': _searchSelection!.username},
                ),
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
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

const _courseWeekdayKeys = [
  'lobbyHub.schedule.weekdaysShort.monday',
  'lobbyHub.schedule.weekdaysShort.tuesday',
  'lobbyHub.schedule.weekdaysShort.wednesday',
  'lobbyHub.schedule.weekdaysShort.thursday',
  'lobbyHub.schedule.weekdaysShort.friday',
  'lobbyHub.schedule.weekdaysShort.saturday',
  'lobbyHub.schedule.weekdaysShort.sunday',
];

String _formatCourseDate(DateTime date) =>
    '${_courseWeekdayKeys[date.weekday - 1].tr()}, '
    '${date.day}/${date.month}/${date.year}';

void _showCourseTimeError(BuildContext context) {
  showFToast(
    context: context,
    icon: const Icon(FLucideIcons.circleAlert),
    variant: .destructive,
    title: Text('course.endAfterStart'.tr()),
    alignment: .bottomCenter,
  );
}

/// The same date / start / end / venue composition used by the lobby
/// activity planner, shared by both course-session create and edit sheets.
class _CourseWhenWhereFields extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final String? locationId;
  final VoidCallback onPickDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<Map<String, String?>?> onFreeAddressChanged;

  const _CourseWhenWhereFields({
    required this.start,
    required this.end,
    required this.locationId,
    required this.onPickDate,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onLocationChanged,
    required this.onFreeAddressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PSheetSectionLabel(label: 'course.whenWhere'.tr()),
        const SizedBox(height: 8),
        _CoursePickerRow(
          icon: FLucideIcons.calendar,
          label: 'course.date'.tr(),
          value: _formatCourseDate(start),
          onTap: onPickDate,
        ),
        const SizedBox(height: 8),
        _CoursePickerRow(
          icon: FLucideIcons.clock,
          label: 'course.start'.tr(),
          value: formatTimeOfDay(start),
          onTap: onPickStart,
        ),
        const SizedBox(height: 8),
        _CoursePickerRow(
          icon: FLucideIcons.clock,
          label: 'course.sessionEnd'.tr(),
          value: formatTimeOfDay(end),
          onTap: onPickEnd,
        ),
        const SizedBox(height: 8),
        HomeGroundField(
          value: locationId,
          prefixIcon: FLucideIcons.mapPin,
          onChanged: onLocationChanged,
          onFreeAddressChanged: onFreeAddressChanged,
        ),
      ],
    );
  }
}

class _CoursePickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _CoursePickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTappable(
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.secondaryForeground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: context.theme.typography.body.sm.copyWith(
                  color: colors.secondaryForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              FLucideIcons.chevronRight,
              size: 16,
              color: colors.mutedForeground,
            ),
          ],
        ),
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
  late DateTime _start;
  late DateTime _end;
  String? _locationId;
  Map<String, String?>? _freeAddress;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18);
    _end = _start.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      useRootNavigator: true,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDate: _start,
    );
    if (date == null || !mounted) return;
    final duration = _end.difference(_start);
    setState(() {
      _start = DateTime(
        date.year,
        date.month,
        date.day,
        _start.hour,
        _start.minute,
      );
      _end = _start.add(duration);
    });
  }

  Future<void> _pickStart() async {
    final time = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null || !mounted) return;
    final duration = _end.difference(_start);
    setState(() {
      _start = DateTime(
        _start.year,
        _start.month,
        _start.day,
        time.hour,
        time.minute,
      );
      if (!_end.isAfter(_start)) _end = _start.add(duration);
    });
  }

  Future<void> _pickEnd() async {
    final time = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (time == null || !mounted) return;
    final end = DateTime(
      _start.year,
      _start.month,
      _start.day,
      time.hour,
      time.minute,
    );
    if (!end.isAfter(_start)) {
      _showCourseTimeError(context);
      return;
    }
    setState(() => _end = end);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(courseActionControllerProvider);
    final isCoach = widget.course.isCoach;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: isCoach
                ? 'course.scheduleSession'.tr()
                : 'course.proposeSession'.tr(),
          ),
          const SizedBox(height: 20),
          _CourseWhenWhereFields(
            start: _start,
            end: _end,
            locationId: _locationId,
            onPickDate: _pickDate,
            onPickStart: _pickStart,
            onPickEnd: _pickEnd,
            onLocationChanged: (id) => setState(() {
              _locationId = id.isEmpty ? null : id;
              _freeAddress = null;
            }),
            onFreeAddressChanged: (address) => setState(() {
              _freeAddress = address;
              if (address != null) _locationId = null;
            }),
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _note),
            label: Text('course.note'.tr()),
            maxLines: 2,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
            onPress: busy ? null : _submit,
            child: Text('course.submit'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final start = _start;
    final end = _end;

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
      final locationId = await resolveLocationId(
        pickedId: _locationId,
        freeAddress: _freeAddress,
      );
      await ref
          .read(courseActionControllerProvider.notifier)
          .proposeSession(
            courseId: widget.course.courseId,
            start: start,
            end: end,
            locationId: locationId,
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
  builder: (_) => _RescheduleSessionSheet(course: course, session: session),
);

class _RescheduleSessionSheet extends ConsumerStatefulWidget {
  final CourseDetail course;
  final CourseSession session;

  const _RescheduleSessionSheet({required this.course, required this.session});

  @override
  ConsumerState<_RescheduleSessionSheet> createState() =>
      _RescheduleSessionSheetState();
}

class _RescheduleSessionSheetState
    extends ConsumerState<_RescheduleSessionSheet> {
  late DateTime _start = widget.session.startTime.toLocal();
  late DateTime _end =
      widget.session.endTime?.toLocal() ?? _start.add(const Duration(hours: 1));
  late String? _locationId = widget.session.locationId;
  Map<String, String?>? _freeAddress;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _start.isBefore(today) ? today : _start;
    final date = await showDatePicker(
      context: context,
      useRootNavigator: true,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDate: initialDate,
    );
    if (date == null || !mounted) return;
    final duration = _end.difference(_start);
    setState(() {
      _start = DateTime(
        date.year,
        date.month,
        date.day,
        _start.hour,
        _start.minute,
      );
      _end = _start.add(duration);
    });
  }

  Future<void> _pickStart() async {
    final time = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null || !mounted) return;
    final duration = _end.difference(_start);
    setState(() {
      _start = DateTime(
        _start.year,
        _start.month,
        _start.day,
        time.hour,
        time.minute,
      );
      if (!_end.isAfter(_start)) _end = _start.add(duration);
    });
  }

  Future<void> _pickEnd() async {
    final time = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (time == null || !mounted) return;
    final end = DateTime(
      _start.year,
      _start.month,
      _start.day,
      time.hour,
      time.minute,
    );
    if (!end.isAfter(_start)) {
      _showCourseTimeError(context);
      return;
    }
    setState(() => _end = end);
  }

  Future<void> _save() async {
    try {
      final locationId = await resolveLocationId(
        pickedId: _locationId,
        freeAddress: _freeAddress,
      );
      await ref
          .read(courseActionControllerProvider.notifier)
          .reschedule(
            activityId: widget.session.activityId,
            start: _start,
            end: _end,
            locationId: locationId,
            courseId: widget.course.courseId,
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

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(courseActionControllerProvider);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(label: 'course.editSession'.tr()),
          const SizedBox(height: 20),
          _CourseWhenWhereFields(
            start: _start,
            end: _end,
            locationId: _locationId,
            onPickDate: _pickDate,
            onPickStart: _pickStart,
            onPickEnd: _pickEnd,
            onLocationChanged: (id) => setState(() {
              _locationId = id.isEmpty ? null : id;
              _freeAddress = null;
            }),
            onFreeAddressChanged: (address) => setState(() {
              _freeAddress = address;
              if (address != null) _locationId = null;
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'course.rescheduleWarning'.tr(),
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          FButton(
            onPress: busy ? null : _save,
            child: Text('course.saveSession'.tr()),
          ),
          const SizedBox(height: 8),
          FButton(
            variant: .destructive,
            onPress: busy
                ? null
                : () async {
                    try {
                      await ref
                          .read(courseActionControllerProvider.notifier)
                          .cancelSession(
                            widget.session.activityId,
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
            child: Text('course.cancelSession'.tr()),
          ),
        ],
      ),
    );
  }
}

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

Future<void> showCourseReviewSheet(BuildContext context, CourseDetail course) =>
    showPSheet(
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
                    star <= _rating ? FLucideIcons.star : FLucideIcons.starOff,
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
