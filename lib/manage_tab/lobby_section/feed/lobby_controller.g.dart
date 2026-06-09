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
    extends $AsyncNotifierProvider<UserLobbiesController, List<LobbyListItem>> {
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
    r'c0a978fc97e4f2a1cc5e9a7e5730bd46d61aa26b';

abstract class _$UserLobbiesController
    extends $AsyncNotifier<List<LobbyListItem>> {
  FutureOr<List<LobbyListItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<LobbyListItem>>, List<LobbyListItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LobbyListItem>>, List<LobbyListItem>>,
              AsyncValue<List<LobbyListItem>>,
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
    r'f25b47c72904d8a61baaea82e167045759649a36';

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
