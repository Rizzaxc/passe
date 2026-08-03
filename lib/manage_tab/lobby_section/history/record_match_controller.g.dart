// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_match_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Records a played match into `lobby_match`. Captain-only (RLS: "Captain can
/// record matches for their lobby"). v1 records against a free-text opponent
/// (`opponent_lobby_id` stays null, so the referee-required constraint doesn't
/// apply); linking to an opponent lobby + referee booking arrives with the
/// challenge handshake.

@ProviderFor(RecordMatchController)
final recordMatchControllerProvider = RecordMatchControllerFamily._();

/// Records a played match into `lobby_match`. Captain-only (RLS: "Captain can
/// record matches for their lobby"). v1 records against a free-text opponent
/// (`opponent_lobby_id` stays null, so the referee-required constraint doesn't
/// apply); linking to an opponent lobby + referee booking arrives with the
/// challenge handshake.
final class RecordMatchControllerProvider
    extends $NotifierProvider<RecordMatchController, bool> {
  /// Records a played match into `lobby_match`. Captain-only (RLS: "Captain can
  /// record matches for their lobby"). v1 records against a free-text opponent
  /// (`opponent_lobby_id` stays null, so the referee-required constraint doesn't
  /// apply); linking to an opponent lobby + referee booking arrives with the
  /// challenge handshake.
  RecordMatchControllerProvider._({
    required RecordMatchControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recordMatchControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recordMatchControllerHash();

  @override
  String toString() {
    return r'recordMatchControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecordMatchController create() => RecordMatchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecordMatchControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recordMatchControllerHash() =>
    r'd3204be4490e25b14e1facd7ffa9bd3e3f256619';

/// Records a played match into `lobby_match`. Captain-only (RLS: "Captain can
/// record matches for their lobby"). v1 records against a free-text opponent
/// (`opponent_lobby_id` stays null, so the referee-required constraint doesn't
/// apply); linking to an opponent lobby + referee booking arrives with the
/// challenge handshake.

final class RecordMatchControllerFamily extends $Family
    with $ClassFamilyOverride<RecordMatchController, bool, bool, bool, String> {
  RecordMatchControllerFamily._()
    : super(
        retry: null,
        name: r'recordMatchControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Records a played match into `lobby_match`. Captain-only (RLS: "Captain can
  /// record matches for their lobby"). v1 records against a free-text opponent
  /// (`opponent_lobby_id` stays null, so the referee-required constraint doesn't
  /// apply); linking to an opponent lobby + referee booking arrives with the
  /// challenge handshake.

  RecordMatchControllerProvider call(String lobbyId) =>
      RecordMatchControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'recordMatchControllerProvider';
}

/// Records a played match into `lobby_match`. Captain-only (RLS: "Captain can
/// record matches for their lobby"). v1 records against a free-text opponent
/// (`opponent_lobby_id` stays null, so the referee-required constraint doesn't
/// apply); linking to an opponent lobby + referee booking arrives with the
/// challenge handshake.

abstract class _$RecordMatchController extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  bool build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
