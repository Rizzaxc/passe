// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferred_sending_bank_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The banking app the current user wants Passe to open when they tap
/// "Open in App" to pay someone — deliberately independent of whichever
/// bank/wallet the recipient uses. Only [VietqrBank]s with an [VietqrBank.appId]
/// are valid choices, since that's what makes an app deep-linkable.
///
/// Same persisted-state shape as `SelectedSportState`/`ProModeState`.

@ProviderFor(PreferredSendingBankState)
final preferredSendingBankStateProvider = PreferredSendingBankStateProvider._();

/// The banking app the current user wants Passe to open when they tap
/// "Open in App" to pay someone — deliberately independent of whichever
/// bank/wallet the recipient uses. Only [VietqrBank]s with an [VietqrBank.appId]
/// are valid choices, since that's what makes an app deep-linkable.
///
/// Same persisted-state shape as `SelectedSportState`/`ProModeState`.
final class PreferredSendingBankStateProvider
    extends $AsyncNotifierProvider<PreferredSendingBankState, VietqrBank?> {
  /// The banking app the current user wants Passe to open when they tap
  /// "Open in App" to pay someone — deliberately independent of whichever
  /// bank/wallet the recipient uses. Only [VietqrBank]s with an [VietqrBank.appId]
  /// are valid choices, since that's what makes an app deep-linkable.
  ///
  /// Same persisted-state shape as `SelectedSportState`/`ProModeState`.
  PreferredSendingBankStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferredSendingBankStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferredSendingBankStateHash();

  @$internal
  @override
  PreferredSendingBankState create() => PreferredSendingBankState();
}

String _$preferredSendingBankStateHash() =>
    r'4dc95725e6bfb9a5bdf40ad1443f37e3197c172f';

/// The banking app the current user wants Passe to open when they tap
/// "Open in App" to pay someone — deliberately independent of whichever
/// bank/wallet the recipient uses. Only [VietqrBank]s with an [VietqrBank.appId]
/// are valid choices, since that's what makes an app deep-linkable.
///
/// Same persisted-state shape as `SelectedSportState`/`ProModeState`.

abstract class _$PreferredSendingBankState extends $AsyncNotifier<VietqrBank?> {
  FutureOr<VietqrBank?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<VietqrBank?>, VietqrBank?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<VietqrBank?>, VietqrBank?>,
              AsyncValue<VietqrBank?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
