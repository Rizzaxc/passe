// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChallengerFeed)
final challengerFeedProvider = ChallengerFeedProvider._();

final class ChallengerFeedProvider
    extends $AsyncNotifierProvider<ChallengerFeed, List<Map<String, dynamic>>> {
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

String _$challengerFeedHash() => r'a3ca2a5755a520cc00c48228f00068c98bcafe8b';

abstract class _$ChallengerFeed
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
