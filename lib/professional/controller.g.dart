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

String _$professionalByIdHash() => r'08973deca1679bde4a3bf7ab61123b69d3284cdc';

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
