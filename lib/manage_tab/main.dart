import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../core/sport_selector.dart';
import '../router.dart';
import '../ui/main.dart';
import 'lobby_section/main.dart';
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
      child: ScheduleSubtab(),
      label: Icon(FIcons.calendarDays),
    ),
    FTabEntry(
      child: LobbySubtab(),
      label: Icon(FIcons.users),
    ),
  ];

  @override
  State<ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<ManageTab> with SingleTickerProviderStateMixin {
  late final FTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = FTabController(
      length: 2,
      vsync: this,
      index: widget.initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: Text('nav.manage'.tr()),
        suffixes: [
          const NotificationIconButton(),
          const SportSelector(),
        ],
      ),
      child: FTabs(
        children: ManageTab.manageSections,
      ),
    );
  }
}
