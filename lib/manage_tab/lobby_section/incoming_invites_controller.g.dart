// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incoming_invites_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IncomingInvitesController)
final incomingInvitesControllerProvider = IncomingInvitesControllerProvider._();

final class IncomingInvitesControllerProvider
    extends
        $AsyncNotifierProvider<
          IncomingInvitesController,
          List<IncomingInvite>
        > {
  IncomingInvitesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incomingInvitesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incomingInvitesControllerHash();

  @$internal
  @override
  IncomingInvitesController create() => IncomingInvitesController();
}

String _$incomingInvitesControllerHash() =>
    r'cc0acc1f6dc52c6a7fe1a466d8a4d677d44e09fc';

abstract class _$IncomingInvitesController
    extends $AsyncNotifier<List<IncomingInvite>> {
  FutureOr<List<IncomingInvite>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<IncomingInvite>>, List<IncomingInvite>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<IncomingInvite>>,
                List<IncomingInvite>
              >,
              AsyncValue<List<IncomingInvite>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
