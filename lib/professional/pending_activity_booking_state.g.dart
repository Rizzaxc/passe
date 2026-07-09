// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_activity_booking_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One-shot hand-off for lobby-scoped booking: a captain/coordinator tapping
/// "Đặt HLV / Trọng tài" on an activity sets this to that activity's id
/// before navigating to professional discovery (there's no lobby-scoped
/// booking screen — the general discovery flow is reused, per the grill-me
/// decision). The booking sheet reads and immediately clears it on submit,
/// so it can only ever attach to the very next booking created — if the
/// user wanders off and books something unrelated first, that consumes and
/// clears the flag instead of misattaching a later one.

@ProviderFor(PendingActivityBookingState)
final pendingActivityBookingStateProvider =
    PendingActivityBookingStateProvider._();

/// One-shot hand-off for lobby-scoped booking: a captain/coordinator tapping
/// "Đặt HLV / Trọng tài" on an activity sets this to that activity's id
/// before navigating to professional discovery (there's no lobby-scoped
/// booking screen — the general discovery flow is reused, per the grill-me
/// decision). The booking sheet reads and immediately clears it on submit,
/// so it can only ever attach to the very next booking created — if the
/// user wanders off and books something unrelated first, that consumes and
/// clears the flag instead of misattaching a later one.
final class PendingActivityBookingStateProvider
    extends $NotifierProvider<PendingActivityBookingState, String?> {
  /// One-shot hand-off for lobby-scoped booking: a captain/coordinator tapping
  /// "Đặt HLV / Trọng tài" on an activity sets this to that activity's id
  /// before navigating to professional discovery (there's no lobby-scoped
  /// booking screen — the general discovery flow is reused, per the grill-me
  /// decision). The booking sheet reads and immediately clears it on submit,
  /// so it can only ever attach to the very next booking created — if the
  /// user wanders off and books something unrelated first, that consumes and
  /// clears the flag instead of misattaching a later one.
  PendingActivityBookingStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingActivityBookingStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingActivityBookingStateHash();

  @$internal
  @override
  PendingActivityBookingState create() => PendingActivityBookingState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pendingActivityBookingStateHash() =>
    r'd0ed054d61ea89a0bff39e4545ef813ec3244e4c';

/// One-shot hand-off for lobby-scoped booking: a captain/coordinator tapping
/// "Đặt HLV / Trọng tài" on an activity sets this to that activity's id
/// before navigating to professional discovery (there's no lobby-scoped
/// booking screen — the general discovery flow is reused, per the grill-me
/// decision). The booking sheet reads and immediately clears it on submit,
/// so it can only ever attach to the very next booking created — if the
/// user wanders off and books something unrelated first, that consumes and
/// clears the flag instead of misattaching a later one.

abstract class _$PendingActivityBookingState extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
