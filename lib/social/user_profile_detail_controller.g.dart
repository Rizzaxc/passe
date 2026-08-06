// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userProfileDetail)
final userProfileDetailProvider = UserProfileDetailFamily._();

final class UserProfileDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfileDetail>,
          UserProfileDetail,
          FutureOr<UserProfileDetail>
        >
    with
        $FutureModifier<UserProfileDetail>,
        $FutureProvider<UserProfileDetail> {
  UserProfileDetailProvider._({
    required UserProfileDetailFamily super.from,
    required (String, Sport) super.argument,
  }) : super(
         retry: null,
         name: r'userProfileDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userProfileDetailHash();

  @override
  String toString() {
    return r'userProfileDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<UserProfileDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfileDetail> create(Ref ref) {
    final argument = this.argument as (String, Sport);
    return userProfileDetail(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfileDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userProfileDetailHash() => r'b4a5a4b00ee010301938d0d2a39c6b3ab2a2bddb';

final class UserProfileDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<UserProfileDetail>,
          (String, Sport)
        > {
  UserProfileDetailFamily._()
    : super(
        retry: null,
        name: r'userProfileDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserProfileDetailProvider call(String userId, Sport sport) =>
      UserProfileDetailProvider._(argument: (userId, sport), from: this);

  @override
  String toString() => r'userProfileDetailProvider';
}
