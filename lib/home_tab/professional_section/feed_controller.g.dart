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

String _$professionalFeedHash() => r'60ca64fe6b28ed7569b99975f71835181b0791f0';

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
