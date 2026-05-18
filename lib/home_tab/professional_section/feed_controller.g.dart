// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfessionalFeed)
final professionalFeedProvider = ProfessionalFeedProvider._();

final class ProfessionalFeedProvider
    extends $AsyncNotifierProvider<ProfessionalFeed, List<ProfessionalFeedItem>> {
  ProfessionalFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'professionalFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$professionalFeedHash();

  @$internal
  @override
  ProfessionalFeed create() => ProfessionalFeed();
}

String _$professionalFeedHash() => r'eca4c0395a5809b6e263be173bbfff7407bd8d0e';

abstract class _$ProfessionalFeed
    extends $AsyncNotifier<List<ProfessionalFeedItem>> {
  FutureOr<List<ProfessionalFeedItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ProfessionalFeedItem>>,
              List<ProfessionalFeedItem>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ProfessionalFeedItem>>,
                List<ProfessionalFeedItem>
              >,
              AsyncValue<List<ProfessionalFeedItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ProfessionalRoleFilter)
final professionalRoleFilterProvider = ProfessionalRoleFilterProvider._();

final class ProfessionalRoleFilterProvider
    extends $NotifierProvider<ProfessionalRoleFilter, ProfessionalRole?> {
  ProfessionalRoleFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'professionalRoleFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$professionalRoleFilterHash();

  @$internal
  @override
  ProfessionalRoleFilter create() => ProfessionalRoleFilter();

  Override overrideWithValue(ProfessionalRole? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfessionalRole?>(value),
    );
  }
}

String _$professionalRoleFilterHash() =>
    r'professionalRoleFilter_manual_placeholder';

abstract class _$ProfessionalRoleFilter extends $Notifier<ProfessionalRole?> {
  ProfessionalRole? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfessionalRole?, ProfessionalRole?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfessionalRole?, ProfessionalRole?>,
              ProfessionalRole?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
