// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hero_collapse_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the pinned activity hero (`hero.dart`) renders as a slim
/// full-width "Lên Lịch" button instead of its full card. A user density
/// preference toggled from the hero itself, persisted per-user via
/// [UserPreferences] — distinct from `ActivityHero.compact`, which is a
/// transient scroll-position-driven collapse that doesn't survive a rebuild.

@ProviderFor(HeroCollapsedState)
final heroCollapsedStateProvider = HeroCollapsedStateProvider._();

/// Whether the pinned activity hero (`hero.dart`) renders as a slim
/// full-width "Lên Lịch" button instead of its full card. A user density
/// preference toggled from the hero itself, persisted per-user via
/// [UserPreferences] — distinct from `ActivityHero.compact`, which is a
/// transient scroll-position-driven collapse that doesn't survive a rebuild.
final class HeroCollapsedStateProvider
    extends $AsyncNotifierProvider<HeroCollapsedState, bool> {
  /// Whether the pinned activity hero (`hero.dart`) renders as a slim
  /// full-width "Lên Lịch" button instead of its full card. A user density
  /// preference toggled from the hero itself, persisted per-user via
  /// [UserPreferences] — distinct from `ActivityHero.compact`, which is a
  /// transient scroll-position-driven collapse that doesn't survive a rebuild.
  HeroCollapsedStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'heroCollapsedStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$heroCollapsedStateHash();

  @$internal
  @override
  HeroCollapsedState create() => HeroCollapsedState();
}

String _$heroCollapsedStateHash() =>
    r'1162c6e161e80315eb927dcf76b9881b766ff136';

/// Whether the pinned activity hero (`hero.dart`) renders as a slim
/// full-width "Lên Lịch" button instead of its full card. A user density
/// preference toggled from the hero itself, persisted per-user via
/// [UserPreferences] — distinct from `ActivityHero.compact`, which is a
/// transient scroll-position-driven collapse that doesn't survive a rebuild.

abstract class _$HeroCollapsedState extends $AsyncNotifier<bool> {
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
