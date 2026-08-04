// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_sport_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedSportState)
final selectedSportStateProvider = SelectedSportStateProvider._();

final class SelectedSportStateProvider
    extends $AsyncNotifierProvider<SelectedSportState, Sport> {
  SelectedSportStateProvider._()
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
    r'd4ac244175180406c97369e48d2342738b5af2b1';

abstract class _$SelectedSportState extends $AsyncNotifier<Sport> {
  FutureOr<Sport> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Sport>, Sport>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Sport>, Sport>,
              AsyncValue<Sport>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
