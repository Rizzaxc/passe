import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A horizontal line calendar that displays dates in a row with spaceBetween layout.
/// Automatically adjusts number of visible days based on screen width.
class PCalendar extends StatelessWidget {
  /// The start date of the calendar range.
  final DateTime start;

  /// Number of days to display.
  final int daysToShow;

  /// The currently selected date.
  final DateTime? selectedDate;

  /// Called when a date is selected.
  final ValueChanged<DateTime>? onDateSelected;

  /// Optional padding around the calendar.
  final EdgeInsetsGeometry padding;

  const PCalendar({
    required this.start,
    required this.daysToShow,
    this.selectedDate,
    this.onDateSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      daysToShow,
      (i) => start.add(Duration(days: i)),
    );
    final today = DateTime.now();

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final date in dates)
            _PCalendarTile(
              date: date,
              isSelected: _isSameDay(date, selectedDate),
              isToday: _isSameDay(date, today),
              onTap: onDateSelected != null ? () => onDateSelected!(date) : null,
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _PCalendarTile extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onTap;

  const _PCalendarTile({
    required this.date,
    required this.isSelected,
    required this.isToday,
    this.onTap,
  });

  static const _weekdayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final weekdayKey = _weekdayKeys[date.weekday - 1];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.background,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'timeslot.dayOfWeek.shortName.$weekdayKey'.tr(),
              style: typography.xs.copyWith(
                color: isSelected ? colors.primaryForeground : colors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date.day.toString(),
              style: typography.xl.copyWith(
                color: isSelected ? colors.primaryForeground : colors.primary,
                fontWeight: FontWeight.w500,
                decoration: isToday ? TextDecoration.underline : null,
                decorationColor: isSelected ? colors.primaryForeground : colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
