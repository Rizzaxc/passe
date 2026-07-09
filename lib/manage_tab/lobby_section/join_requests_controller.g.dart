// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_requests_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(JoinRequestsController)
final joinRequestsControllerProvider = JoinRequestsControllerFamily._();

final class JoinRequestsControllerProvider
    extends $AsyncNotifierProvider<JoinRequestsController, List<JoinRequest>> {
  JoinRequestsControllerProvider._({
    required JoinRequestsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'joinRequestsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$joinRequestsControllerHash();

  @override
  String toString() {
    return r'joinRequestsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JoinRequestsController create() => JoinRequestsController();

  @override
  bool operator ==(Object other) {
    return other is JoinRequestsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$joinRequestsControllerHash() =>
    r'f581927fdd59b860ed6104197125ea097a543ffa';

final class JoinRequestsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          JoinRequestsController,
          AsyncValue<List<JoinRequest>>,
          List<JoinRequest>,
          FutureOr<List<JoinRequest>>,
          String
        > {
  JoinRequestsControllerFamily._()
    : super(
        retry: null,
        name: r'joinRequestsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JoinRequestsControllerProvider call(String lobbyId) =>
      JoinRequestsControllerProvider._(argument: lobbyId, from: this);

  @override
  String toString() => r'joinRequestsControllerProvider';
}

abstract class _$JoinRequestsController
    extends $AsyncNotifier<List<JoinRequest>> {
  late final _$args = ref.$arg as String;
  String get lobbyId => _$args;

  FutureOr<List<JoinRequest>> build(String lobbyId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<JoinRequest>>, List<JoinRequest>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<JoinRequest>>, List<JoinRequest>>,
              AsyncValue<List<JoinRequest>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
