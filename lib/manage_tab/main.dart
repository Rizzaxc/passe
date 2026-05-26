import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../core/sport_selector.dart';
import '../currency/da_appbar_button.dart';
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
    FTabEntry(
      child: ScheduleSection(),
      label: Icon(FIcons.calendarDays),
    ),
    FTabEntry(
      child: LobbySubtab(),
      label: Icon(FIcons.users),
    ),
    FTabEntry(
      child: CoachingSection(),
      label: Icon(FIcons.graduationCap),
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
    return FScaffold(
      header: FHeader(
        title: Text('nav.manage'.tr()),
        suffixes: [
          const DaAppbarButton(),
          const NotificationIconButton(),
          const SportSelector(),
        ],
      ),
      child: FTabs(
        expands: true,
        contentPhysics: const NeverScrollableScrollPhysics(),
        control: FTabControl.lifted(
          index: _currentIndex,
          onChange: _onTabChanged,
        ),
        children: ManageTab.manageSections,
      ),
    );
  }
}
