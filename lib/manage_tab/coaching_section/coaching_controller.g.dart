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
/// bookings surface elsewhere (attached to a lobby activity via
/// `activity.referee_booking_id`, shown on the activity hero card; and on a
/// recorded match via `lobby_match.referee_booking_id`), so this coach-only
/// view excludes them.

@ProviderFor(coachingBookings)
final coachingBookingsProvider = CoachingBookingsProvider._();

/// The signed-in user's coach bookings (`professional_booking` rows where
/// the linked professional's role is `coach`) — real data behind Manage ▸
/// Coaching, replacing the fully-mocked course/session prototype. Referee
/// bookings surface elsewhere (attached to a lobby activity via
/// `activity.referee_booking_id`, shown on the activity hero card; and on a
/// recorded match via `lobby_match.referee_booking_id`), so this coach-only
/// view excludes them.

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
  /// bookings surface elsewhere (attached to a lobby activity via
  /// `activity.referee_booking_id`, shown on the activity hero card; and on a
  /// recorded match via `lobby_match.referee_booking_id`), so this coach-only
  /// view excludes them.
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
/// request/confirmation, marking a past confirmed session complete (either
/// party, first tap wins — see `schema/professional_booking_completion.sql`),
/// or reviewing a completed session.

@ProviderFor(CoachingBookingActionController)
final coachingBookingActionControllerProvider =
    CoachingBookingActionControllerProvider._();

/// Client-side actions on a coaching booking: cancelling an upcoming
/// request/confirmation, marking a past confirmed session complete (either
/// party, first tap wins — see `schema/professional_booking_completion.sql`),
/// or reviewing a completed session.
final class CoachingBookingActionControllerProvider
    extends $NotifierProvider<CoachingBookingActionController, bool> {
  /// Client-side actions on a coaching booking: cancelling an upcoming
  /// request/confirmation, marking a past confirmed session complete (either
  /// party, first tap wins — see `schema/professional_booking_completion.sql`),
  /// or reviewing a completed session.
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
    r'b22dfff19f08138f858c716df512ecb4cfef52b2';

/// Client-side actions on a coaching booking: cancelling an upcoming
/// request/confirmation, marking a past confirmed session complete (either
/// party, first tap wins — see `schema/professional_booking_completion.sql`),
/// or reviewing a completed session.

abstract class _$CoachingBookingActionController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
