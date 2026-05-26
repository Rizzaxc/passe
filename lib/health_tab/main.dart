import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/sport_selector.dart';
import '../currency/da_appbar_button.dart';
import '../ui/main.dart';
import 'achievements_section/main.dart';
import 'activity_data_section/main.dart';
import 'health_controller.dart';
import 'not_linked_view.dart';
import 'user_health_section/main.dart';

class HealthTab extends ConsumerStatefulWidget {
  final int initialIndex;

  const HealthTab({super.key, this.initialIndex = 0});

  factory HealthTab.withInitialTab(int initialIndex) {
    return HealthTab(initialIndex: initialIndex);
  }

  @override
  ConsumerState<HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends ConsumerState<HealthTab> {
  late int _currentIndex;

  static const _sections = [
    (
      icon: FIcons.trendingUp,
      titleKey: 'health.userHealth.title',
      child: UserHealthSubtab(),
    ),
    (
      icon: FIcons.activity,
      titleKey: 'health.activityData.title',
      child: ActivityDataSubtab(),
    ),
    (
      icon: FIcons.trophy,
      titleKey: 'health.achievements.title',
      child: AchievementsSubtab(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<FTabEntry> _buildTabEntries() {
    return _sections.map((section) => FTabEntry(
      label: Icon(section.icon, key: const ValueKey('icon')),
      child: section.child,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final healthStatus = ref.watch(healthControllerProvider);

    return FScaffold(
      header: FHeader(
        title: Text('health.title'.tr()),
        suffixes: [
          const DaAppbarButton(),
          const NotificationIconButton(),
          const SportSelector(),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(healthControllerProvider);
          await ref.read(healthControllerProvider.future);
        },
        child: healthStatus.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [Center(child: Text('health.error'.tr()))],
          ),
          data: (status) {
            if (status == HealthLinkStatus.notLinked) {
              return const HealthNotLinkedView();
            }

            return FTabs(
              expands: true,
              contentPhysics: const NeverScrollableScrollPhysics(),
              control: FTabControl.lifted(
                index: _currentIndex,
                onChange: _onTabChanged,
              ),
              children: _buildTabEntries(),
            );
          },
        ),
      ),
    );
  }
}
