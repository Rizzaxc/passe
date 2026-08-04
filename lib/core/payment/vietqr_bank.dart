/// A bank or e-wallet from VietQR's own registry (`api.vietqr.io/v2/banks`),
/// with its app-deeplink info (`.../v2/android-app-deeplinks`,
/// `.../v2/ios-app-deeplinks`) folded in.
///
/// Hardcoded rather than fetched at runtime — keeps the picker instant and
/// offline. This is a deliberately small, low-maintenance list covering the
/// banks the vast majority of users have, not an exhaustive one. Every entry
/// below was fetched live from VietQR during planning (2026-08); `androidAppId`
/// and `iosAppId` were identical for every bank that had one, so `appId` is
/// exposed as a single field. `null` `appId` means VietQR has no registered
/// app-deeplink for that bank — it still gets a QR (via `bin`), just no
/// "open app" button.
class VietqrBank {
  /// VietQR bin — used to build the QR image URL and as `bank_id` in
  /// `user_payment_info`.
  final String bin;

  /// Display name shown in the UI and snapshotted as `bank_display_name`.
  final String shortName;

  final String logoUrl;

  /// App-deeplink id (`dl.vietqr.io/pay?app=<appId>`), if VietQR has one for
  /// this bank. Also doubles as the `<bankCode>` token in `ba=<account>@<bankCode>`
  /// — VietQR's own example deeplink uses the lowercase appId there.
  final String? appId;

  /// Whether tapping the deeplink pre-fills the recipient into the bank
  /// app's transfer form (vs. just opening the app to a blank screen).
  final bool autofill;

  const VietqrBank({
    required this.bin,
    required this.shortName,
    required this.logoUrl,
    this.appId,
    this.autofill = false,
  });
}

const List<VietqrBank> kVietqrBanks = [
  VietqrBank(
    bin: '970436',
    shortName: 'Vietcombank',
    logoUrl: 'https://cdn.vietqr.io/img/VCB.png',
    appId: 'vcb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970407',
    shortName: 'Techcombank',
    logoUrl: 'https://cdn.vietqr.io/img/TCB.png',
    appId: 'tcb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970422',
    shortName: 'MBBank',
    logoUrl: 'https://cdn.vietqr.io/img/MB.png',
    appId: 'mb',
    autofill: true,
  ),
  VietqrBank(
    bin: '970418',
    shortName: 'BIDV',
    logoUrl: 'https://cdn.vietqr.io/img/BIDV.png',
    appId: 'bidv',
    autofill: true,
  ),
  VietqrBank(
    bin: '970415',
    shortName: 'VietinBank',
    logoUrl: 'https://cdn.vietqr.io/img/ICB.png',
    appId: 'icb',
    autofill: true,
  ),
  VietqrBank(
    bin: '970416',
    shortName: 'ACB',
    logoUrl: 'https://cdn.vietqr.io/img/ACB.png',
    appId: 'acb',
    autofill: true,
  ),
  VietqrBank(
    bin: '970423',
    shortName: 'TPBank',
    logoUrl: 'https://cdn.vietqr.io/img/TPB.png',
    appId: 'tpb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970432',
    shortName: 'VPBank',
    logoUrl: 'https://cdn.vietqr.io/img/VPB.png',
    appId: 'vpb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970403',
    shortName: 'Sacombank',
    logoUrl: 'https://cdn.vietqr.io/img/STB.png',
    // No entry in VietQR's app-deeplink list — QR-only, no "open app" button.
  ),
  VietqrBank(
    bin: '970405',
    shortName: 'Agribank',
    logoUrl: 'https://cdn.vietqr.io/img/VBA.png',
    appId: 'vba',
    autofill: false,
  ),
  VietqrBank(
    bin: '970443',
    shortName: 'SHB',
    logoUrl: 'https://cdn.vietqr.io/img/SHB.png',
    appId: 'shb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970437',
    shortName: 'HDBank',
    logoUrl: 'https://cdn.vietqr.io/img/HDB.png',
    appId: 'hdb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970448',
    shortName: 'OCB',
    logoUrl: 'https://cdn.vietqr.io/img/OCB.png',
    appId: 'ocb',
    autofill: true,
  ),
  VietqrBank(
    bin: '970440',
    shortName: 'SeABank',
    logoUrl: 'https://cdn.vietqr.io/img/SEAB.png',
    appId: 'seab',
    autofill: false,
  ),
  VietqrBank(
    bin: '970441',
    shortName: 'VIB',
    logoUrl: 'https://cdn.vietqr.io/img/VIB.png',
    appId: 'vib',
    autofill: false,
  ),
  VietqrBank(
    bin: '970431',
    shortName: 'Eximbank',
    logoUrl: 'https://cdn.vietqr.io/img/EIB.png',
    appId: 'eib',
    autofill: false,
  ),
  VietqrBank(
    bin: '971025',
    shortName: 'MoMo',
    logoUrl: 'https://cdn.vietqr.io/img/momo.png',
    // MoMo is a transfer-enabled VietQR entity (bin above) but has no entry
    // in VietQR's app-deeplink list — QR + copy only, no "open app" button.
  ),
];

VietqrBank? vietqrBankByBin(String bin) {
  for (final bank in kVietqrBanks) {
    if (bank.bin == bin) return bank;
  }
  return null;
}
