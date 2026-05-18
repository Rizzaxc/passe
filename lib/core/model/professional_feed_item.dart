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
  });

  factory ProfessionalFeedItem.fromJson(Map<String, dynamic> json) {
    return ProfessionalFeedItem(
      id: json['id'] as String,
      displayName: (json['display_name'] ?? json['name'] ?? '') as String,
      role: ProfessionalRole.values.firstWhere(
        (r) => r.name == (json['role'] as String?),
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
    );
  }
}
