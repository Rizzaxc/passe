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
/// (`https://dl.vietqr.io/pay?app=...`) that opens [openWith] — the
/// *sender's* own banking app, not necessarily the recipient's — prefilled
/// to transfer into [beneficiaryBank]'s account. `app` picks which app gets
/// opened (requires [VietqrBank.appId]); the `ba` beneficiary token is
/// [beneficiaryBank]'s [VietqrBank.bankCode] regardless of which app that
/// is, so paying a Vietcombank — or MoMo — recipient by opening your own
/// Techcombank app still lands the money in the right place. Returns null
/// when [openWith] has no registered app-deeplink id — the caller should
/// hide the "open app" action in that case rather than show a dead button.
Uri? buildVietqrAppDeeplink({
  required VietqrBank openWith,
  required VietqrBank beneficiaryBank,
  required String accountNo,
  String? accountName,
  num? amount,
  String? note,
}) {
  final appId = openWith.appId;
  if (appId == null) return null;

  return Uri.https('dl.vietqr.io', '/pay', {
    'app': appId,
    'ba': '$accountNo@${beneficiaryBank.bankCode}',
    if (accountName != null && accountName.isNotEmpty) 'bn': accountName,
    if (amount != null) 'am': amount.round().toString(),
    if (note != null && note.isNotEmpty) 'tn': note,
  });
}
