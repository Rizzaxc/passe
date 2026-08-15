// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches a single professional by id from the `professional` table.
///
/// Used by [ProfessionalDetailPage] when navigation arrives without a
/// preloaded [ProfessionalFeedItem] (e.g. a deep-link, a push notif, or
/// a place that hasn't fetched the row yet). Callers that already have
/// the model should pass it as `$extra` to skip this round-trip.

@ProviderFor(professionalById)
final professionalByIdProvider = ProfessionalByIdFamily._();

/// Fetches a single professional by id from the `professional` table.
///
/// Used by [ProfessionalDetailPage] when navigation arrives without a
/// preloaded [ProfessionalFeedItem] (e.g. a deep-link, a push notif, or
/// a place that hasn't fetched the row yet). Callers that already have
/// the model should pass it as `$extra` to skip this round-trip.

final class ProfessionalByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProfessionalFeedItem>,
          ProfessionalFeedItem,
          FutureOr<ProfessionalFeedItem>
        >
    with
        $FutureModifier<ProfessionalFeedItem>,
        $FutureProvider<ProfessionalFeedItem> {
  /// Fetches a single professional by id from the `professional` table.
  ///
  /// Used by [ProfessionalDetailPage] when navigation arrives without a
  /// preloaded [ProfessionalFeedItem] (e.g. a deep-link, a push notif, or
  /// a place that hasn't fetched the row yet). Callers that already have
  /// the model should pass it as `$extra` to skip this round-trip.
  ProfessionalByIdProvider._({
    required ProfessionalByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'professionalByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$professionalByIdHash();

  @override
  String toString() {
    return r'professionalByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProfessionalFeedItem> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProfessionalFeedItem> create(Ref ref) {
    final argument = this.argument as String;
    return professionalById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfessionalByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$professionalByIdHash() => r'a8f3187815c3d39deecf2f6fdacf4b128dd671f6';

/// Fetches a single professional by id from the `professional` table.
///
/// Used by [ProfessionalDetailPage] when navigation arrives without a
/// preloaded [ProfessionalFeedItem] (e.g. a deep-link, a push notif, or
/// a place that hasn't fetched the row yet). Callers that already have
/// the model should pass it as `$extra` to skip this round-trip.

final class ProfessionalByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProfessionalFeedItem>, String> {
  ProfessionalByIdFamily._()
    : super(
        retry: null,
        name: r'professionalByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a single professional by id from the `professional` table.
  ///
  /// Used by [ProfessionalDetailPage] when navigation arrives without a
  /// preloaded [ProfessionalFeedItem] (e.g. a deep-link, a push notif, or
  /// a place that hasn't fetched the row yet). Callers that already have
  /// the model should pass it as `$extra` to skip this round-trip.

  ProfessionalByIdProvider call(String id) =>
      ProfessionalByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'professionalByIdProvider';
}

/// The signed-in user's own `professional.id`, if their account is linked
/// (`professional.linked_user_id = auth.uid()`) — `null` for a regular
/// player. Set out-of-app (admin/DB-direct), never self-registered. Gates
/// whether the pro-mode toggle appears at all, and scopes every pro-mode
/// query.

@ProviderFor(linkedProfessionalId)
final linkedProfessionalIdProvider = LinkedProfessionalIdProvider._();

/// The signed-in user's own `professional.id`, if their account is linked
/// (`professional.linked_user_id = auth.uid()`) — `null` for a regular
/// player. Set out-of-app (admin/DB-direct), never self-registered. Gates
/// whether the pro-mode toggle appears at all, and scopes every pro-mode
/// query.

final class LinkedProfessionalIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The signed-in user's own `professional.id`, if their account is linked
  /// (`professional.linked_user_id = auth.uid()`) — `null` for a regular
  /// player. Set out-of-app (admin/DB-direct), never self-registered. Gates
  /// whether the pro-mode toggle appears at all, and scopes every pro-mode
  /// query.
  LinkedProfessionalIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkedProfessionalIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkedProfessionalIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return linkedProfessionalId(ref);
  }
}

String _$linkedProfessionalIdHash() =>
    r'b58d26f84e9f8ef9f8f4fe13f3a0ab285f807134';

/// A professional's own Zalo — the same `user_contact` row they (or, for a
/// referee, presumably nobody yet) edit in user mode / pro mode, sourced by
/// a two-step lookup (`professional.linked_user_id` → `user_contact.zalo`)
/// rather than widening `home_professional_data`'s return shape. Readable
/// regardless of `zalo_public`/friendship — see
/// `schema/user_contact_professional_visibility.sql`. `null` when unlinked
/// or unset, which callers treat as "no Zalo button".

@ProviderFor(professionalZalo)
final professionalZaloProvider = ProfessionalZaloFamily._();

/// A professional's own Zalo — the same `user_contact` row they (or, for a
/// referee, presumably nobody yet) edit in user mode / pro mode, sourced by
/// a two-step lookup (`professional.linked_user_id` → `user_contact.zalo`)
/// rather than widening `home_professional_data`'s return shape. Readable
/// regardless of `zalo_public`/friendship — see
/// `schema/user_contact_professional_visibility.sql`. `null` when unlinked
/// or unset, which callers treat as "no Zalo button".

final class ProfessionalZaloProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A professional's own Zalo — the same `user_contact` row they (or, for a
  /// referee, presumably nobody yet) edit in user mode / pro mode, sourced by
  /// a two-step lookup (`professional.linked_user_id` → `user_contact.zalo`)
  /// rather than widening `home_professional_data`'s return shape. Readable
  /// regardless of `zalo_public`/friendship — see
  /// `schema/user_contact_professional_visibility.sql`. `null` when unlinked
  /// or unset, which callers treat as "no Zalo button".
  ProfessionalZaloProvider._({
    required ProfessionalZaloFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'professionalZaloProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$professionalZaloHash();

  @override
  String toString() {
    return r'professionalZaloProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return professionalZalo(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfessionalZaloProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$professionalZaloHash() => r'bab19533100e1017dfcbe4cf095b3b1b62b8858a';

/// A professional's own Zalo — the same `user_contact` row they (or, for a
/// referee, presumably nobody yet) edit in user mode / pro mode, sourced by
/// a two-step lookup (`professional.linked_user_id` → `user_contact.zalo`)
/// rather than widening `home_professional_data`'s return shape. Readable
/// regardless of `zalo_public`/friendship — see
/// `schema/user_contact_professional_visibility.sql`. `null` when unlinked
/// or unset, which callers treat as "no Zalo button".

final class ProfessionalZaloFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  ProfessionalZaloFamily._()
    : super(
        retry: null,
        name: r'professionalZaloProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A professional's own Zalo — the same `user_contact` row they (or, for a
  /// referee, presumably nobody yet) edit in user mode / pro mode, sourced by
  /// a two-step lookup (`professional.linked_user_id` → `user_contact.zalo`)
  /// rather than widening `home_professional_data`'s return shape. Readable
  /// regardless of `zalo_public`/friendship — see
  /// `schema/user_contact_professional_visibility.sql`. `null` when unlinked
  /// or unset, which callers treat as "no Zalo button".

  ProfessionalZaloProvider call(String professionalId) =>
      ProfessionalZaloProvider._(argument: professionalId, from: this);

  @override
  String toString() => r'professionalZaloProvider';
}

/// Whether the signed-in user's linked professional profile is a **coach**
/// (as opposed to a referee). Pro mode branches on this: a coach runs courses,
/// a referee runs bookings.

@ProviderFor(isLinkedCoach)
final isLinkedCoachProvider = IsLinkedCoachProvider._();

/// Whether the signed-in user's linked professional profile is a **coach**
/// (as opposed to a referee). Pro mode branches on this: a coach runs courses,
/// a referee runs bookings.

final class IsLinkedCoachProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the signed-in user's linked professional profile is a **coach**
  /// (as opposed to a referee). Pro mode branches on this: a coach runs courses,
  /// a referee runs bookings.
  IsLinkedCoachProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isLinkedCoachProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isLinkedCoachHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isLinkedCoach(ref);
  }
}

String _$isLinkedCoachHash() => r'b8491176e7847cee7bfd9a50c6e54e2f97ec37f6';
