// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All of the caller's lobbies for the current sport — challenges are
/// lobby-vs-lobby, so the user picks which one they're challenging *as*
/// via the dropdown under the section title.

@ProviderFor(contextLobbyOptions)
final contextLobbyOptionsProvider = ContextLobbyOptionsProvider._();

/// All of the caller's lobbies for the current sport — challenges are
/// lobby-vs-lobby, so the user picks which one they're challenging *as*
/// via the dropdown under the section title.

final class ContextLobbyOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ContextLobby>>,
          List<ContextLobby>,
          FutureOr<List<ContextLobby>>
        >
    with
        $FutureModifier<List<ContextLobby>>,
        $FutureProvider<List<ContextLobby>> {
  /// All of the caller's lobbies for the current sport — challenges are
  /// lobby-vs-lobby, so the user picks which one they're challenging *as*
  /// via the dropdown under the section title.
  ContextLobbyOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contextLobbyOptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contextLobbyOptionsHash();

  @$internal
  @override
  $FutureProviderElement<List<ContextLobby>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ContextLobby>> create(Ref ref) {
    return contextLobbyOptions(ref);
  }
}

String _$contextLobbyOptionsHash() =>
    r'7279cc45e18a9dd5e3fbc9a3a053eba9ed386165';

/// The user's explicit pick from the context-lobby dropdown. Null means
/// "no explicit pick yet" — [contextLobby] falls back to the first option.

@ProviderFor(ContextLobbySelection)
final contextLobbySelectionProvider = ContextLobbySelectionProvider._();

/// The user's explicit pick from the context-lobby dropdown. Null means
/// "no explicit pick yet" — [contextLobby] falls back to the first option.
final class ContextLobbySelectionProvider
    extends $NotifierProvider<ContextLobbySelection, String?> {
  /// The user's explicit pick from the context-lobby dropdown. Null means
  /// "no explicit pick yet" — [contextLobby] falls back to the first option.
  ContextLobbySelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contextLobbySelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contextLobbySelectionHash();

  @$internal
  @override
  ContextLobbySelection create() => ContextLobbySelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$contextLobbySelectionHash() =>
    r'8c3d1b4d1858e26bea421dc1d84a5192be61f1bb';

/// The user's explicit pick from the context-lobby dropdown. Null means
/// "no explicit pick yet" — [contextLobby] falls back to the first option.

abstract class _$ContextLobbySelection extends $Notifier<String?> {
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

/// The effective context lobby: the user's explicit pick if it's still a
/// valid option, otherwise the first lobby for the current sport.

@ProviderFor(contextLobby)
final contextLobbyProvider = ContextLobbyProvider._();

/// The effective context lobby: the user's explicit pick if it's still a
/// valid option, otherwise the first lobby for the current sport.

final class ContextLobbyProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContextLobby?>,
          ContextLobby?,
          FutureOr<ContextLobby?>
        >
    with $FutureModifier<ContextLobby?>, $FutureProvider<ContextLobby?> {
  /// The effective context lobby: the user's explicit pick if it's still a
  /// valid option, otherwise the first lobby for the current sport.
  ContextLobbyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contextLobbyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contextLobbyHash();

  @$internal
  @override
  $FutureProviderElement<ContextLobby?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ContextLobby?> create(Ref ref) {
    return contextLobby(ref);
  }
}

String _$contextLobbyHash() => r'f981d13eb1a113c7f68a7bfeb122fcc359d4435c';

@ProviderFor(ChallengerFeed)
final challengerFeedProvider = ChallengerFeedProvider._();

final class ChallengerFeedProvider
    extends $AsyncNotifierProvider<ChallengerFeed, List<LobbyFeedItem>> {
  ChallengerFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'challengerFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$challengerFeedHash();

  @$internal
  @override
  ChallengerFeed create() => ChallengerFeed();
}

String _$challengerFeedHash() => r'5f0d7195fee87a73f4f2339cb6e3fdd2b811ddea';

abstract class _$ChallengerFeed extends $AsyncNotifier<List<LobbyFeedItem>> {
  FutureOr<List<LobbyFeedItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<LobbyFeedItem>>, List<LobbyFeedItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LobbyFeedItem>>, List<LobbyFeedItem>>,
              AsyncValue<List<LobbyFeedItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
