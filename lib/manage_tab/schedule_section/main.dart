import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/calendar.dart';
import '../../ui/empty_section_placeholder.dart';

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
      return PEmptySectionPlaceholder(
        subtitle: 'manageTab.schedule.selectDate'.tr(),
      );
    }

    return PEmptySectionPlaceholder(
      hero: Icon(FIcons.calendar, size: 48, color: context.theme.colors.mutedForeground),
      title: DateFormat.yMMMMd().format(selectedDate!),
      subtitle: 'manageTab.schedule.stub'.tr(),
    );
  }
}
