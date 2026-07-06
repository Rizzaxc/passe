// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coaching_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's coach bookings (`professional_booking` rows where
/// the linked professional's role is `coach`) — real data behind Manage ▸
/// Coaching, replacing the fully-mocked course/session prototype. Referee
/// bookings surface elsewhere (via `lobby_match.referee_booking_id`), so
/// this excludes them.

@ProviderFor(coachingBookings)
final coachingBookingsProvider = CoachingBookingsProvider._();

/// The signed-in user's coach bookings (`professional_booking` rows where
/// the linked professional's role is `coach`) — real data behind Manage ▸
/// Coaching, replacing the fully-mocked course/session prototype. Referee
/// bookings surface elsewhere (via `lobby_match.referee_booking_id`), so
/// this excludes them.

final class CoachingBookingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProfessionalBookingItem>>,
          List<ProfessionalBookingItem>,
          FutureOr<List<ProfessionalBookingItem>>
        >
    with
        $FutureModifier<List<ProfessionalBookingItem>>,
        $FutureProvider<List<ProfessionalBookingItem>> {
  /// The signed-in user's coach bookings (`professional_booking` rows where
  /// the linked professional's role is `coach`) — real data behind Manage ▸
  /// Coaching, replacing the fully-mocked course/session prototype. Referee
  /// bookings surface elsewhere (via `lobby_match.referee_booking_id`), so
  /// this excludes them.
  CoachingBookingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachingBookingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachingBookingsHash();

  @$internal
  @override
  $FutureProviderElement<List<ProfessionalBookingItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProfessionalBookingItem>> create(Ref ref) {
    return coachingBookings(ref);
  }
}

String _$coachingBookingsHash() => r'9430b24434315357f3ee1a04bec4372d8f53f942';

/// Client-side actions on a coaching booking: cancelling an upcoming
/// request/confirmation, or reviewing a past confirmed session (see
/// `schema/professional_booking_review_policy_fix.sql` for why the review
/// gate is "confirmed + past", not `status == completed`).

@ProviderFor(CoachingBookingActionController)
final coachingBookingActionControllerProvider =
    CoachingBookingActionControllerProvider._();

/// Client-side actions on a coaching booking: cancelling an upcoming
/// request/confirmation, or reviewing a past confirmed session (see
/// `schema/professional_booking_review_policy_fix.sql` for why the review
/// gate is "confirmed + past", not `status == completed`).
final class CoachingBookingActionControllerProvider
    extends $NotifierProvider<CoachingBookingActionController, bool> {
  /// Client-side actions on a coaching booking: cancelling an upcoming
  /// request/confirmation, or reviewing a past confirmed session (see
  /// `schema/professional_booking_review_policy_fix.sql` for why the review
  /// gate is "confirmed + past", not `status == completed`).
  CoachingBookingActionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachingBookingActionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachingBookingActionControllerHash();

  @$internal
  @override
  CoachingBookingActionController create() => CoachingBookingActionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$coachingBookingActionControllerHash() =>
    r'99b79768f491f598b2a9cb276428e22373939d9f';

/// Client-side actions on a coaching booking: cancelling an upcoming
/// request/confirmation, or reviewing a past confirmed session (see
/// `schema/professional_booking_review_policy_fix.sql` for why the review
/// gate is "confirmed + past", not `status == completed`).

abstract class _$CoachingBookingActionController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
