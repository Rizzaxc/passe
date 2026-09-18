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
import 'recap_widgets.dart';
import 'zone_bar.dart';

class ActivityDataSubtab extends ConsumerWidget {
  const ActivityDataSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sport = ref.watch(selectedSportStateProvider).value;
    final detected = ref.watch(detectedWorkoutsProvider);
    final recaps = ref.watch(activityHealthListProvider);
    final sportCounts = ref.watch(activityHealthSportCountsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activityHealthListProvider);
        ref.invalidate(detectedWorkoutsProvider);
        ref.invalidate(activityHealthSportCountsProvider);
        await ref.read(activityHealthListProvider.future);
      },
      child: (sport == null || sport == Sport.others)
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                PEmptySectionPlaceholder(
                  subtitle: 'health.activityData.selectSport'.tr(),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                      final hint = sportCounts.maybeWhen(
                        data: (counts) => _bestOtherSport(counts, sport),
                        orElse: () => null,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (hint != null) ...[
                            _OtherSportHint(sport: hint.$1, count: hint.$2),
                            const SizedBox(height: 10),
                          ],
                          const _SampleRecapCard(),
                        ],
                      );
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
      style: context.theme.typography.body.sm.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Weekday + month + day — used only by [_DetectedCard], where a review card
/// benefits from the extra precision of the raw calendar date. The recap
/// card/sheet *titles* use [cardTitleDateLabel] instead.
///
/// [dt] is UTC (Supabase `timestamptz` via `DateTime.parse`) — `.toLocal()`
/// first or the date can land on the wrong day for the device's timezone.
String _dateLabel(BuildContext context, DateTime dt) =>
    DateFormat.MMMEd(context.locale.toString()).format(dt.toLocal());

/// The other sport with the most reports, excluding [current] — so a user
/// viewing an empty recap list for one sport can be pointed at reports
/// filed under a different one instead of it looking identical to "never
/// synced". `null` when there's nothing else to point at.
(Sport, int)? _bestOtherSport(Map<Sport, int> counts, Sport current) {
  (Sport, int)? best;
  for (final entry in counts.entries) {
    if (entry.key == current || entry.value <= 0) continue;
    if (best == null || entry.value > best.$2) best = (entry.key, entry.value);
  }
  return best;
}

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
              Icon(FLucideIcons.activity, size: 18, color: colors.primary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      '${_dateLabel(context, w.startTime)} · ${sourceLabelKey(w.source).tr()}',
                      style: context.theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      evidenceKey.tr(),
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FButton(
                    variant: .outline,
                    onPress: () => _run(
                      () => ref
                          .read(healthSyncControllerProvider.notifier)
                          .dismiss(w.activityId),
                    ),
                    child: Text('health.detected.dismiss'.tr()),
                  ),
                ),
                Expanded(
                  child: FButton(
                    onPress: () => _run(() async {
                      final ok = await ref
                          .read(healthSyncControllerProvider.notifier)
                          .attach(w);
                      if (!context.mounted) return;
                      if (ok) {
                        showFToast(
                          context: context,
                          title: Text('health.detected.attached'.tr()),
                        );
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

// ─── Other-sport hint (shown above the sample card when empty) ────────────────

/// Points at reports filed under a different sport when the context sport's
/// recap list is empty but another sport has real data. Tapping switches the
/// context sport directly rather than making the user go find the selector.
class _OtherSportHint extends ConsumerWidget {
  final Sport sport;
  final int count;
  const _OtherSportHint({required this.sport, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          ref.read(selectedSportStateProvider.notifier).change(sport),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.secondary,
          borderRadius: context.theme.style.borderRadius.md,
        ),
        child: Row(
          spacing: 8,
          children: [
            Icon(FLucideIcons.arrowRightLeft, size: 16, color: colors.primary),
            Expanded(
              child: Text(
                'health.activityData.otherSportHint'.plural(
                  count,
                  namedArgs: {'sport': sport.getLocalizedName(context)},
                ),
                style: context.theme.typography.body.sm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sample recap (shown in place of the empty state) ──────────────────────────

/// A dimmed, non-interactive stand-in for `_RecapCard` so a first-time user
/// sees the real recap layout instead of a blank message.
class _SampleRecapCard extends StatelessWidget {
  const _SampleRecapCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: 0.45,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                border: Border.all(color: colors.border),
                borderRadius: context.theme.style.borderRadius.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: [
                  Row(
                    spacing: 12,
                    children: [
                      ActivityIconBadge(colors: colors),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Row(
                              spacing: 6,
                              children: [
                                Text(
                                  'health.activityData.sample.session'.tr(),
                                  style: context.theme.typography.body.sm
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                _PreviewChip(colors: colors),
                              ],
                            ),
                            Text(
                              'health.source.self'.tr(),
                              style: context.theme.typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        FLucideIcons.chevronRight,
                        size: 18,
                        color: colors.mutedForeground,
                      ),
                    ],
                  ),
                  Divider(height: 1, color: colors.border),
                  Wrap(
                    spacing: 18,
                    runSpacing: 10,
                    children: [
                      StatChip(icon: FLucideIcons.timer, value: '45m'),
                      StatChip(
                        icon: FLucideIcons.heartPulse,
                        value: '132',
                        unit: 'bpm',
                      ),
                      StatChip(
                        icon: FLucideIcons.flame,
                        value: '410',
                        unit: 'kcal',
                      ),
                    ],
                  ),
                  Text(
                    'health.recap.zones'.tr().toUpperCase(),
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const ZoneBar(
                    easy: 600,
                    moderate: 1200,
                    hard: 900,
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          spacing: 6,
          children: [
            Icon(
              FLucideIcons.sparkles,
              size: 14,
              color: colors.mutedForeground,
            ),
            Expanded(
              child: Text(
                'health.activityData.sample.caption'.tr(),
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final FColors colors;
  const _PreviewChip({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'health.activityData.sample.label'.tr().toUpperCase(),
        style: context.theme.typography.body.xs.copyWith(
          color: colors.mutedForeground,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          letterSpacing: 0.3,
        ),
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
    final totalZoneSeconds =
        (row.hrZoneEasySeconds ?? 0) +
        (row.hrZoneModerateSeconds ?? 0) +
        (row.hrZoneHardSeconds ?? 0);

    return GestureDetector(
      onTap: () => showActivityRecapSheet(context, row),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.border),
          borderRadius: context.theme.style.borderRadius.md,
          boxShadow: context.theme.style.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Row(
              spacing: 12,
              children: [
                SourceAvatar(row: row),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        cardTitleDateLabel(context, row.startTime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SourceLocationLines(
                        source: row.source,
                        sourceName: row.sourceName,
                        locationLabel: row.locationLabel,
                        style: context.theme.typography.body.xs.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  FLucideIcons.chevronRight,
                  size: 18,
                  color: colors.mutedForeground,
                ),
              ],
            ),
            Divider(height: 1, color: colors.border),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                if (row.durationMinutes != null)
                  StatChip(
                    icon: FLucideIcons.timer,
                    value: _duration(row.durationMinutes!),
                  ),
                if (row.avgHeartRate != null)
                  StatChip(
                    icon: FLucideIcons.heartPulse,
                    value: '${row.avgHeartRate}',
                    unit: 'bpm',
                  ),
                if (row.activeCalories != null)
                  StatChip(
                    icon: FLucideIcons.flame,
                    value: '${row.activeCalories!.round()}',
                    unit: 'kcal',
                  ),
                if (row.steps != null && row.steps! > 0)
                  StatChip(
                    icon: FLucideIcons.footprints,
                    value: '${row.steps}',
                    unit: 'health.recap.steps'.tr(),
                  ),
                if (row.distanceMeters != null && row.distanceMeters! > 0)
                  StatChip(
                    icon: FLucideIcons.route,
                    value: _distance(row.distanceMeters!),
                  ),
              ],
            ),
            if (totalZoneSeconds > 0) ...[
              Text(
                'health.recap.zones'.tr().toUpperCase(),
                style: context.theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              ZoneBar(
                easy: row.hrZoneEasySeconds ?? 0,
                moderate: row.hrZoneModerateSeconds ?? 0,
                hard: row.hrZoneHardSeconds ?? 0,
                compact: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _duration(int minutes) =>
      minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';

  String _distance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.round()} m';
}
