// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_location_field.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A coach's declared courts (set out-of-app — see
/// `schema/professional_preferred_location.sql`), for the student to pick a
/// session venue from.

@ProviderFor(preferredCourts)
final preferredCourtsProvider = PreferredCourtsFamily._();

/// A coach's declared courts (set out-of-app — see
/// `schema/professional_preferred_location.sql`), for the student to pick a
/// session venue from.

final class PreferredCourtsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Location>>,
          List<Location>,
          FutureOr<List<Location>>
        >
    with $FutureModifier<List<Location>>, $FutureProvider<List<Location>> {
  /// A coach's declared courts (set out-of-app — see
  /// `schema/professional_preferred_location.sql`), for the student to pick a
  /// session venue from.
  PreferredCourtsProvider._({
    required PreferredCourtsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'preferredCourtsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$preferredCourtsHash();

  @override
  String toString() {
    return r'preferredCourtsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Location>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Location>> create(Ref ref) {
    final argument = this.argument as String;
    return preferredCourts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PreferredCourtsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$preferredCourtsHash() => r'42742001a70e5c9a2d75e2e4fb080c594462678a';

/// A coach's declared courts (set out-of-app — see
/// `schema/professional_preferred_location.sql`), for the student to pick a
/// session venue from.

final class PreferredCourtsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Location>>, String> {
  PreferredCourtsFamily._()
    : super(
        retry: null,
        name: r'preferredCourtsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A coach's declared courts (set out-of-app — see
  /// `schema/professional_preferred_location.sql`), for the student to pick a
  /// session venue from.

  PreferredCourtsProvider call(String professionalId) =>
      PreferredCourtsProvider._(argument: professionalId, from: this);

  @override
  String toString() => r'preferredCourtsProvider';
}
