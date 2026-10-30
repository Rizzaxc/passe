import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_controller.dart';
import '../core/app_platform.dart';
import '../ui/main.dart';
import 'achievements_section/achievements_controller.dart';
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
      icon: FLucideIcons.trendingUp,
      titleKey: 'health.userHealth.title',
      child: UserHealthSubtab(),
    ),
    (
      icon: FLucideIcons.activity,
      titleKey: 'health.activityData.title',
      child: ActivityDataSubtab(),
    ),
    (
      icon: FLucideIcons.trophy,
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

  @override
  Widget build(BuildContext context) {
    // No HealthKit / Health Connect on web: keep the tab (shell branch
    // indices and nav coach keys stay put) but show what it does instead.
    if (AppPlatform.isWeb) {
      return FScaffold(
        header: FHeader(
          title: Text('health.title'.tr()),
          suffixes: const [NotificationIconButton()],
        ),
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: GetAppPanel(feature: WebGatedFeature.health),
        ),
      );
    }

    final healthStatus = ref.watch(healthControllerProvider);
    final isLinked = healthStatus.value == HealthLinkStatus.linked;
    final hasUnseenAchievements =
        ref.watch(unseenAchievementsProvider).value ?? false;

    return FScaffold(
      header: FHeader(
        title: Text('health.title'.tr()),
        suffixes: [
          // Sync button (device → Supabase) only makes sense once linked.
          if (isLinked) const _SyncButton(),
          const NotificationIconButton(),
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
          if (status != HealthLinkStatus.linked) {
            // A guest has no achievements to show either way.
            if (ref.watch(currentUserIdProvider) == null) {
              return const HealthNotLinkedView();
            }
            // Social badges progress from posts and reactions alone, so
            // achievements stay visible without a wearable; only the
            // device-backed subtabs (trends, activity data) wait on a link.
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: HealthLinkPromptCard(),
                ),
                Expanded(child: AchievementsSubtab()),
              ],
            );
          }

          return PRailTabs(
            index: _currentIndex,
            onChanged: _onTabChanged,
            tabs: [
              for (final section in _sections)
                PRailTab(
                  icon: section.icon,
                  label: section.titleKey.tr(),
                  build: () => section.child,
                  dot:
                      section.icon == FLucideIcons.trophy &&
                      hasUnseenAchievements,
                ),
            ],
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
    final syncing =
        ref.watch(healthSyncControllerProvider) == HealthSyncPhase.syncing;

    return FButton.icon(
      variant: .ghost,
      onPress: syncing
          ? null
          : () async {
              try {
                final result = await ref
                    .read(healthSyncControllerProvider.notifier)
                    .syncNow();
                if (!context.mounted) return;
                showFToast(
                  context: context,
                  title: Text(
                    result.skipped
                        ? 'health.sync.skipped'.tr()
                        : 'health.sync.done'.tr(
                            namedArgs: {
                              'days': '${result.daysSynced}',
                              'activities': '${result.activitiesCaptured}',
                            },
                          ),
                  ),
                );
                // Celebrate any unlock/level-up from this sync.
                if (result.leveledUp) {
                  showFToast(
                    context: context,
                    title: Text('health.achievements.toast.levelUp'.tr()),
                  );
                } else if (result.achievementsUnlocked > 0) {
                  showFToast(
                    context: context,
                    title: Text(
                      'health.achievements.toast.unlocked'.tr(
                        namedArgs: {'count': '${result.achievementsUnlocked}'},
                      ),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  showFToast(
                    context: context,
                    title: Text('health.sync.failed'.tr()),
                  );
                }
              }
            },
      child: syncing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(FLucideIcons.refreshCw, size: 20),
    );
  }
}
