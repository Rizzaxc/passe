import 'enum.dart';

class ProfessionalFeedItem {
  final String id;
  final String displayName;
  final ProfessionalRole role;
  final String? bio;
  final List<int> sports;
  final int? experienceYears;
  final double averageRating;
  final int reviewCount;
  final bool isVerified;
  final int? preferredCityCluster;
  final List<String> preferredDistricts;
  final List<String> preferredLocationNames;

  /// Cheapest active `professional_service.price_amount` for the context sport,
  /// rolled up by the feed controller (not present on the `professional` row
  /// itself). `null` when the professional has no active priced service.
  final double? priceFrom;
  final ProfessionalPricingKind? priceFromKind;

  const ProfessionalFeedItem({
    required this.id,
    required this.displayName,
    required this.role,
    this.bio,
    required this.sports,
    this.experienceYears,
    required this.averageRating,
    required this.reviewCount,
    required this.isVerified,
    this.preferredCityCluster,
    this.preferredDistricts = const [],
    this.preferredLocationNames = const [],
    this.priceFrom,
    this.priceFromKind,
  });

  factory ProfessionalFeedItem.fromJson(Map<String, dynamic> json) {
    final priceFrom = double.tryParse(json['price_from']?.toString() ?? '');
    return ProfessionalFeedItem(
      id: json['id'] as String,
      displayName: (json['display_name'] ?? json['name'] ?? '') as String,
      // DB column is `professional_role`; keep `role` as a fallback for any
      // RPC that aliases it. (Reading only `role` silently made every
      // professional parse as `coach`.)
      role: ProfessionalRole.values.firstWhere(
        (r) =>
            r.name == ((json['professional_role'] ?? json['role']) as String?),
        orElse: () => ProfessionalRole.coach,
      ),
      bio: json['bio'] as String?,
      sports:
          (json['sports'] as List?)?.map((e) => (e as num).toInt()).toList() ??
          [],
      experienceYears: (json['experience_years'] as num?)?.toInt(),
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '') ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      preferredCityCluster: (json['preferred_city_cluster'] as num?)?.toInt(),
      preferredDistricts:
          (json['preferred_districts'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      preferredLocationNames:
          (json['preferred_location_names'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList() ??
          const [],
      priceFrom: priceFrom,
      priceFromKind: priceFrom == null
          ? null
          : ProfessionalPricingKind.fromValue(
              json['price_from_kind'] as String?,
            ),
    );
  }
}
