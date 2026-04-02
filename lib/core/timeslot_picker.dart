import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'model/enum.dart';
import 'model/timeslot.dart';

/// Shows a timeslot picker sheet and returns the selected timeslot
Future<Timeslot?> showTimeslotPicker({
  required BuildContext context,
  Timeslot? initialTimeslot,
}) async {
  Timeslot? selectedTimeslot = initialTimeslot;

  return showFSheet<Timeslot>(
    context: context,
    useSafeArea: true,
    useRootNavigator: true,
    constraints: BoxConstraints(minWidth: double.infinity),
    side: .btt,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: context.theme.colors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.symmetric(
          horizontal: BorderSide(color: context.theme.colors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TimeslotPicker(
                initialTimeslot: initialTimeslot,
                onChanged: (timeslot) {
                  selectedTimeslot = timeslot;
                },
              ),
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: () => Navigator.of(context).pop(selectedTimeslot),
              // child: Text('OK'),
              child: const Icon(FIcons.check),
            ),
          ],
        ),
      ),
    ),
  );
}

class TimeslotPicker extends StatefulWidget {
  final Timeslot? initialTimeslot;
  final ValueChanged<Timeslot>? onChanged;

  const TimeslotPicker({super.key, this.initialTimeslot, this.onChanged});

  @override
  State<TimeslotPicker> createState() => _TimeslotPickerState();
}

class _TimeslotPickerState extends State<TimeslotPicker> {
  late int _dayOfWeekIndex;
  late int _dayChunkIndex;

  @override
  void initState() {
    super.initState();
    _dayOfWeekIndex = widget.initialTimeslot != null
        ? DayOfWeek.values.indexOf(widget.initialTimeslot!.dayOfWeek)
        : 10; // default to Weekend
    _dayChunkIndex = widget.initialTimeslot != null
        ? DayChunk.values.indexOf(widget.initialTimeslot!.dayChunk)
        : 3; // default to Evening
  }

  void _notifyChange() {
    final timeslot = Timeslot(
      DayOfWeek.values[_dayOfWeekIndex],
      DayChunk.values[_dayChunkIndex],
    );
    widget.onChanged?.call(timeslot);
  }

  /// Normalize index for looping wheels - handles negative and overflow values
  int _normalizeIndex(int index, int length) {
    return ((index % length) + length) % length;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day Chunk picker
          Expanded(
            flex: 5,
            child: FPicker(
              control: FPickerControl.managed(
                initial: [_dayChunkIndex],
                onChange: (indexes) {
                  setState(() {
                    // Clamp for non-looping wheel
                    _dayChunkIndex = indexes[0].clamp(
                      0,
                      DayChunk.values.length - 1,
                    );
                    _notifyChange();
                  });
                },
              ),
              children: [
                FPickerWheel(
                  loop: false,
                  children: DayChunk.values
                      .map(
                        (chunk) => Center(
                          child: Text(
                            chunk.getFullName(context),
                            style: context.theme.typography.md,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          // Separator
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '-',
                style: context.theme.typography.xl.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ),
          ),

          // Day of Week picker
          Expanded(
            flex: 6,
            child: FPicker(
              control: FPickerControl.managed(
                initial: [_dayOfWeekIndex],
                onChange: (indexes) {
                  setState(() {
                    // Normalize for looping wheel
                    _dayOfWeekIndex = _normalizeIndex(
                      indexes[0],
                      DayOfWeek.values.length,
                    );
                    _notifyChange();
                  });
                },
              ),
              children: [
                FPickerWheel(
                  loop: true,
                  autofocus: true,
                  children: DayOfWeek.values
                      .map(
                        (day) => Center(
                          child: Text(
                            day.getFullName(context),
                            style: context.theme.typography.md,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
