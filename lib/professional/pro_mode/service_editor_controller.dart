import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'service_editor_controller.g.dart';

/// One `professional_service` row, full shape (not just the active-only
/// subset the client booking sheet reads) — used for the pro's own CRUD
/// screen, so includes `isActive`/`sessionCount`/`pricingMode`.
class ProfessionalServiceRow {
  final String id;
  final int sportId;
  final String serviceType;
  final String? description;
  final double? hourlyRate;
  final int? minDurationMinutes;
  final int? maxParticipants;
  final int sessionCount;
  final String pricingMode; // 'per_session' | 'wholesale'
  final bool isActive;

  const ProfessionalServiceRow({
    required this.id,
    required this.sportId,
    required this.serviceType,
    this.description,
    this.hourlyRate,
    this.minDurationMinutes,
    this.maxParticipants,
    required this.sessionCount,
    required this.pricingMode,
    required this.isActive,
  });

  factory ProfessionalServiceRow.fromJson(Map<String, dynamic> json) {
    return ProfessionalServiceRow(
      id: json['id'] as String,
      sportId: (json['sport_id'] as num).toInt(),
      serviceType: json['service_type'] as String,
      description: json['service_description'] as String?,
      hourlyRate: double.tryParse(json['hourly_rate']?.toString() ?? ''),
      minDurationMinutes: (json['min_duration_minutes'] as num?)?.toInt(),
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 1,
      pricingMode: json['pricing_mode'] as String? ?? 'per_session',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

@riverpod
Future<List<ProfessionalServiceRow>> myServices(
  Ref ref,
  String professionalId,
) async {
  final response = await Supabase.instance.client
      .from('professional_service')
      .select()
      .eq('professional_id', professionalId)
      .order('created_at')
      .timeout(const Duration(seconds: 5));

  return (response as List)
      .map((e) => ProfessionalServiceRow.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Create/edit/(de)activate the linked professional's own services. RLS
/// ("Linked professionals can manage their own services") already scopes
/// writes to the caller's own `professional_id`.
@riverpod
class ServiceEditorController extends _$ServiceEditorController {
  final supabase = Supabase.instance.client;

  @override
  bool build(String professionalId) => false; // in-flight flag

  Future<void> upsert({
    String? id,
    required int sportId,
    required String serviceType,
    String? description,
    double? hourlyRate,
    int? minDurationMinutes,
    int? maxParticipants,
    required int sessionCount,
    required String pricingMode,
  }) async {
    state = true;
    try {
      final data = {
        'professional_id': professionalId,
        'sport_id': sportId,
        'service_type': serviceType,
        'service_description': description,
        'hourly_rate': hourlyRate,
        'min_duration_minutes': minDurationMinutes,
        'max_participants': maxParticipants,
        'session_count': sessionCount,
        'pricing_mode': pricingMode,
      };
      if (id == null) {
        await supabase
            .from('professional_service')
            .insert(data)
            .timeout(const Duration(seconds: 5));
      } else {
        await supabase
            .from('professional_service')
            .update(data)
            .eq('id', id)
            .timeout(const Duration(seconds: 5));
      }
      ref.invalidate(myServicesProvider(professionalId));
    } finally {
      state = false;
    }
  }

  Future<void> setActive(String id, bool active) async {
    state = true;
    try {
      await supabase
          .from('professional_service')
          .update({'is_active': active})
          .eq('id', id)
          .timeout(const Duration(seconds: 5));
      ref.invalidate(myServicesProvider(professionalId));
    } finally {
      state = false;
    }
  }
}
