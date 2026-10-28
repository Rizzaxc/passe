import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import 'sheet.dart';

/// The card-row vocabulary of the session scheduler ("Lên Lịch Buổi Chơi"),
/// shared so every form that schedules something — a session, a challenge
/// offer — reads as the same form. Each row is a bordered card on its own;
/// [PFormSection] stacks them under an uppercase section label.

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
  color: context.theme.colors.card,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: context.theme.colors.border),
);

/// A [PSheetSectionLabel] over its rows, 8 px apart.
class PFormSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const PFormSection({super.key, required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PSheetSectionLabel(label: label),
        const SizedBox(height: 8),
        ...List.generate(children.length, (i) {
          if (i == 0) return children[i];
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: children[i],
          );
        }),
      ],
    );
  }
}

/// "icon  label / sub ……… value ›" — opens a picker.
class PPickerRow extends StatelessWidget {
  final IconData icon;
  final String label;

  /// A muted line under the label, e.g. what the chosen value means.
  final String? sub;
  final String value;
  final VoidCallback onTap;

  const PPickerRow({
    super.key,
    required this.icon,
    required this.label,
    this.sub,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTappable(
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _cardDecoration(context),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.secondaryForeground),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: context.theme.typography.body.sm.copyWith(
                  color: colors.secondaryForeground,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              FLucideIcons.chevronRight,
              size: 16,
              color: colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

/// "icon  label / sub ……… switch".
class PSwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// True locks the switch at its current value, dimmed and non-interactive.
  final bool locked;

  const PSwitchRow({
    super.key,
    required this.icon,
    required this.label,
    this.sub,
    required this.value,
    required this.onChanged,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.secondaryForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Opacity(
            opacity: locked ? 0.5 : 1,
            child: FSwitch(value: value, onChange: locked ? null : onChanged),
          ),
        ],
      ),
    );
  }
}

/// The slider row: "icon  label / caption ……… [slider] value" — the same
/// single-row shape as [PPickerRow] and [PSwitchRow], with a compact slider
/// as the input. The [caption] says what the value works out to.
class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valueLabel;
  final String? caption;
  final double fraction;
  final bool enabled;
  final ValueChanged<double> onFraction;

  const _SliderRow({
    required this.icon,
    required this.label,
    required this.valueLabel,
    required this.caption,
    required this.fraction,
    required this.enabled,
    required this.onFraction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.secondaryForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: FSlider(
              enabled: enabled,
              control: FSliderControl.liftedContinuous(
                value: FSliderValue(max: fraction),
                onChange: (v) => onFraction(v.max),
              ),
              // The value is already printed beside the track.
              tooltipControls: const .disabled(),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            child: Text(
              valueLabel,
              textAlign: TextAlign.end,
              maxLines: 1,
              style: typography.body.sm.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "1h30", "2h", "30p" — how a session length is written everywhere,
/// compact enough for the value slot beside a slider.
String formatSessionLength(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return 'durationMinutes'.tr(namedArgs: {'count': '$m'});
  return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
}

/// Session length picked on a slider between [min] and [max], snapped to
/// [step]. [caption] typically names the resulting end time.
class PDurationSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final Duration value;
  final Duration min;
  final Duration max;
  final Duration step;
  final String? caption;
  final ValueChanged<Duration> onChanged;

  const PDurationSlider({
    super.key,
    this.icon = FLucideIcons.timer,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = const Duration(minutes: 30),
    this.caption,
    required this.onChanged,
  });

  Duration _at(double fraction) {
    final range = (max - min).inMinutes;
    final raw = min.inMinutes + fraction * range;
    final snapped = (raw / step.inMinutes).round() * step.inMinutes;
    return Duration(minutes: snapped.clamp(min.inMinutes, max.inMinutes));
  }

  @override
  Widget build(BuildContext context) {
    final range = (max - min).inMinutes;
    final fraction = range <= 0
        ? 0.0
        : ((value - min).inMinutes / range).clamp(0.0, 1.0);
    return _SliderRow(
      icon: icon,
      label: label,
      valueLabel: formatSessionLength(value),
      caption: caption,
      fraction: fraction,
      enabled: range > 0,
      onFraction: (f) {
        final picked = _at(f);
        if (picked != value) onChanged(picked);
      },
    );
  }
}

/// "How long before kickoff", snapped to a handful of [stops] (hours) between
/// [minHours] and [maxHours] — the scheduler's confirmation cutoff, and a
/// challenge offer's closing time. A current value that isn't a stop (an
/// edited session, or a cap that fell between stops) is kept as one.
class PLeadSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double hours;
  final int minHours;
  final double maxHours;
  final List<int> stops;
  final String? caption;
  final ValueChanged<double> onChanged;

  const PLeadSlider({
    super.key,
    this.icon = FLucideIcons.alarmClock,
    required this.label,
    required this.hours,
    required this.minHours,
    required this.maxHours,
    this.stops = const [2, 6, 12, 24, 36, 48, 72],
    this.caption,
    required this.onChanged,
  });

  static String formatLead(double h) {
    final rounded = h.round();
    if (rounded % 24 == 0) {
      final days = rounded ~/ 24;
      return 'lobbyHub.schedule.leadDays'.tr(namedArgs: {'count': '$days'});
    }
    return 'lobbyHub.schedule.leadHours'.tr(namedArgs: {'count': '$rounded'});
  }

  List<double> get _values {
    final values = [
      for (final h in stops)
        if (h >= minHours && h <= maxHours) h.toDouble(),
    ];
    if (!values.contains(hours)) {
      values
        ..add(hours)
        ..sort();
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final values = _values;
    final last = values.length - 1;
    return _SliderRow(
      icon: icon,
      label: label,
      valueLabel: formatLead(hours),
      caption: caption,
      fraction: last <= 0 ? 0 : values.indexOf(hours) / last,
      enabled: last > 0,
      onFraction: (f) {
        if (last <= 0) return;
        final picked = values[(f * last).round()];
        if (picked != hours) onChanged(picked);
      },
    );
  }
}

/// Inline forui line calendar over today … today + [maxDays] — the whole
/// horizon fits a swipe, so a modal date picker is an extra step for nothing.
class PDateStrip extends StatelessWidget {
  final DateTime date;
  final int maxDays;
  final ValueChanged<DateTime> onChanged;

  const PDateStrip({
    super.key,
    required this.date,
    required this.maxDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // forui calendars work in UTC-midnight dates; convert at the edges.
    final today = DateTime.utc(now.year, now.month, now.day);
    final last = today.add(Duration(days: maxDays));
    final selected = DateTime.utc(date.year, date.month, date.day);

    return SizedBox(
      height: 72,
      child: FLineCalendar(
        control: .lifted(
          date: selected,
          onChange: (d) {
            if (d != null) onChanged(DateTime(d.year, d.month, d.day));
          },
        ),
        scrollControl: .managed(
          start: today,
          end: last,
          today: today,
          initialDate: selected,
        ),
        selectable: (d) => !d.isBefore(today) && !d.isAfter(last),
      ),
    );
  }
}

/// forui wheel time picker in a sheet, replacing Material's dial. Returns
/// null when dismissed.
Future<TimeOfDay?> showPTimePicker(
  BuildContext context, {
  required TimeOfDay initial,
  required String title,
}) {
  return showPSheet<TimeOfDay>(
    context: context,
    builder: (_) => _TimePickerSheet(initial: initial, title: title),
  );
}

class _TimePickerSheet extends StatefulWidget {
  final TimeOfDay initial;
  final String title;

  const _TimePickerSheet({required this.initial, required this.title});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late FTime _time = FTime(widget.initial.hour, widget.initial.minute);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        PSheetTitle(
          label: widget.title,
          trailing: FButton.icon(
            variant: .ghost,
            onPress: () => Navigator.of(context).pop(),
            child: const Icon(FLucideIcons.x),
          ),
        ),
        SizedBox(
          height: 180,
          child: FTimePicker(
            hour24: true,
            minuteInterval: 5,
            control: .lifted(
              time: _time,
              onChange: (t) => setState(() => _time = t),
            ),
          ),
        ),
        FButton(
          onPress: () => Navigator.of(
            context,
          ).pop(TimeOfDay(hour: _time.hour, minute: _time.minute)),
          child: Text('done'.tr()),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// "icon  label / amount in words ……… [ 300000 ] đ" — an amount typed into a
/// compact field on the right, read back in words underneath the label so a
/// missing zero is caught before it's saved.
class PAmountRow extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;
  final String suffix;

  const PAmountRow({
    super.key,
    required this.controller,
    this.icon = FLucideIcons.banknote,
    required this.label,
    this.hint = '50000',
    this.suffix = 'đ',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.secondaryForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedBuilder(
                  animation: controller,
                  builder: (_, _) {
                    final amount = num.tryParse(controller.text.trim());
                    return Text(
                      amount == null || amount < 0
                          ? 'lobbyHub.common.enterAmountReading'.tr()
                          : formatVndWords(amount),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                        height: 1.4,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: FTextField(
              hint: hint,
              textAlign: TextAlign.end,
              control: FTextFieldControl.managed(controller: controller),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            suffix,
            style: typography.body.sm.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.secondaryForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// "icon  label / sub ……… −  4  +" — a small whole number.
class PStepperRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const PStepperRow({
    super.key,
    required this.icon,
    required this.label,
    this.sub,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.secondaryForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          _StepperButton(
            icon: FLucideIcons.minus,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: typography.body.lg.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.foreground,
              ),
            ),
          ),
          _StepperButton(
            icon: FLucideIcons.plus,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final enabled = onTap != null;
    return FTappable(
      onPress: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? colors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 14,
          color: enabled ? colors.foreground : colors.mutedForeground,
        ),
      ),
    );
  }
}

/// Pick one of [options] from a sheet of card rows, each with an optional
/// [description] — the destination of a [PPickerRow] whose choices need more
/// than a word to tell apart. Returns null when dismissed.
Future<T?> showPOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T) label,
  String? Function(T)? description,
}) {
  return showPSheet<T>(
    context: context,
    builder: (sheetContext) {
      final colors = sheetContext.theme.colors;
      final typography = sheetContext.theme.typography;
      return SingleChildScrollView(
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            PSheetTitle(
              label: title,
              trailing: FButton.icon(
                variant: .ghost,
                onPress: () => Navigator.of(sheetContext).pop(),
                child: const Icon(FLucideIcons.x),
              ),
            ),
            for (final o in options)
              FTappable(
                onPress: () => Navigator.of(sheetContext).pop(o),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: o == selected
                        ? colors.primary.withValues(alpha: 0.06)
                        : colors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: o == selected ? colors.primary : colors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label(o),
                              style: typography.body.sm.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (description?.call(o) case final d?) ...[
                              const SizedBox(height: 2),
                              Text(
                                d,
                                style: typography.body.xs.copyWith(
                                  color: colors.mutedForeground,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (o == selected) ...[
                        const SizedBox(width: 8),
                        Icon(
                          FLucideIcons.check,
                          size: 18,
                          color: colors.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
