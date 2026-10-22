import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/mode_aware_title.dart';
import '../core/state/host_mode_state.dart';
import '../core/state/pro_mode_state.dart';
import '../course/course_hub.dart';
import '../freeplay/repository.dart';
import '../professional/controller.dart';
import '../professional/pro_mode/booking_history_main.dart';
import '../professional/pro_mode/pending_requests_main.dart';
import '../professional/pro_mode/pro_schedule_main.dart';
import '../ui/main.dart';
import 'freeplay_section/main.dart';
import 'lobby_section/feed/main.dart';
import 'lobby_section/freeplay_section/main.dart';
import 'schedule_section/main.dart';

/// Route-level guard for professional booking-request notifications.
///
/// Both OS push taps and the in-app notification center resolve to
/// `ManageRequestsRoute`. That route must not rely on the user's last saved
/// mode: index 0 is Lobby in player mode and Requests in referee mode.
/// Wait for both lookups, verify this is still a linked professional, then
/// activate professional mode before mounting the requested tab.
class ProfessionalRequestsLanding extends ConsumerWidget {
  final String? highlightBookingId;

  const ProfessionalRequestsLanding({super.key, this.highlightBookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final professionalAsync = ref.watch(linkedProfessionalIdProvider);
    final modeAsync = ref.watch(proModeStateProvider);
    final hostModeAsync = ref.watch(hostModeStateProvider);

    if (professionalAsync.isLoading ||
        modeAsync.isLoading ||
        hostModeAsync.isLoading) {
      return const FScaffold(child: Center(child: CircularProgressIndicator()));
    }

    final professionalId = professionalAsync.asData?.value;
    if (professionalId == null) {
      return ManageTab.withInitialTab(ManageTab.scheduleIndex);
    }

    final proModeActive = modeAsync.asData?.value ?? false;
    final hostModeActive = hostModeAsync.asData?.value ?? false;
    if (!proModeActive || hostModeActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(hostModeStateProvider.notifier).set(false);
        ref.read(proModeStateProvider.notifier).set(true);
      });
      return const FScaffold(child: Center(child: CircularProgressIndicator()));
    }

    return ManageTab.withInitialTab(
      ManageTab.primaryIndex,
      highlightBookingId: highlightBookingId,
    );
  }
}

/// Mode-aware landing for `/manage/course` notification fallbacks.
///
/// Player mode keeps Course third, while coach mode now puts Courses first.
/// Referee and host modes have no course surface, so leave those modes before
/// mounting the player's course hub rather than clamping to an unrelated tab.
class CourseHubLanding extends ConsumerWidget {
  const CourseHubLanding({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeAsync = ref.watch(proModeStateProvider);
    final hostModeAsync = ref.watch(hostModeStateProvider);

    if (modeAsync.isLoading || hostModeAsync.isLoading) {
      return const FScaffold(child: Center(child: CircularProgressIndicator()));
    }

    final proModeActive = modeAsync.asData?.value ?? false;
    final hostModeActive = hostModeAsync.asData?.value ?? false;

    if (hostModeActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(hostModeStateProvider.notifier).set(false);
      });
      return const FScaffold(child: Center(child: CircularProgressIndicator()));
    }

    if (!proModeActive) {
      return ManageTab.withInitialTab(ManageTab.playerCourseIndex);
    }

    final isCoachAsync = ref.watch(isLinkedCoachProvider);
    if (isCoachAsync.isLoading) {
      return const FScaffold(child: Center(child: CircularProgressIndicator()));
    }
    if (isCoachAsync.asData?.value ?? false) {
      return ManageTab.withInitialTab(ManageTab.primaryIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proModeStateProvider.notifier).set(false);
    });
    return const FScaffold(child: Center(child: CircularProgressIndicator()));
  }
}

class ManageTab extends StatefulWidget {
  /// Index contract shared by every Manage mode: the mode's primary hub is
  /// first and its schedule is second.
  static const primaryIndex = 0;
  static const scheduleIndex = 1;
  static const playerCourseIndex = 2;

  /// Appended last so the 0/1/2 deep-link contract above doesn't move.
  static const playerFreeplayIndex = 3;

  final int initialIndex;

  // Set from a professional_booking_requested notification tap — threaded
  // down to ProPendingRequestsSection to scroll/highlight that one card.
  final String? highlightBookingId;

  const ManageTab({
    super.key,
    this.initialIndex = primaryIndex,
    this.highlightBookingId,
  });

  static final instance = ManageTab();

  factory ManageTab.withInitialTab(
    int initialIndex, {
    String? highlightBookingId,
  }) {
    return ManageTab(
      initialIndex: initialIndex,
      highlightBookingId: highlightBookingId,
    );
  }

  static List<PRailTab> get manageSections => [
    PRailTab(
      icon: FLucideIcons.users,
      label: 'manageTab.rail.lobby'.tr(),
      build: () => const LobbySubtab(),
    ),
    PRailTab(
      icon: FLucideIcons.calendarDays,
      label: 'manageTab.rail.schedule'.tr(),
      build: () => const ScheduleSection(),
    ),
    PRailTab(
      icon: FLucideIcons.graduationCap,
      label: 'manageTab.rail.courses'.tr(),
      build: () => const CourseHubSection(),
    ),
    PRailTab(
      icon: FLucideIcons.ticket,
      label: 'discover.rail.freeplay'.tr(),
      build: () => const PlayerFreeplaySubtab(),
    ),
  ];

  static List<PRailTab> get hostManageSections => [
    PRailTab(
      icon: FLucideIcons.ticket,
      label: 'manageTab.rail.listings'.tr(),
      build: () => const HostFreeplaySection(),
    ),
    PRailTab(
      icon: FLucideIcons.calendarDays,
      label: 'manageTab.rail.schedule'.tr(),
      build: () => const ScheduleSection(dataSource: ScheduleDataSource.host),
    ),
  ];

  // Coach mode uses the normal Manage schedule verbatim: `my_schedule_data`
  // already returns the coach's approved course sessions, so a parallel
  // professional calendar would create two structures for the same data.
  // Referees keep the booking-specific schedule/requests/history surfaces.
  static List<PRailTab> proManageSections(
    String professionalId, {
    String? highlightBookingId,
    bool isCoach = false,
  }) => [
    if (isCoach)
      PRailTab(
        icon: FLucideIcons.graduationCap,
        label: 'manageTab.rail.courses'.tr(),
        build: () => const ProCoursesSection(),
      )
    else
      PRailTab(
        icon: FLucideIcons.inbox,
        label: 'manageTab.rail.requests'.tr(),
        build: () => ProPendingRequestsSection(
          professionalId: professionalId,
          highlightBookingId: highlightBookingId,
        ),
      ),
    PRailTab(
      icon: FLucideIcons.calendarDays,
      label: 'manageTab.rail.schedule'.tr(),
      build: () => isCoach
          ? const ScheduleSection()
          : ProScheduleSection(professionalId: professionalId),
    ),
    // History means different things per role: a coach's past work is ended
    // courses, and `ProBookingHistorySection` reads `referee_booking` — which
    // a coach can never have a row in, so it would sit permanently empty.
    if (isCoach)
      PRailTab(
        icon: FLucideIcons.history,
        label: 'manageTab.rail.history'.tr(),
        build: () => const ProCoursesSection(endedOnly: true),
      )
    else
      PRailTab(
        icon: FLucideIcons.history,
        label: 'manageTab.rail.history'.tr(),
        build: () => ProBookingHistorySection(professionalId: professionalId),
      ),
  ];

  @override
  State<ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<ManageTab> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabChanged(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final linkedProfessionalId = ref
            .watch(linkedProfessionalIdProvider)
            .asData
            ?.value;
        final proModeActive =
            ref.watch(proModeStateProvider).asData?.value ?? false;
        final linkedHost = ref.watch(linkedFreeplayHostProvider).asData?.value;
        final hostModeActive =
            ref.watch(hostModeStateProvider).asData?.value ?? false;
        final sections = linkedHost != null && hostModeActive
            ? ManageTab.hostManageSections
            : linkedProfessionalId != null && proModeActive
            ? ManageTab.proManageSections(
                linkedProfessionalId,
                highlightBookingId: widget.highlightBookingId,
                isCoach:
                    ref.watch(isLinkedCoachProvider).asData?.value ?? false,
              )
            : ManageTab.manageSections;
        final index = _currentIndex.clamp(0, sections.length - 1);

        return FScaffold(
          header: FHeader(
            title: ModeAwareTitle('nav.manage'.tr()),
            suffixes: [const NotificationIconButton()],
          ),
          child: PRailTabs(
            tabs: sections,
            index: index,
            onChanged: _onTabChanged,
          ),
        );
      },
    );
  }
}
