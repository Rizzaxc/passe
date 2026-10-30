import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_controller.dart';
import '../core/format.dart';
import '../core/map_directions.dart';
import '../core/model/enum.dart';
import '../logger/talker.dart';
import '../messaging/conversation_view.dart';
import '../router.dart';
import '../ui/main.dart';
import 'course_controller.dart';
import 'course_sheets.dart';
import 'model.dart';

/// The other party's identity, for the header's title fallback and its
/// tappable subline. A student always has one coach
/// ([CourseDetail.coachName]/[coachUserId]); a coach may have several
/// students, so before the course has a real [CourseDetail.name] this falls
/// back to whoever is earliest in the (already live-members-only) roster —
/// same "who's actually asking" logic `course_card.dart`'s hub-list fallback
/// uses.
class _CourseParty {
  final String? userId;
  final String name;
  final String? generatedAvatar;

  const _CourseParty({required this.name, this.userId, this.generatedAvatar});
}

_CourseParty _otherParty(CourseDetail course) {
  if (!course.isCoach) {
    return _CourseParty(
      userId: course.coachUserId,
      name: course.coachName ?? 'course.newInquiry'.tr(),
    );
  }
  final member = course.members.firstOrNull;
  return _CourseParty(
    userId: member?.userId,
    name: member?.username ?? 'course.newInquiry'.tr(),
    generatedAvatar: member?.generatedAvatar,
  );
}

String _courseDisplayName(CourseDetail course) =>
    course.name ?? _otherParty(course).name;

/// One course: **Feed** (the shared thread + pending proposals), **Planner**
/// (approved upcoming sessions + RSVP) and **History** (progress, finished
/// sessions and the viewer's own private reports).
///
/// Mirrors the lobby detail page deliberately — same slim identity header,
/// same chip rail, same card language — because the two screens do the same
/// job for different groups.
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
    final colors = context.theme.colors;
    final course = async.value;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CourseHeader(
              course: course,
              onBackTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  const ManageCourseRoute().go(context);
                }
              },
            ),
            // All 3 tabs are visible to anyone with course access, inquiring
            // students included — an inquiring student can already see
            // scheduled sessions via the feed's system messages, so hiding
            // Planner/History outright bought no real privacy, just an
            // inconsistent, confusing surface. Actions (propose, RSVP, write
            // a report/review) stay gated on `canManage` inside each tab.
            Expanded(
              child: async.when(
                loading: () => const Center(child: FCircularProgress()),
                // Also where a push lands for a course the viewer no longer
                // has access to (left without attending, declined inquiry) —
                // give them a way out instead of a dead end.
                error: (_, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
                      children: [
                        Text(
                          'course.unavailable'.tr(),
                          textAlign: TextAlign.center,
                        ),
                        FButton(
                          variant: .outline,
                          onPress: () =>
                              ref.invalidate(courseDetailProvider(widget.id)),
                          child: Text('course.retry'.tr()),
                        ),
                        FButton(
                          onPress: () => const ManageCourseRoute().go(context),
                          child: Text('course.backToHub'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (course) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (course.pendingOfferId != null)
                      _PendingOfferCard(course: course),
                    // Chip rail — same 14-px inset as the lobby hub, so the
                    // rail and the cards under it line up.
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: PRailTabs(
                          index: _tab,
                          onChanged: (i) => setState(() => _tab = i),
                          tabs: [
                            PRailTab(
                              icon: FLucideIcons.messageCircle,
                              label: 'course.tab.feed'.tr(),
                              build: () => _FeedTab(course: course),
                            ),
                            PRailTab(
                              icon: FLucideIcons.activity,
                              label: 'course.tab.planner'.tr(),
                              build: () => _PlannerTab(course: course),
                            ),
                            PRailTab(
                              icon: FLucideIcons.clock,
                              label: 'course.tab.history'.tr(),
                              build: () => _HistoryTab(course: course),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────

/// The lobby hub's header shape (`_LobbyHeader`): an oversize identity tile
/// + the course name, with back and the info-sheet trigger side by side.
/// Unlike a lobby, a course is defined by *who* it's with, so a tappable
/// subline names the other party (coach for a student, the first student
/// for a coach) and the sport — the one thing that tells two of the same
/// coach's courses apart at a glance.
class _CourseHeader extends StatelessWidget {
  static const _tileSize = 56.0;

  final CourseDetail? course;
  final VoidCallback onBackTap;

  const _CourseHeader({required this.course, required this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final course = this.course;
    final ended = course?.status == CourseStatus.ended;

    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Container(
            width: _tileSize,
            height: _tileSize,
            decoration: BoxDecoration(
              color: ended ? colors.muted : pbAmber,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Icon(
              FLucideIcons.graduationCap,
              size: 26,
              color: ended ? colors.mutedForeground : pbInk,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  course == null
                      ? 'course.title'.tr()
                      : _courseDisplayName(course),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: colors.foreground,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                if (course != null) _PartySubline(course: course),
              ],
            ),
          ),
          IconButton(
            onPressed: onBackTap,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 19,
              color: colors.secondaryForeground,
            ),
            padding: const EdgeInsets.all(7),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          IconButton(
            onPressed: course == null
                ? null
                : () => showCourseInfoSheet(context, course),
            icon: Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: colors.secondaryForeground,
            ),
            padding: const EdgeInsets.all(7),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}

class _PartySubline extends StatelessWidget {
  final CourseDetail course;

  const _PartySubline({required this.course});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final party = _otherParty(course);
    final sport = course.sportId > 0 && course.sportId < Sport.values.length
        ? Sport.values[course.sportId]
        : null;
    final status = course.isCoach
        ? 'course.status.${(course.members.firstOrNull?.status ?? CourseMemberStatus.inquiring).name}'
              .tr()
        : null;
    final muted = context.theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
      fontWeight: FontWeight.w600,
    );

    final row = Row(
      children: [
        if (party.userId case final id?)
          PUserAvatar(
            userId: id,
            username: party.name,
            generatedAvatar: party.generatedAvatar,
            radius: 9,
          )
        else
          Icon(FLucideIcons.user, size: 14, color: colors.mutedForeground),
        const SizedBox(width: 6),
        // One Text.rich so name, sport and status ellipsize together.
        Flexible(
          child: Text.rich(
            TextSpan(
              text: party.name,
              style: muted.copyWith(
                color: colors.secondaryForeground,
                fontWeight: FontWeight.w700,
              ),
              children: [
                if (sport != null)
                  TextSpan(
                    text: ' · ${sport.getLocalizedName(context)}',
                    style: muted,
                  ),
                if (status != null) TextSpan(text: ' · $status', style: muted),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (party.userId == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          UserRoute(id: party.userId!, $extra: party.name).push(context),
      child: row,
    );
  }
}

// ─── Enrollment offer ──────────────────────────────────────────

/// Everything a student needs to decide, right where they land after the
/// `course_enrollment_offer` push routes them here — there was previously no
/// way to accept an offer anywhere in the app.
class _PendingOfferCard extends ConsumerWidget {
  final CourseDetail course;

  const _PendingOfferCard({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final busy = ref.watch(courseActionControllerProvider);
    final offerId = course.pendingOfferId;
    if (offerId == null) return const SizedBox.shrink();
    final radius = BorderRadius.circular(14);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: POffsetFrame(
        offsetColor: pbCoral,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: pbInk.withValues(alpha: 0.16)),
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: pbCoral.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      FLucideIcons.mailOpen,
                      size: 18,
                      color: _courseCrimson,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          'course.offerReceivedTitle'.tr().toUpperCase(),
                          style: context.theme.typography.body.xs.copyWith(
                            color: _courseCrimson,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          course.offerName ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.theme.typography.body.md.copyWith(
                            color: pbInk,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (course.offerDescription?.trim().isNotEmpty == true)
                Text(
                  course.offerDescription!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              if (course.offerTargetSessionCount != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: _CourseTag(
                    icon: FLucideIcons.target,
                    text: 'course.offerTargetSessions'.plural(
                      course.offerTargetSessionCount!,
                    ),
                  ),
                ),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: FButton(
                      variant: .outline,
                      size: .sm,
                      onPress: busy
                          ? null
                          : () => _respond(context, ref, false),
                      child: Text('course.declineOffer'.tr()),
                    ),
                  ),
                  Expanded(
                    child: FButton(
                      size: .sm,
                      onPress: busy ? null : () => _respond(context, ref, true),
                      prefix: const Icon(FLucideIcons.check, size: 16),
                      child: Text('course.acceptOffer'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    bool accept,
  ) async {
    if (!accept) {
      final confirmed = await confirmCourseAction(
        context,
        title: 'course.declineOfferTitle'.tr(),
        body: 'course.declineOfferBody'.tr(),
        confirmLabel: 'course.declineOffer'.tr(),
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
    }
    try {
      final joinedId = await ref
          .read(courseActionControllerProvider.notifier)
          .respondToOffer(
            course.pendingOfferId!,
            accept,
            courseId: course.courseId,
          );
      // A group-course offer shown in this inquiry thread moved us into
      // that course; this thread is now closed to us.
      if (accept && joinedId != course.courseId && context.mounted) {
        CourseDetailRoute(id: joinedId).pushReplacement(context);
      }
    } catch (e, st) {
      talker.handle(e, st, 'Respond to enrollment offer failed');
      if (context.mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('course.actionFailed'.tr()),
        );
      }
    }
  }
}

// ─── Feed ──────────────────────────────────────────────────────

/// The thread, plus the approve/reject queue above it — a pending proposal
/// is a thing to act on, not just a message to read. The queue is capped so
/// a backlog of proposals can't push the thread off screen.
class _FeedTab extends ConsumerWidget {
  final CourseDetail course;

  const _FeedTab({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = course.conversationId;
    final hasInquirer = course.members.any(
      (m) => m.status == CourseMemberStatus.inquiring,
    );
    final proposals = course.pendingProposals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (proposals.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: _OverlineLabel(
              text: 'course.pendingProposals'.tr(),
              count: proposals.length,
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.32,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: proposals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _ProposalCard(course: course, session: proposals[i]),
            ),
          ),
        ],
        Expanded(
          child: conversationId == null
              ? Center(
                  child: PEmptySectionPlaceholder(
                    hero: Icon(
                      FLucideIcons.messagesSquare,
                      size: 48,
                      color: context.theme.colors.mutedForeground,
                    ),
                    subtitle: 'course.noThread'.tr(),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
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
/// Beside it, the other answer to an inquiry: declining it.
class _EnrollInquirerChip extends ConsumerWidget {
  final CourseDetail course;

  const _EnrollInquirerChip({required this.course});

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    final inquirer = course.members
        .where((m) => m.status == CourseMemberStatus.inquiring)
        .firstOrNull;
    if (inquirer == null) return;
    final confirmed = await confirmCourseAction(
      context,
      title: 'course.declineInquiryTitle'.tr(),
      body: 'course.declineInquiryBody'.tr(
        namedArgs: {'username': inquirer.username},
      ),
      confirmLabel: 'course.declineInquiry'.tr(),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(courseActionControllerProvider.notifier)
          .declineInquiry(course.courseId, inquirer.userId);
      // A bare inquiry is ended server-side once nobody is left in it, so
      // there's nothing more to do on this page.
      if (context.mounted) context.pop();
    } catch (e, st) {
      talker.handle(e, st, 'Decline course inquiry failed');
      if (context.mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('course.actionFailed'.tr()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final busy = ref.watch(courseActionControllerProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Semantics(
            button: true,
            label: 'course.enrollChip'.tr(),
            child: FTappable(
              onPress: () =>
                  showEnrollmentOfferSheet(context, course, allowSearch: false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
          ),
          Semantics(
            button: true,
            label: 'course.declineInquiry'.tr(),
            child: FTappable(
              onPress: busy ? null : () => _decline(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FLucideIcons.userX,
                      size: 14,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'course.declineInquiry'.tr(),
                      style: context.theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pending session proposal: when, where, who asked, and — for whoever
/// can act on it — the decision right on the card.
class _ProposalCard extends ConsumerWidget {
  final CourseDetail course;
  final CourseSession session;

  const _ProposalCard({required this.course, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final controller = ref.watch(courseActionControllerProvider.notifier);
    final busy = ref.watch(courseActionControllerProvider);
    // withdraw_course_proposal is proposer-only server-side; only show the
    // button to the one viewer it would actually work for. Everyone else
    // (including another inquiring/enrolled student who isn't the proposer)
    // just reads the row.
    final isMine = session.proposedBy == ref.watch(currentUserIdProvider);
    final proposer = course.members
        .where((m) => m.userId == session.proposedBy)
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amber edge — "waiting on a decision", vs. the crimson strip
            // of an approved session.
            const SizedBox(width: 3, child: ColoredBox(color: pbAmber)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DateBlock(date: session.startTime),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SessionSummary(
                            course: course,
                            session: session,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: course.isCoach && proposer != null
                              ? _UserChip(
                                  userId: proposer.userId,
                                  username: proposer.username,
                                  generatedAvatar: proposer.generatedAvatar,
                                )
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: _CourseTag(
                                    icon: FLucideIcons.hourglass,
                                    text: 'course.awaitingApproval'.tr(),
                                    tone: _TagTone.amber,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        if (course.isCoach) ...[
                          FButton(
                            variant: .outline,
                            size: .sm,
                            onPress: busy
                                ? null
                                : () =>
                                      _approve(context, ref, controller, false),
                            child: Text('course.reject'.tr()),
                          ),
                          const SizedBox(width: 6),
                          FButton(
                            size: .sm,
                            onPress: busy
                                ? null
                                : () =>
                                      _approve(context, ref, controller, true),
                            prefix: const Icon(FLucideIcons.check, size: 14),
                            child: Text('course.approve'.tr()),
                          ),
                        ] else if (isMine)
                          FButton(
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

/// Time range, venue and note — the compact body shared by proposal and
/// past-session cards (the planner's own card keeps the big date header).
class _SessionSummary extends StatelessWidget {
  final CourseDetail course;
  final CourseSession session;

  const _SessionSummary({required this.course, required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          _timeRangeLabel(session),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.theme.typography.body.md.copyWith(
            color: _courseCrimson,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        if (session.venueName != null)
          _CourseSessionDetailRow(
            icon: FLucideIcons.mapPin,
            text: session.venueName!,
            onPress: _hasCourseSessionDirections(session)
                ? () => _openCourseSessionDirections(context, session)
                : null,
          ),
        if (session.note != null)
          _CourseSessionDetailRow(
            icon: FLucideIcons.stickyNote,
            text: session.note!,
            maxLines: 2,
          ),
      ],
    );
  }
}

// ─── Planner ───────────────────────────────────────────────────

/// Mirrors the lobby hub's Planner tab shape: a section header with an
/// always-reachable "+" rather than a full-width button buried in the list,
/// and a card-style empty state instead of a bare placeholder line.
class _PlannerTab extends ConsumerWidget {
  final CourseDetail course;

  const _PlannerTab({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = course.upcoming;
    // Every viewer with course access sees this tab, including an inquiring
    // student — but only the coach and an enrolled student may actually
    // schedule/propose.
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
            // Cards carry their own 4-px side margin, same as the lobby's
            // ActivityCard, so the list itself is not inset.
            child: upcoming.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 32),
                    children: [
                      _CourseEmptyCard(
                        icon: FLucideIcons.calendarDays,
                        title: 'course.noUpcoming'.tr(),
                        // An inquiring student with no pending offer has
                        // course access but nothing to do here yet, and
                        // previously nothing said why — this tab just looked
                        // permanently empty/broken to them.
                        subtitle:
                            !canPropose &&
                                !course.isCoach &&
                                course.pendingOfferId == null
                            ? 'course.waitingForCoach'.tr(
                                namedArgs: {'coach': course.coachName ?? ''},
                              )
                            : null,
                        actionLabel: !canPropose
                            ? null
                            : course.isCoach
                            ? 'course.scheduleSession'.tr()
                            : 'course.proposeSession'.tr(),
                        onAction: canPropose
                            ? () => showProposeSessionSheet(context, course)
                            : null,
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: upcoming.length,
                    itemBuilder: (context, i) => _SessionCard(
                      course: course,
                      session: upcoming[i],
                      isNext: i == 0,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final CourseDetail course;
  final CourseSession session;

  /// The soonest upcoming session — tagged so it stands out from the rest.
  final bool isNext;

  /// History's reading of the same card, as the lobby's History reuses its
  /// `ActivityCard`: RSVP and edit give way to attendance and reports.
  final bool isPast;

  const _SessionCard({
    required this.course,
    required this.session,
    this.isNext = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final controller = ref.watch(courseActionControllerProvider.notifier);
    final busy = ref.watch(courseActionControllerProvider);
    final start = session.startTime.toLocal();
    final dateLabel = '${_weekdayShort(start)}, ${start.day}/${start.month}';
    final duration = session.endTime?.difference(session.startTime);
    final hasDirections = _hasCourseSessionDirections(session);
    final canEdit = !isPast && course.isCoach && !session.hasStarted;
    final going = session.goingCount > 0;
    final attended = session.myAttended;
    final reports = isPast
        ? course.reports
              .where((r) => r.activityId == session.activityId)
              .toList()
        : const <SessionReport>[];
    final canReport = isPast && course.isCoach;

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF09090B),
                          letterSpacing: -0.5,
                          height: 1.05,
                        ),
                      ),
                    ),
                    if (isNext && !isPast) ...[
                      const SizedBox(width: 8),
                      _CourseTag(
                        icon: FLucideIcons.sparkles,
                        text: 'course.nextUp'.tr(),
                        tone: _TagTone.crimson,
                      ),
                    ],
                    if (isPast && !course.isCoach && attended != null) ...[
                      const SizedBox(width: 8),
                      _CourseTag(
                        icon: attended ? FLucideIcons.check : FLucideIcons.x,
                        text: attended
                            ? 'course.attendance.present'.tr()
                            : 'course.attendance.absent'.tr(),
                        tone: attended ? _TagTone.green : _TagTone.orange,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _timeRangeLabel(session),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _courseCrimson,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
                if (session.venueName != null) ...[
                  const SizedBox(height: 10),
                  _CourseSessionDetailRow(
                    icon: FLucideIcons.mapPin,
                    text: session.venueName!,
                    subtitle: session.streetAddress,
                  ),
                ],
                if (duration != null && duration.inMinutes > 0) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _CourseTag(
                        icon: FLucideIcons.timer,
                        text: 'course.durationMinutes'.plural(
                          duration.inMinutes,
                        ),
                      ),
                    ],
                  ),
                ],
                if (session.note != null) ...[
                  const SizedBox(height: 8),
                  _CourseSessionDetailRow(
                    icon: FLucideIcons.stickyNote,
                    text: session.note!,
                    maxLines: 3,
                  ),
                ],
                if (!isPast) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        going ? Icons.check_circle : Icons.check_circle_outline,
                        size: 14,
                        color: going ? _courseGreen : colors.mutedForeground,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'course.goingCount'.plural(session.goingCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.theme.typography.body.sm.copyWith(
                            color: going
                                ? _courseGreen
                                : colors.secondaryForeground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // The coach's present/absent marks, then the private
                // write-ups this viewer is entitled to.
                if (isPast && course.isCoach && session.roster.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'course.attendance.title'.tr().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.mutedForeground,
                      letterSpacing: 0.7,
                    ),
                  ),
                  for (final entry in session.roster)
                    _AttendanceRow(
                      course: course,
                      session: session,
                      entry: entry,
                    ),
                ],
                for (final report in reports) ...[
                  const SizedBox(height: 10),
                  _ReportBlock(course: course, report: report),
                ],
                // RSVP closes at kickoff (server-side too).
                if (!isPast && course.canManage && !session.hasStarted) ...[
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
                // Same quick-action strip as the lobby's activity card. A
                // started session can't be moved or cancelled any more.
                if (hasDirections || canEdit || canReport) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: Row(
                            children: [
                              if (canReport) ...[
                                PQuickAction(
                                  icon: Icons.edit_note_outlined,
                                  label: 'course.writeReport'.tr(),
                                  onTap: () => showSessionReportSheet(
                                    context,
                                    course,
                                    session,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (hasDirections)
                                PQuickAction(
                                  icon: Icons.navigation_outlined,
                                  label: 'lobbyHub.activity.directions'.tr(),
                                  onTap: () => _openCourseSessionDirections(
                                    context,
                                    session,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // The lobby card's trailing "…": edit/cancel live in a
                      // sheet rather than as more chips in the strip.
                      if (canEdit) ...[
                        const SizedBox(width: 6),
                        Semantics(
                          button: true,
                          label: 'course.sessionActions'.tr(),
                          child: GestureDetector(
                            onTap: busy
                                ? null
                                : () => showSessionActionsSheet(
                                    context,
                                    course,
                                    session,
                                  ),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.more_horiz_rounded,
                                size: 18,
                                color: colors.secondaryForeground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

// ─── History ───────────────────────────────────────────────────

/// The lobby hub's History shape: a record card, a strip of filter pills,
/// then every finished session drawn with the Planner's own card in its past
/// reading — attendance and the private reports the viewer is entitled to. A
/// student sees only their own reports; the coach sees all of them and can
/// write the ones still missing.
class _HistoryTab extends ConsumerStatefulWidget {
  final CourseDetail course;

  const _HistoryTab({required this.course});

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

enum _HistoryFilter { all, attended, missed, reported, unreported }

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  _HistoryFilter _filter = _HistoryFilter.all;

  List<_HistoryFilter> get _filters => widget.course.isCoach
      ? const [
          _HistoryFilter.all,
          _HistoryFilter.unreported,
          _HistoryFilter.reported,
        ]
      : const [
          _HistoryFilter.all,
          _HistoryFilter.attended,
          _HistoryFilter.missed,
          _HistoryFilter.reported,
        ];

  bool _hasReport(CourseSession s) =>
      widget.course.reports.any((r) => r.activityId == s.activityId);

  /// A coach still owes a report when someone attended and has none yet.
  bool _owesReport(CourseSession s) => s.roster.any(
    (e) =>
        e.attended &&
        !widget.course.reports.any(
          (r) => r.activityId == s.activityId && r.studentId == e.userId,
        ),
  );

  List<CourseSession> _apply(List<CourseSession> past) => switch (_filter) {
    _HistoryFilter.all => past,
    _HistoryFilter.attended => past.where((s) => s.myAttended == true).toList(),
    _HistoryFilter.missed => past.where((s) => s.myAttended == false).toList(),
    _HistoryFilter.reported => past.where(_hasReport).toList(),
    _HistoryFilter.unreported => past.where(_owesReport).toList(),
  };

  static String _label(_HistoryFilter f) => switch (f) {
    _HistoryFilter.all => 'lobbyHub.history.all'.tr(),
    _HistoryFilter.attended => 'course.attendance.present'.tr(),
    _HistoryFilter.missed => 'course.attendance.absent'.tr(),
    _HistoryFilter.reported => 'course.filter.reported'.tr(),
    _HistoryFilter.unreported => 'course.filter.unreported'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final past = course.past;
    final filtered = _apply(past);

    return RefreshIndicator(
      onRefresh: () =>
          ref.refresh(courseDetailProvider(course.courseId).future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: _ProgressCard(course: course),
            ),
          ),
          if (course.canReview)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                child: _ReviewPrompt(course: course),
              ),
            ),
          if (past.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 32),
                child: _CourseEmptyCard(
                  icon: FLucideIcons.history,
                  title: 'course.noHistory'.tr(),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    return _FilterPill(
                      label: _label(f),
                      active: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    );
                  },
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: PEmptySectionPlaceholder(
                  subtitle: 'course.filter.empty'.tr(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(top: 6, bottom: 20),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _SessionCard(
                    course: course,
                    session: filtered[i],
                    isPast: true,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The lobby History's filter pill.
class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? _courseCrimson : context.theme.colors.secondary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? const Color(0xFFFFF1F2)
                : context.theme.colors.secondaryForeground,
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final CourseDetail course;

  const _ProgressCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final c = context.theme.colors;
    final target = course.targetSessionCount;
    final held = course.heldSessionCount;
    final progress = target == null || target == 0
        ? null
        : (held / target).clamp(0.0, 1.0);

    final List<Widget> stats;
    if (course.isCoach) {
      final students = course.members
          .where((m) => m.status == CourseMemberStatus.enrolled)
          .length;
      stats = [
        _HStat(
          value: target == null ? '$held' : '$held/$target',
          label: 'course.stats.held'.tr(),
          color: c.foreground,
        ),
        _HStat(
          value: '$students',
          label: 'course.stats.students'.tr(),
          color: pbBlueDeep,
        ),
        _HStat(
          value: '${course.reports.length}',
          label: 'course.stats.reports'.tr(),
          color: _courseGreen,
        ),
      ];
    } else {
      final attended = course.past.where((s) => s.myAttended == true).length;
      final missed = course.past.where((s) => s.myAttended == false).length;
      final marked = attended + missed;
      stats = [
        _HStat(
          value: target == null ? '$held' : '$held/$target',
          label: 'course.stats.held'.tr(),
          color: c.foreground,
        ),
        _HStat(
          value: '$attended',
          label: 'course.stats.attended'.tr(),
          color: _courseGreen,
        ),
        _HStat(
          value: '$missed',
          label: 'course.stats.missed'.tr(),
          color: _courseOrange,
        ),
        _HStat(
          value: marked == 0 ? '–' : '${(attended * 100 / marked).round()}%',
          label: 'course.stats.rate'.tr(),
          color: _courseCrimson,
        ),
      ];
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'course.stats.title'.tr().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.mutedForeground,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              if (course.status == CourseStatus.ended)
                _CourseTag(
                  icon: FLucideIcons.flag,
                  text: 'course.ended'.tr(),
                  tone: _TagTone.green,
                ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(spacing: 18, children: stats),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: c.border,
                      color: pbBlueDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).round()}%',
                  style: context.theme.typography.body.xs.copyWith(
                    color: pbBlueDeep,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _HStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: context.theme.colors.mutedForeground,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ReviewPrompt extends StatelessWidget {
  final CourseDetail course;

  const _ReviewPrompt({required this.course});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pbAmber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pbAmber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(FLucideIcons.star, size: 20, color: pbInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'course.reviewPrompt'.tr(
                namedArgs: {'coach': course.coachName ?? ''},
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.sm.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FButton(
            size: .sm,
            onPress: () => showCourseReviewSheet(context, course),
            child: Text('course.writeReview'.tr()),
          ),
        ],
      ),
    );
  }
}

/// A coach's private write-up, quoted. The coach sees whom it's for; a
/// student only ever receives their own, so it's labelled as the coach's.
class _ReportBlock extends StatelessWidget {
  final CourseDetail course;
  final SessionReport report;

  const _ReportBlock({required this.course, required this.report});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final student = course.members
        .where((m) => m.userId == report.studentId)
        .firstOrNull;
    final label = course.isCoach && student != null
        ? 'course.reportFor'.tr(namedArgs: {'username': student.username})
        : 'course.coachReport'.tr();

    return Container(
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 3, child: ColoredBox(color: pbBlueDeep)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          FLucideIcons.quote,
                          size: 12,
                          color: pbBlueDeep,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.typography.body.xs.copyWith(
                              color: pbBlueDeep,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(report.body, style: context.theme.typography.body.sm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared bits ───────────────────────────────────────────────

String _weekdayShort(DateTime d) => [
  'lobbyHub.schedule.weekdaysShort.monday',
  'lobbyHub.schedule.weekdaysShort.tuesday',
  'lobbyHub.schedule.weekdaysShort.wednesday',
  'lobbyHub.schedule.weekdaysShort.thursday',
  'lobbyHub.schedule.weekdaysShort.friday',
  'lobbyHub.schedule.weekdaysShort.saturday',
  'lobbyHub.schedule.weekdaysShort.sunday',
][d.weekday - 1].tr();

String _timeRangeLabel(CourseSession session) {
  final start = formatTimeOfDay(session.startTime.toLocal());
  final end = session.endTime;
  return end == null ? start : '$start – ${formatTimeOfDay(end.toLocal())}';
}

/// A compact calendar-leaf: weekday over day/month.
class _DateBlock extends StatelessWidget {
  final DateTime date;

  const _DateBlock({required this.date});

  @override
  Widget build(BuildContext context) {
    final d = date.toLocal();
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _courseCrimsonTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _weekdayShort(d).toUpperCase(),
            maxLines: 1,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _courseCrimson,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${d.day}/${d.month}',
              maxLines: 1,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: pbInk,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase label with an optional count pill — the lobby feed's
/// day-divider voice, used to head a group inside a tab.
class _OverlineLabel extends StatelessWidget {
  final String text;
  final int? count;

  const _OverlineLabel({required this.text, this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      children: [
        Flexible(
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colors.mutedForeground,
              letterSpacing: 0.7,
            ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.secondaryForeground,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

enum _TagTone { neutral, crimson, green, orange, amber }

/// The lobby activity card's `_Tag` pill, in the tones a course needs.
class _CourseTag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final _TagTone tone;

  const _CourseTag({
    required this.text,
    this.icon,
    this.tone = _TagTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final (fg, bg) = switch (tone) {
      _TagTone.crimson => (_courseCrimson, _courseCrimsonTint),
      _TagTone.green => (_courseGreen, _courseGreenTint),
      _TagTone.orange => (_courseOrange, _courseOrange.withValues(alpha: 0.1)),
      _TagTone.amber => (pbInk, pbAmber.withValues(alpha: 0.22)),
      _TagTone.neutral => (colors.secondaryForeground, colors.secondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar + name, tappable through to the user's page.
class _UserChip extends StatelessWidget {
  final String userId;
  final String username;
  final String? generatedAvatar;

  const _UserChip({
    required this.userId,
    required this.username,
    this.generatedAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => UserRoute(id: userId, $extra: username).push(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PUserAvatar(
            userId: userId,
            username: username,
            generatedAvatar: generatedAvatar,
            radius: 11,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CourseEmptyCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _courseCrimsonTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: _courseCrimson),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.theme.typography.body.md.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: context.theme.typography.body.sm.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            Center(
              child: FButton(
                size: .sm,
                mainAxisSize: MainAxisSize.min,
                onPress: onAction,
                prefix: const Icon(FLucideIcons.plus, size: 16),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Same ad-hoc pair the lobby activity card uses
// (`manage_tab/lobby_section/activity/activity_card.dart`), so a course
// session and a lobby session read as the same kind of object. The green half
// is the brand token; only the crimson and the tint are local.
const _courseCrimson = Color(0xFFDC143C);
const _courseCrimsonTint = Color(0xFFFFEBED);
const _courseGreen = pbGreen;
const _courseGreenTint = Color(0xFFEEF2E4);
// The lobby history's loss orange, for a missed session.
const _courseOrange = Color(0xFFF97316);

bool _hasCourseSessionDirections(CourseSession session) =>
    mapDirectionsDestination(
      lat: session.locationLat,
      lon: session.locationLon,
      address: session.streetAddress,
      label: session.venueName,
    ) !=
    null;

Future<void> _openCourseSessionDirections(
  BuildContext context,
  CourseSession session,
) => openMapDirections(
  context,
  lat: session.locationLat,
  lon: session.locationLon,
  address: session.streetAddress,
  label: session.venueName ?? '',
);

class _CourseSessionDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? subtitle;
  final int maxLines;
  final VoidCallback? onPress;

  const _CourseSessionDetailRow({
    required this.icon,
    required this.text,
    this.subtitle,
    this.maxLines = 1,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.secondaryForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle?.trim().isNotEmpty == true)
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
        if (onPress != null) ...[
          const SizedBox(width: 6),
          // The lobby's "Chỉ Đường" glyph, so every directions affordance
          // on this page reads the same.
          Icon(
            Icons.navigation_outlined,
            size: 15,
            color: context.theme.colors.mutedForeground,
          ),
        ],
      ],
    );
    return onPress == null ? row : FTappable(onPress: onPress!, child: row);
  }
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

/// One student on a started session's roster, with the coach's
/// present/absent mark. The mark overrides the RSVP as the attendance signal
/// (reports, review eligibility) and stays correctable.
class _AttendanceRow extends ConsumerWidget {
  final CourseDetail course;
  final CourseSession session;
  final SessionRosterEntry entry;

  const _AttendanceRow({
    required this.course,
    required this.session,
    required this.entry,
  });

  Future<void> _mark(BuildContext context, WidgetRef ref, bool attended) async {
    try {
      await ref
          .read(courseActionControllerProvider.notifier)
          .markAttendance(
            activityId: session.activityId,
            studentId: entry.userId,
            attended: attended,
            courseId: course.courseId,
          );
    } catch (e, st) {
      talker.handle(e, st, 'Mark course attendance failed');
      if (context.mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('course.actionFailed'.tr()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final busy = ref.watch(courseActionControllerProvider);
    final hint = entry.marked != null
        ? null
        : entry.rsvp == 'going'
        ? 'course.attendance.fromRsvp'.tr()
        : 'course.attendance.unmarked'.tr();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => UserRoute(
                id: entry.userId,
                $extra: entry.username,
              ).push(context),
              child: Row(
                children: [
                  PUserAvatar(
                    userId: entry.userId,
                    username: entry.username,
                    generatedAvatar: entry.generatedAvatar,
                    radius: 12,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: entry.username,
                        children: [
                          if (hint != null)
                            TextSpan(
                              text: '  $hint',
                              style: context.theme.typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.theme.typography.body.sm,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'course.attendance.present'.tr(),
            child: FButton.icon(
              variant: entry.attended ? .primary : .outline,
              size: .sm,
              onPress: busy || entry.marked == true
                  ? null
                  : () => _mark(context, ref, true),
              child: const Icon(FLucideIcons.check, size: 14),
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: 'course.attendance.absent'.tr(),
            child: FButton.icon(
              variant: entry.attended ? .outline : .destructive,
              size: .sm,
              onPress: busy || entry.marked == false
                  ? null
                  : () => _mark(context, ref, false),
              child: const Icon(FLucideIcons.x, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
