// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirmation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActivityConfirmationController)
final activityConfirmationControllerProvider =
    ActivityConfirmationControllerFamily._();

final class ActivityConfirmationControllerProvider
    extends
        $AsyncNotifierProvider<
          ActivityConfirmationController,
          ActivityConfirmationStatus
        > {
  ActivityConfirmationControllerProvider._({
    required ActivityConfirmationControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activityConfirmationControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activityConfirmationControllerHash();

  @override
  String toString() {
    return r'activityConfirmationControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActivityConfirmationController create() => ActivityConfirmationController();

  @override
  bool operator ==(Object other) {
    return other is ActivityConfirmationControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activityConfirmationControllerHash() =>
    r'activity-confirmation-hand-rolled';

final class ActivityConfirmationControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ActivityConfirmationController,
          AsyncValue<ActivityConfirmationStatus>,
          ActivityConfirmationStatus,
          FutureOr<ActivityConfirmationStatus>,
          String
        > {
  ActivityConfirmationControllerFamily._()
    : super(
        retry: null,
        name: r'activityConfirmationControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActivityConfirmationControllerProvider call(String activityId) =>
      ActivityConfirmationControllerProvider._(
        argument: activityId,
        from: this,
      );

  @override
  String toString() => r'activityConfirmationControllerProvider';
}

abstract class _$ActivityConfirmationController
    extends $AsyncNotifier<ActivityConfirmationStatus> {
  late final _$args = ref.$arg as String;
  String get activityId => _$args;

  FutureOr<ActivityConfirmationStatus> build(String activityId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ActivityConfirmationStatus>,
              ActivityConfirmationStatus
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ActivityConfirmationStatus>,
                ActivityConfirmationStatus
              >,
              AsyncValue<ActivityConfirmationStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
