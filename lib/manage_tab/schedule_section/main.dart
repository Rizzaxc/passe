import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/calendar.dart';

class ScheduleSection extends StatefulWidget {
  const ScheduleSection({super.key});

  @override
  State<ScheduleSection> createState() => _ScheduleSectionState();
}

class _ScheduleSectionState extends State<ScheduleSection> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final breakpoints = context.theme.breakpoints;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < breakpoints.sm;
    final daysToShow = isPhone ? 5 : 7;

    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        PCalendar(
          start: yesterday,
          daysToShow: daysToShow,
          selectedDate: _selectedDate,
          onDateSelected: (date) => setState(() => _selectedDate = date),
        ),
        _ScheduleBody(selectedDate: _selectedDate),
      ],
    );
  }
}

class _ScheduleBody extends StatelessWidget {
  final DateTime? selectedDate;

  const _ScheduleBody({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    if (selectedDate == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'manageTab.schedule.selectDate'.tr(),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FIcons.calendar,
            size: 48,
            color: context.theme.colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat.yMMMMd().format(selectedDate!),
            style: context.theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'manageTab.schedule.stub'.tr(),
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
