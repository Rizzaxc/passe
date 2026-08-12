import 'package:number_to_vietnamese_words/number_to_vietnamese_words.dart';

const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// A match kickoff, Vietnamese-style: `"T7 12/9 · 18:00"`. Shared by every
/// surface that shows a challenge's agreed time (the offer control, the
/// challenger feed card, the challenges sheet, the referee's booking card) so
/// they can't drift apart.
String formatMatchDateTime(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day}/${d.month} · ${formatTimeOfDay(d)}';

/// Just the clock part, zero-padded: `"18:05"`.
String formatTimeOfDay(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Groups a numeric amount with `.` thousands separators (Vietnamese
/// currency style), e.g. `350000` -> `"350.000"`.
String formatVnd(num amount) {
  final digits = amount.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Reads a whole-VND amount in Vietnamese, e.g. `350000` becomes
/// `"Ba trăm năm mươi nghìn đồng"`. Money surfaces display absolute amounts;
/// their surrounding labels communicate who pays or receives.
String formatVndWords(num amount) =>
    '${amount.abs().round().toVietnameseWords()} đồng';
