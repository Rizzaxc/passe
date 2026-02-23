// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserLobbiesController)
final userLobbiesControllerProvider = UserLobbiesControllerProvider._();

final class UserLobbiesControllerProvider
    extends $AsyncNotifierProvider<UserLobbiesController, List<Lobby>> {
  UserLobbiesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userLobbiesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userLobbiesControllerHash();

  @$internal
  @override
  UserLobbiesController create() => UserLobbiesController();
}

String _$userLobbiesControllerHash() =>
    r'17e77724616dc353f6a743965a16d5cc4d8db54f';

abstract class _$UserLobbiesController extends $AsyncNotifier<List<Lobby>> {
  FutureOr<List<Lobby>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Lobby>>, List<Lobby>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Lobby>>, List<Lobby>>,
              AsyncValue<List<Lobby>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(LobbyFormController)
final lobbyFormControllerProvider = LobbyFormControllerFamily._();

final class LobbyFormControllerProvider
    extends $NotifierProvider<LobbyFormController, LobbyFormState> {
  LobbyFormControllerProvider._({
    required LobbyFormControllerFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'lobbyFormControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lobbyFormControllerHash();

  @override
  String toString() {
    return r'lobbyFormControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LobbyFormController create() => LobbyFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LobbyFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LobbyFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LobbyFormControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lobbyFormControllerHash() =>
    r'a72b7e7e297d621297624555e91ccaac2d4e1c11';

final class LobbyFormControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LobbyFormController,
          LobbyFormState,
          LobbyFormState,
          LobbyFormState,
          String?
        > {
  LobbyFormControllerFamily._()
    : super(
        retry: null,
        name: r'lobbyFormControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LobbyFormControllerProvider call(String? lobbyId) =>
      LobbyFormControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'lobbyFormControllerProvider';
}

abstract class _$LobbyFormController extends $Notifier<LobbyFormState> {
  late final _$args = ref.$arg as String?;
  String? get lobbyId => _$args;

  LobbyFormState build(String? lobbyId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LobbyFormState, LobbyFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LobbyFormState, LobbyFormState>,
              LobbyFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
