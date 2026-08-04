import 'vietqr_bank.dart';

/// Builds the public VietQR quick-link image URL for a transfer target.
///
/// No API key required (`img.vietqr.io`'s quick-link endpoint is public) —
/// see the Context section of the payment-info plan for the research behind
/// this. [amount]/[note] are optional so the same builder covers both a
/// static profile display (no amount) and a prefilled "pay host"/"pay coach"
/// flow (amount + note set).
String buildVietqrImageUrl({
  required String bankId,
  required String accountNo,
  String? accountName,
  num? amount,
  String? note,
}) {
  final uri = Uri.https('img.vietqr.io', '/image/$bankId-$accountNo-compact2.png', {
    if (accountName != null && accountName.isNotEmpty) 'accountName': accountName,
    if (amount != null) 'amount': amount.round().toString(),
    if (note != null && note.isNotEmpty) 'addInfo': note,
  });
  return uri.toString();
}

/// Builds VietQR's app-deeplink redirector URL
/// (`https://dl.vietqr.io/pay?app=...`) for opening the bank's own app
/// directly, if that bank has a registered deeplink for the current
/// platform. Returns null when it doesn't — the caller should hide the
/// "open app" action in that case rather than show a dead button.
Uri? buildVietqrAppDeeplink({
  required VietqrBank bank,
  required String accountNo,
  String? accountName,
  num? amount,
  String? note,
}) {
  final appId = bank.appId;
  if (appId == null) return null;

  return Uri.https('dl.vietqr.io', '/pay', {
    'app': appId,
    'ba': '$accountNo@$appId',
    if (accountName != null && accountName.isNotEmpty) 'bn': accountName,
    if (amount != null) 'am': amount.round().toString(),
    if (note != null && note.isNotEmpty) 'tn': note,
  });
}
