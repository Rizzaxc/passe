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
    extends
        $AsyncNotifierProvider<ProfessionalFeed, List<Map<String, dynamic>>> {
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
    extends $AsyncNotifier<List<Map<String, dynamic>>> {
  FutureOr<List<Map<String, dynamic>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>>,
              List<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>>,
                List<Map<String, dynamic>>
              >,
              AsyncValue<List<Map<String, dynamic>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
