// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_info_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's own payment info — capped to one row per user
/// (`user_payment_info_user_id_key`), so this list is always 0 or 1 long.
/// Plain immediately-persisted writes (add upserts, delete clears), unlike
/// `ProfileController`'s draft/commit pattern, since there's no batching
/// benefit here and an add can involve picking a bank from a live form.

@ProviderFor(PaymentInfoController)
final paymentInfoControllerProvider = PaymentInfoControllerProvider._();

/// The signed-in user's own payment info — capped to one row per user
/// (`user_payment_info_user_id_key`), so this list is always 0 or 1 long.
/// Plain immediately-persisted writes (add upserts, delete clears), unlike
/// `ProfileController`'s draft/commit pattern, since there's no batching
/// benefit here and an add can involve picking a bank from a live form.
final class PaymentInfoControllerProvider
    extends
        $AsyncNotifierProvider<PaymentInfoController, List<UserPaymentInfo>> {
  /// The signed-in user's own payment info — capped to one row per user
  /// (`user_payment_info_user_id_key`), so this list is always 0 or 1 long.
  /// Plain immediately-persisted writes (add upserts, delete clears), unlike
  /// `ProfileController`'s draft/commit pattern, since there's no batching
  /// benefit here and an add can involve picking a bank from a live form.
  PaymentInfoControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentInfoControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentInfoControllerHash();

  @$internal
  @override
  PaymentInfoController create() => PaymentInfoController();
}

String _$paymentInfoControllerHash() =>
    r'fa118dd5611fbca7605f6b300dbd7d82b8af2197';

/// The signed-in user's own payment info — capped to one row per user
/// (`user_payment_info_user_id_key`), so this list is always 0 or 1 long.
/// Plain immediately-persisted writes (add upserts, delete clears), unlike
/// `ProfileController`'s draft/commit pattern, since there's no batching
/// benefit here and an add can involve picking a bank from a live form.

abstract class _$PaymentInfoController
    extends $AsyncNotifier<List<UserPaymentInfo>> {
  FutureOr<List<UserPaymentInfo>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<UserPaymentInfo>>, List<UserPaymentInfo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<UserPaymentInfo>>,
                List<UserPaymentInfo>
              >,
              AsyncValue<List<UserPaymentInfo>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
