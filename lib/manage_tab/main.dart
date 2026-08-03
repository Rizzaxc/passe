import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/sport_selector.dart';
import '../core/state/pro_mode_state.dart';
import '../professional/controller.dart';
import '../professional/pro_mode/booking_history_main.dart';
import '../professional/pro_mode/pending_requests_main.dart';
import '../professional/pro_mode/pro_schedule_main.dart';
import '../ui/main.dart';
import 'coaching_section/main.dart';
import 'lobby_section/feed/main.dart';
import 'schedule_section/main.dart';

class ManageTab extends StatefulWidget {
  final int initialIndex;

  const ManageTab({super.key, this.initialIndex = 0});

  static final instance = ManageTab();

  factory ManageTab.withInitialTab(int initialIndex) {
    return ManageTab(initialIndex: initialIndex);
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
  static List<FTabEntry> proManageSections(String professionalId) => [
    FTabEntry(
      child: ProScheduleSection(professionalId: professionalId),
      label: const Icon(FLucideIcons.calendarDays),
    ),
    FTabEntry(
      child: ProPendingRequestsSection(professionalId: professionalId),
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
        final sections = linkedProfessionalId != null && proModeActive
            ? ManageTab.proManageSections(linkedProfessionalId)
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
