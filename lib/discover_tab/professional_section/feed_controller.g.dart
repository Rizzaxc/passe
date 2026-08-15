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
        $AsyncNotifierProvider<ProfessionalFeed, List<ProfessionalFeedItem>> {
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

String _$professionalFeedHash() => r'cd2a981f57634fcd87dcea0a2752f06080f6f20e';

abstract class _$ProfessionalFeed
    extends $AsyncNotifier<List<ProfessionalFeedItem>> {
  FutureOr<List<ProfessionalFeedItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
