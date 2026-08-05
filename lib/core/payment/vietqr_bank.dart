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
/// "open app" button for it as an *opener*. MoMo (a wallet, not a bank) is a
/// fully transfer-supported VietQR beneficiary all the same — interbank
/// wires and other banking apps can pay into a MoMo number just like a real
/// bank account, confirmed via `transferSupported: 1` on its `api.vietqr.io`
/// entry — so it needs no special-casing on the *receiving* side.
class VietqrBank {
  /// VietQR bin — used to build the QR image URL and as `bank_id` in
  /// `user_payment_info`.
  final String bin;

  /// Display name shown in the UI and snapshotted as `bank_display_name`.
  final String shortName;

  final String logoUrl;

  /// VietQR's own short transfer code (`api.vietqr.io`'s `code` field,
  /// lowercased) for this bank/wallet as a *beneficiary* — the `<bankCode>`
  /// token in `ba=<account>@<bankCode>`. Every VietQR-transfer-supported
  /// entity has one, including MoMo (`'momo'`), independent of whether it
  /// also has an [appId].
  final String bankCode;

  /// App-deeplink id (`dl.vietqr.io/pay?app=<appId>`), if VietQR has one for
  /// this bank — i.e. whether *this* bank/wallet can itself be the app that
  /// `dl.vietqr.io/pay` opens. Unrelated to whether it can receive a
  /// transfer (see [bankCode]): a sender picks their *own* bank as their
  /// preferred sending app (see `PreferredSendingBankState`), so only banks
  /// with a non-null [appId] are selectable there. `null` means VietQR has
  /// no registered app-deeplink for it (currently Sacombank and MoMo) — it's
  /// still payable via QR/interbank transfer, just not selectable as an
  /// "open app" target itself.
  final String? appId;

  /// Whether tapping the deeplink pre-fills the recipient into the bank
  /// app's transfer form (vs. just opening the app to a blank screen).
  final bool autofill;

  const VietqrBank({
    required this.bin,
    required this.shortName,
    required this.logoUrl,
    required this.bankCode,
    this.appId,
    this.autofill = false,
  });
}

const List<VietqrBank> kVietqrBanks = [
  VietqrBank(
    bin: '970436',
    shortName: 'Vietcombank',
    logoUrl: 'https://cdn.vietqr.io/img/VCB.png',
    bankCode: 'vcb',
    appId: 'vcb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970407',
    shortName: 'Techcombank',
    logoUrl: 'https://cdn.vietqr.io/img/TCB.png',
    bankCode: 'tcb',
    appId: 'tcb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970422',
    shortName: 'MBBank',
    logoUrl: 'https://cdn.vietqr.io/img/MB.png',
    bankCode: 'mb',
    appId: 'mb',
    autofill: true,
  ),
  VietqrBank(
    bin: '970418',
    shortName: 'BIDV',
    logoUrl: 'https://cdn.vietqr.io/img/BIDV.png',
    bankCode: 'bidv',
    appId: 'bidv',
    autofill: true,
  ),
  VietqrBank(
    bin: '970415',
    shortName: 'VietinBank',
    logoUrl: 'https://cdn.vietqr.io/img/ICB.png',
    bankCode: 'icb',
    appId: 'icb',
    autofill: true,
  ),
  VietqrBank(
    bin: '970416',
    shortName: 'ACB',
    logoUrl: 'https://cdn.vietqr.io/img/ACB.png',
    bankCode: 'acb',
    appId: 'acb',
    autofill: true,
  ),
  VietqrBank(
    bin: '970423',
    shortName: 'TPBank',
    logoUrl: 'https://cdn.vietqr.io/img/TPB.png',
    bankCode: 'tpb',
    appId: 'tpb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970432',
    shortName: 'VPBank',
    logoUrl: 'https://cdn.vietqr.io/img/VPB.png',
    bankCode: 'vpb',
    appId: 'vpb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970403',
    shortName: 'Sacombank',
    logoUrl: 'https://cdn.vietqr.io/img/STB.png',
    bankCode: 'stb',
    // No entry in VietQR's app-deeplink list — not selectable as a "preferred
    // sending app", but still a normal payable beneficiary via QR/transfer.
  ),
  VietqrBank(
    bin: '970405',
    shortName: 'Agribank',
    logoUrl: 'https://cdn.vietqr.io/img/VBA.png',
    bankCode: 'vba',
    appId: 'vba',
    autofill: false,
  ),
  VietqrBank(
    bin: '970443',
    shortName: 'SHB',
    logoUrl: 'https://cdn.vietqr.io/img/SHB.png',
    bankCode: 'shb',
    appId: 'shb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970437',
    shortName: 'HDBank',
    logoUrl: 'https://cdn.vietqr.io/img/HDB.png',
    bankCode: 'hdb',
    appId: 'hdb',
    autofill: false,
  ),
  VietqrBank(
    bin: '970448',
    shortName: 'OCB',
    logoUrl: 'https://cdn.vietqr.io/img/OCB.png',
    bankCode: 'ocb',
    appId: 'ocb',
    autofill: true,
  ),
  VietqrBank(
    bin: '970440',
    shortName: 'SeABank',
    logoUrl: 'https://cdn.vietqr.io/img/SEAB.png',
    bankCode: 'seab',
    appId: 'seab',
    autofill: false,
  ),
  VietqrBank(
    bin: '970441',
    shortName: 'VIB',
    logoUrl: 'https://cdn.vietqr.io/img/VIB.png',
    bankCode: 'vib',
    appId: 'vib',
    autofill: false,
  ),
  VietqrBank(
    bin: '970431',
    shortName: 'Eximbank',
    logoUrl: 'https://cdn.vietqr.io/img/EIB.png',
    bankCode: 'eib',
    appId: 'eib',
    autofill: false,
  ),
  VietqrBank(
    bin: '971025',
    shortName: 'MoMo',
    logoUrl: 'https://cdn.vietqr.io/img/momo.png',
    bankCode: 'momo',
    // MoMo has no entry in VietQR's app-deeplink list, so it can't be picked
    // as a "preferred sending app" — but transferSupported:1 on its own
    // VietQR entry means it's a normal beneficiary otherwise: any sender's
    // own banking app can wire into it via bankCode above, same as a bank.
  ),
];

VietqrBank? vietqrBankByBin(String bin) {
  for (final bank in kVietqrBanks) {
    if (bank.bin == bin) return bank;
  }
  return null;
}
