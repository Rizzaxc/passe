import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/sport_selector.dart';
import '../core/state/host_mode_state.dart';
import '../core/state/pro_mode_state.dart';
import '../freeplay/repository.dart';
import '../professional/controller.dart';
import '../professional/pro_mode/booking_history_main.dart';
import '../professional/pro_mode/pending_requests_main.dart';
import '../professional/pro_mode/pro_schedule_main.dart';
import '../ui/main.dart';
import 'coaching_section/main.dart';
import 'freeplay_section/main.dart';
import 'lobby_section/feed/main.dart';
import 'schedule_section/main.dart';

/// Route-level guard for professional booking-request notifications.
///
/// Both OS push taps and the in-app notification center resolve to
/// `ManageRequestsRoute`. That route must not rely on the user's last saved
/// mode: index 1 is Lobby in player mode and Requests in professional mode.
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
      return ManageTab.withInitialTab(0);
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

    return ManageTab.withInitialTab(1, highlightBookingId: highlightBookingId);
  }
}

class ManageTab extends StatefulWidget {
  final int initialIndex;

  // Set from a professional_booking_requested notification tap — threaded
  // down to ProPendingRequestsSection to scroll/highlight that one card.
  final String? highlightBookingId;

  const ManageTab({super.key, this.initialIndex = 0, this.highlightBookingId});

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

  static const manageSections = <FTabEntry>[
    FTabEntry(child: ScheduleSection(), label: Icon(FLucideIcons.calendarDays)),
    FTabEntry(child: LobbySubtab(), label: Icon(FLucideIcons.users)),
    FTabEntry(
      child: CoachingSection(),
      label: Icon(FLucideIcons.graduationCap),
    ),
  ];

  // Pro mode replaces [manageSections] entirely: index 0 is still a
  // schedule-shaped view (the pro's own confirmed bookings, not
  // `my_schedule_data`), index 1 is pending requests (what
  // `ManageRequestsRoute` deep-links to), index 2 is history — no lobby or
  // client-side coaching subtab while in pro mode.
  static List<FTabEntry> proManageSections(
    String professionalId, {
    String? highlightBookingId,
  }) => [
    FTabEntry(
      child: ProScheduleSection(professionalId: professionalId),
      label: const Icon(FLucideIcons.calendarDays),
    ),
    FTabEntry(
      child: ProPendingRequestsSection(
        professionalId: professionalId,
        highlightBookingId: highlightBookingId,
      ),
      label: const Icon(FLucideIcons.inbox),
    ),
    FTabEntry(
      child: ProBookingHistorySection(professionalId: professionalId),
      label: const Icon(FLucideIcons.history),
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
            ? const <FTabEntry>[
                FTabEntry(
                  child: HostFreeplaySection(scheduleOnly: true),
                  label: Icon(FLucideIcons.calendarDays),
                ),
                FTabEntry(
                  child: HostFreeplaySection(),
                  label: Icon(FLucideIcons.ticket),
                ),
              ]
            : linkedProfessionalId != null && proModeActive
            ? ManageTab.proManageSections(
                linkedProfessionalId,
                highlightBookingId: widget.highlightBookingId,
              )
            : ManageTab.manageSections;
        final index = _currentIndex.clamp(0, sections.length - 1);

        return FScaffold(
          header: FHeader(
            title: Text('nav.manage'.tr()),
            suffixes: [const NotificationIconButton(), const SportSelector()],
          ),
          child: FTabs(
            expands: true,
            contentPhysics: const NeverScrollableScrollPhysics(),
            control: FTabControl.lifted(index: index, onChange: _onTabChanged),
            children: sections,
          ),
        );
      },
    );
  }
}
