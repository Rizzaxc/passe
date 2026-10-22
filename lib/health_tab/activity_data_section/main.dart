import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/model/enum.dart';
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
    final detected = ref.watch(detectedWorkoutsProvider);
    final recaps = ref.watch(activityHealthListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activityHealthListProvider);
        ref.invalidate(detectedWorkoutsProvider);
        await ref.read(activityHealthListProvider.future);
      },
      child: ListView(
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
                    if (rows.isEmpty) return const _SampleRecapCard();
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
                // The sport, not the lobby: the list spans every sport, and
                // which lobby/coach it was with is the subtitle line (and the
                // recap sheet's source row) already.
                _SportAvatar(sportId: row.sportId, row: row),
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
                // The session's headline number, readable without opening it.
                if (row.effortScore != null) _EffortBadge(score: row.effortScore!),
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

/// A recap's leading glyph: its sport in a soft circle. Falls back to the
/// source avatar only for rows from an RPC old enough to lack `sport_id`.
class _SportAvatar extends StatelessWidget {
  final int? sportId;
  final ActivityHealthRow row;

  const _SportAvatar({required this.sportId, required this.row});

  static const _size = 36.0;

  @override
  Widget build(BuildContext context) {
    final id = sportId;
    if (id == null || id <= 0 || id >= Sport.values.length) {
      return SourceAvatar(row: row, size: _size);
    }
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.theme.colors.secondary,
        shape: BoxShape.circle,
      ),
      // getIcon takes a radius: 11 → a 22-pt glyph inside the 36-pt disc.
      child: Sport.values[id].getIcon(size: 11),
    );
  }
}

/// Effort Score (0–100) as a compact pill beside the card's chevron.
class _EffortBadge extends StatelessWidget {
  final double score;

  const _EffortBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Semantics(
      label: '${'health.recap.effort'.tr()} ${score.round()}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            Icon(FLucideIcons.zap, size: 13, color: colors.primary),
            Text(
              '${score.round()}',
              style: context.theme.typography.body.sm.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
