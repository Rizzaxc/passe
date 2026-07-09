// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_mode_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether a linked professional is currently viewing Manage/Profile as their
/// pro-facing surface instead of the normal player one. Only meaningful when
/// `linkedProfessionalIdProvider` resolves non-null — the toggle that flips
/// this is hidden otherwise. Same shape as `SelectedSportState`.

@ProviderFor(ProModeState)
final proModeStateProvider = ProModeStateProvider._();

/// Whether a linked professional is currently viewing Manage/Profile as their
/// pro-facing surface instead of the normal player one. Only meaningful when
/// `linkedProfessionalIdProvider` resolves non-null — the toggle that flips
/// this is hidden otherwise. Same shape as `SelectedSportState`.
final class ProModeStateProvider
    extends $AsyncNotifierProvider<ProModeState, bool> {
  /// Whether a linked professional is currently viewing Manage/Profile as their
  /// pro-facing surface instead of the normal player one. Only meaningful when
  /// `linkedProfessionalIdProvider` resolves non-null — the toggle that flips
  /// this is hidden otherwise. Same shape as `SelectedSportState`.
  ProModeStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proModeStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proModeStateHash();

  @$internal
  @override
  ProModeState create() => ProModeState();
}

String _$proModeStateHash() => r'33fc4d74bdef83d1aa2623ff069cc064d6aff693';

/// Whether a linked professional is currently viewing Manage/Profile as their
/// pro-facing surface instead of the normal player one. Only meaningful when
/// `linkedProfessionalIdProvider` resolves non-null — the toggle that flips
/// this is hidden otherwise. Same shape as `SelectedSportState`.

abstract class _$ProModeState extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
