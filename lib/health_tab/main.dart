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
import 'health_sync_service.dart';
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
    final isLinked = healthStatus.value == HealthLinkStatus.linked;

    return FScaffold(
      header: FHeader(
        title: Text('health.title'.tr()),
        suffixes: [
          // Sync button (device → Supabase) only makes sense once linked.
          if (isLinked) const _SyncButton(),
          const DaAppbarButton(),
          const NotificationIconButton(),
          const SportSelector(),
        ],
      ),
      // No tab-level RefreshIndicator: pull-to-refresh (Supabase reads) lives in
      // each data subtab. Only the not-linked / error states get a pull-to-recheck.
      child: healthStatus.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(healthControllerProvider);
            await ref.read(healthControllerProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('health.error'.tr())),
              ),
            ],
          ),
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
    );
  }
}

/// Header action that pushes device data into Supabase. Shows a spinner while
/// syncing and toasts the result. Distinct from pull-to-refresh, which only
/// re-reads Supabase.
class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncing = ref.watch(healthSyncControllerProvider) == HealthSyncPhase.syncing;

    return FButton.icon(
      variant: .ghost,
      onPress: syncing
          ? null
          : () async {
              try {
                final result =
                    await ref.read(healthSyncControllerProvider.notifier).syncNow();
                if (!context.mounted) return;
                showFToast(
                  context: context,
                  title: Text(result.skipped
                      ? 'health.sync.skipped'.tr()
                      : 'health.sync.done'.tr(namedArgs: {
                          'days': '${result.daysSynced}',
                          'activities': '${result.activitiesCaptured}',
                        })),
                );
              } catch (_) {
                if (context.mounted) {
                  showFToast(context: context, title: Text('health.sync.failed'.tr()));
                }
              }
            },
      child: syncing
          ? const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(FIcons.refreshCw, size: 20),
    );
  }
}
