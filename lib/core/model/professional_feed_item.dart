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

  /// Cheapest active `professional_service.hourly_rate` for the context sport,
  /// rolled up by the feed controller (not present on the `professional` row
  /// itself). `null` when the professional has no active priced service.
  final double? priceFrom;

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
    this.priceFrom,
  });

  factory ProfessionalFeedItem.fromJson(Map<String, dynamic> json) {
    return ProfessionalFeedItem(
      id: json['id'] as String,
      displayName: (json['display_name'] ?? json['name'] ?? '') as String,
      // DB column is `professional_role`; keep `role` as a fallback for any
      // RPC that aliases it. (Reading only `role` silently made every
      // professional parse as `coach`.)
      role: ProfessionalRole.values.firstWhere(
        (r) => r.name == ((json['professional_role'] ?? json['role']) as String?),
        orElse: () => ProfessionalRole.coach,
      ),
      bio: json['bio'] as String?,
      sports: (json['sports'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      experienceYears: (json['experience_years'] as num?)?.toInt(),
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '') ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      priceFrom: double.tryParse(json['price_from']?.toString() ?? ''),
    );
  }
}
