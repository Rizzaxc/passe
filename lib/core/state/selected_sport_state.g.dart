// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_sport_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedSportState)
const selectedSportStateProvider = SelectedSportStateProvider._();

final class SelectedSportStateProvider
    extends $AsyncNotifierProvider<SelectedSportState, Sport> {
  const SelectedSportStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSportStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSportStateHash();

  @$internal
  @override
  SelectedSportState create() => SelectedSportState();
}

String _$selectedSportStateHash() =>
    r'bdbed74668dc35e21231481543aabe63695040a4';

abstract class _$SelectedSportState extends $AsyncNotifier<Sport> {
  FutureOr<Sport> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Sport>, Sport>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Sport>, Sport>,
              AsyncValue<Sport>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
