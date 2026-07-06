/// Groups a numeric amount with `.` thousands separators (Vietnamese
/// currency style), e.g. `350000` -> `"350.000"`.
String formatVnd(double amount) {
  final digits = amount.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return buf.toString();
}
