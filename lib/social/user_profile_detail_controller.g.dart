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
    required String super.argument,
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
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserProfileDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfileDetail> create(Ref ref) {
    final argument = this.argument as String;
    return userProfileDetail(ref, argument);
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

String _$userProfileDetailHash() => r'8f46fe49e102cde54b60c091f12ffc9b67f256c8';

final class UserProfileDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserProfileDetail>, String> {
  UserProfileDetailFamily._()
    : super(
        retry: null,
        name: r'userProfileDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserProfileDetailProvider call(String userId) =>
      UserProfileDetailProvider._(argument: userId, from: this);

  @override
  String toString() => r'userProfileDetailProvider';
}
