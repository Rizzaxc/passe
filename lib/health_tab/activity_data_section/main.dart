import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/enum.dart';
import '../../core/state/selected_sport_state.dart';
import '../../ui/main.dart';
import '../health_data_controller.dart';
import '../health_data_service.dart';
import '../health_sync_service.dart';
import '../model/activity_health_row.dart';
import 'recap_sheet.dart';
import 'zone_bar.dart';

class ActivityDataSubtab extends ConsumerWidget {
  const ActivityDataSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sport = ref.watch(selectedSportStateProvider).value;
    final detected = ref.watch(detectedWorkoutsProvider);
    final recaps = ref.watch(activityHealthListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activityHealthListProvider);
        ref.invalidate(detectedWorkoutsProvider);
        await ref.read(activityHealthListProvider.future);
      },
      child: (sport == null || sport == Sport.others)
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [PEmptySectionPlaceholder(subtitle: 'health.activityData.selectSport'.tr())],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              children: [
                // Detected workouts (reconciliation inbox).
                ...detected.maybeWhen(
                  data: (items) => items.isEmpty
                      ? const []
                      : [
                          _SectionLabel(text: 'health.detected.title'.tr()),
                          const SizedBox(height: 8),
                          for (final w in items) ...[
                            _DetectedCard(workout: w),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 8),
                        ],
                  orElse: () => const [],
                ),

                // Recaps.
                recaps.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text('health.error'.tr())),
                  ),
                  data: (rows) {
                    if (rows.isEmpty) {
                      return PEmptySectionPlaceholder(subtitle: 'health.activityData.empty'.tr());
                    }
                    return Column(
                      children: [
                        for (final r in rows) ...[
                          _RecapCard(row: r),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

String _sourceLabel(String source) => switch (source) {
      'lobby' => 'health.source.lobby',
      'professional' => 'health.source.professional',
      _ => 'health.source.self',
    };

String _dateLabel(BuildContext context, DateTime dt) =>
    DateFormat.MMMEd(context.locale.toString()).format(dt);

// ─── Detected workout card ──────────────────────────────────────────────────

class _DetectedCard extends ConsumerStatefulWidget {
  final DetectedWorkout workout;
  const _DetectedCard({required this.workout});

  @override
  ConsumerState<_DetectedCard> createState() => _DetectedCardState();
}

class _DetectedCardState extends ConsumerState<_DetectedCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        showFToast(context: context, title: Text('health.error'.tr()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final w = widget.workout;
    final evidenceKey = w.evidence == HealthEvidence.high
        ? 'health.detected.evidenceHigh'
        : 'health.detected.evidenceMedium';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
        borderRadius: context.theme.style.borderRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(FIcons.activity, size: 18, color: colors.primary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      '${_dateLabel(context, w.startTime)} · ${_sourceLabel(w.source).tr()}',
                      style: context.theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      evidenceKey.tr(),
                      style: context.theme.typography.xs.copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_busy)
            const Center(child: Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator()))
          else
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FButton(
                    variant: .outline,
                    onPress: () => _run(() =>
                        ref.read(healthSyncControllerProvider.notifier).dismiss(w.activityId)),
                    child: Text('health.detected.dismiss'.tr()),
                  ),
                ),
                Expanded(
                  child: FButton(
                    onPress: () => _run(() async {
                      final ok =
                          await ref.read(healthSyncControllerProvider.notifier).attach(w);
                      if (!context.mounted) return;
                      if (ok) {
                        showFToast(context: context, title: Text('health.detected.attached'.tr()));
                      }
                    }),
                    child: Text('health.detected.attach'.tr()),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Recap card ───────────────────────────────────────────────────────────────

class _RecapCard extends StatelessWidget {
  final ActivityHealthRow row;
  const _RecapCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final subtitle = [
      _sourceLabel(row.source).tr(),
      if (row.locationLabel != null) row.locationLabel!,
    ].join(' · ');

    return GestureDetector(
      onTap: () => showActivityRecapSheet(context, row),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.border),
          borderRadius: context.theme.style.borderRadius.md,
          boxShadow: context.theme.style.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        _dateLabel(context, row.startTime),
                        style: context.theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        style: context.theme.typography.xs.copyWith(color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                Icon(FIcons.chevronRight, size: 18, color: colors.mutedForeground),
              ],
            ),
            Row(
              spacing: 16,
              children: [
                if (row.durationMinutes != null)
                  _MiniStat(value: _duration(row.durationMinutes!), label: 'health.recap.duration'.tr()),
                if (row.avgHeartRate != null)
                  _MiniStat(value: '${row.avgHeartRate}', label: 'health.recap.avgHr'.tr()),
                if (row.activeCalories != null)
                  _MiniStat(value: '${row.activeCalories!.round()}', label: 'health.recap.calories'.tr()),
              ],
            ),
            if ((row.hrZoneEasySeconds ?? 0) +
                    (row.hrZoneModerateSeconds ?? 0) +
                    (row.hrZoneHardSeconds ?? 0) >
                0)
              ZoneBar(
                easy: row.hrZoneEasySeconds ?? 0,
                moderate: row.hrZoneModerateSeconds ?? 0,
                hard: row.hrZoneHardSeconds ?? 0,
                compact: true,
              ),
          ],
        ),
      ),
    );
  }

  String _duration(int minutes) =>
      minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 1,
      children: [
        Text(
          value,
          style: context.theme.typography.md.copyWith(fontWeight: FontWeight.w700, height: 1),
        ),
        Text(
          label.toUpperCase(),
          style: context.theme.typography.xs.copyWith(
            color: colors.mutedForeground,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
