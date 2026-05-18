import 'package:json_annotation/json_annotation.dart';

import 'enum.dart';

part 'timeslot.g.dart';

@JsonSerializable()
class Timeslot {
  final DayOfWeek dayOfWeek;
  final DayChunk dayChunk;

  Timeslot(this.dayOfWeek, this.dayChunk);

  // Factory constructor for deserialization
  factory Timeslot.fromJson(Map<String, dynamic> json) =>
      _$TimeslotFromJson(json);

  // Method for serialization
  Map<String, dynamic> toJson() => _$TimeslotToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Timeslot &&
        other.dayOfWeek == dayOfWeek &&
        other.dayChunk == dayChunk;
  }

  @override
  int get hashCode => dayOfWeek.hashCode ^ dayChunk.hashCode;

  // Helper method to expand composite days into individual days
  static List<DayOfWeek> _expandCompositeDays(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.everyday:
        return [
          DayOfWeek.monday,
          DayOfWeek.tuesday,
          DayOfWeek.wednesday,
          DayOfWeek.thursday,
          DayOfWeek.friday,
          DayOfWeek.saturday,
          DayOfWeek.sunday
        ];
      case DayOfWeek.even: // mon wed fri
        return [DayOfWeek.monday, DayOfWeek.wednesday, DayOfWeek.friday];
      case DayOfWeek.odd: // tue thu sat
        return [DayOfWeek.tuesday, DayOfWeek.thursday, DayOfWeek.saturday];
      case DayOfWeek.weekend: // sat sun
        return [DayOfWeek.saturday, DayOfWeek.sunday];
      default:
        return [day]; // Regular single day
    }
  }

  static Map<String, List<String>> listToJson(List<Timeslot> timeslots) {
    Map<DayOfWeek, Set<DayChunk>> mappedTimeslots = {};

    for (var slot in timeslots) {
      // Map composite days to individual days
      List<DayOfWeek> daysToAdd = _expandCompositeDays(slot.dayOfWeek);

      for (var day in daysToAdd) {
        if (!mappedTimeslots.containsKey(day)) {
          mappedTimeslots[day] = {};
        }

        mappedTimeslots[day]!.add(slot.dayChunk);
      }
    }

    Map<String, List<String>> result = {};

    mappedTimeslots.forEach((day, chunks) {
      String dayKey = _$DayOfWeekEnumMap[day]!;
      List<String> chunkValues =
      chunks.map((chunk) => _$DayChunkEnumMap[chunk]!).toList();
      result[dayKey] = chunkValues;
    });

    return result;
  }

  static List<Timeslot> listFromJson(Map<String, dynamic> json) {
    List<Timeslot> result = [];
    Map<DayOfWeek, Set<DayChunk>> consolidatedTimeslots = {};

    json.forEach((dayKey, chunks) {
      DayOfWeek? day;

      for (var entry in _$DayOfWeekEnumMap.entries) {
        if (entry.value == dayKey) {
          day = entry.key;
          break;
        }
      }

      if (day != null && chunks is List) {
        // Store each day and its chunks
        if (!consolidatedTimeslots.containsKey(day)) {
          consolidatedTimeslots[day] = {};
        }

        for (var chunkValue in chunks) {
          DayChunk? chunk;

          for (var entry in _$DayChunkEnumMap.entries) {
            if (entry.value == chunkValue) {
              chunk = entry.key;
              break;
            }
          }

          if (chunk != null) {
            consolidatedTimeslots[day]!.add(chunk);
          }
        }
      }
    });

    // Consolidate into composite days where possible
    _consolidateCompositeTimeslots(consolidatedTimeslots, result);

    return result;
  }

  static const everyDay = [
    DayOfWeek.monday,
    DayOfWeek.tuesday,
    DayOfWeek.wednesday,
    DayOfWeek.thursday,
    DayOfWeek.friday,
    DayOfWeek.saturday,
    DayOfWeek.sunday
  ];

  static const evenDays = [
    DayOfWeek.monday,
    DayOfWeek.wednesday,
    DayOfWeek.friday
  ];
  static const oddDays = [
    DayOfWeek.tuesday,
    DayOfWeek.thursday,
    DayOfWeek.saturday
  ];
  static const weekendDays = [DayOfWeek.saturday, DayOfWeek.sunday];

  // Helper method to consolidate days into composite entries where possible
  static void _consolidateCompositeTimeslots(
      Map<DayOfWeek, Set<DayChunk>> timeslotsMap, List<Timeslot> result) {
    // Check for everyday pattern (all 7 days with same chunks)
    if (_containsAllDays(timeslotsMap)) {
      Set<DayChunk> commonChunks = _findCommonChunks(timeslotsMap, everyDay);

      if (commonChunks.isNotEmpty) {
        for (var chunk in commonChunks) {
          result.add(Timeslot(DayOfWeek.everyday, chunk));
        }

        // Remove processed chunks from individual days
        for (var day in everyDay) {
          if (timeslotsMap.containsKey(day)) {
            timeslotsMap[day]!.removeAll(commonChunks);
            if (timeslotsMap[day]!.isEmpty) {
              timeslotsMap.remove(day);
            }
          }
        }
      }
    }

    // Check for even days (M-W-F)
    if (_containsAllDaysIn(timeslotsMap, evenDays)) {
      Set<DayChunk> commonChunks = _findCommonChunks(timeslotsMap, evenDays);

      if (commonChunks.isNotEmpty) {
        for (var chunk in commonChunks) {
          result.add(Timeslot(DayOfWeek.even, chunk));
        }

        // Remove processed chunks
        for (var day in evenDays) {
          if (timeslotsMap.containsKey(day)) {
            timeslotsMap[day]!.removeAll(commonChunks);
            if (timeslotsMap[day]!.isEmpty) {
              timeslotsMap.remove(day);
            }
          }
        }
      }
    }

    // Check for odd days (T-Th-S)
    if (_containsAllDaysIn(timeslotsMap, oddDays)) {
      Set<DayChunk> commonChunks = _findCommonChunks(timeslotsMap, oddDays);

      if (commonChunks.isNotEmpty) {
        for (var chunk in commonChunks) {
          result.add(Timeslot(DayOfWeek.odd, chunk));
        }

        // Remove processed chunks
        for (var day in oddDays) {
          if (timeslotsMap.containsKey(day)) {
            timeslotsMap[day]!.removeAll(commonChunks);
            if (timeslotsMap[day]!.isEmpty) {
              timeslotsMap.remove(day);
            }
          }
        }
      }
    }

    // Check for weekend (S-S)
    if (_containsAllDaysIn(timeslotsMap, weekendDays)) {
      Set<DayChunk> commonChunks = _findCommonChunks(timeslotsMap, weekendDays);
      if (commonChunks.isNotEmpty) {
        for (var chunk in commonChunks) {
          result.add(Timeslot(DayOfWeek.weekend, chunk));
        }

        // Remove processed chunks
        for (var day in weekendDays) {
          if (timeslotsMap.containsKey(day)) {
            timeslotsMap[day]!.removeAll(commonChunks);
            if (timeslotsMap[day]!.isEmpty) {
              timeslotsMap.remove(day);
            }
          }
        }
      }
    }

    // Add remaining individual days
    timeslotsMap.forEach((day, chunks) {
      for (var chunk in chunks) {
        result.add(Timeslot(day, chunk));
      }
    });
  }

  static bool _containsAllDays(Map<DayOfWeek, Set<DayChunk>> dayChunks) {
    return dayChunks.containsKey(DayOfWeek.monday) &&
        dayChunks.containsKey(DayOfWeek.tuesday) &&
        dayChunks.containsKey(DayOfWeek.wednesday) &&
        dayChunks.containsKey(DayOfWeek.thursday) &&
        dayChunks.containsKey(DayOfWeek.friday) &&
        dayChunks.containsKey(DayOfWeek.saturday) &&
        dayChunks.containsKey(DayOfWeek.sunday);
  }

  static bool _containsAllDaysIn(
      Map<DayOfWeek, Set<DayChunk>> dayChunks, List<DayOfWeek> days) {
    for (var day in days) {
      if (!dayChunks.containsKey(day)) return false;
    }
    return true;
  }

  static Set<DayChunk> _findCommonChunks(
      Map<DayOfWeek, Set<DayChunk>> dayChunks, List<DayOfWeek> days) {
    if (days.isEmpty) return {};

    Set<DayChunk>? commonChunks;

    for (var day in days) {
      if (!dayChunks.containsKey(day)) return {};

      if (commonChunks == null) {
        commonChunks = Set.from(dayChunks[day]!);
      } else {
        commonChunks = commonChunks.intersection(dayChunks[day]!);
      }

      if (commonChunks.isEmpty) return {};
    }

    return commonChunks ?? {};
  }
}
