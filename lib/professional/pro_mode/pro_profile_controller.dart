import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/model/timeslot.dart';

part 'pro_profile_controller.g.dart';

/// Self-editable subset of a linked professional's own row — `display_name`,
/// certifications, and `is_verified` stay admin-managed, out of scope here.
class ProSelfProfile {
  final String displayName;
  final String? bio;
  final String? contactPhone;
  final List<Timeslot> schedule;
  final String? scheduleNote;

  const ProSelfProfile({
    required this.displayName,
    this.bio,
    this.contactPhone,
    required this.schedule,
    this.scheduleNote,
  });

  factory ProSelfProfile.fromJson(Map<String, dynamic> json) {
    final contact = json['contact_details'] as Map<String, dynamic>?;
    final scheduleJson = json['schedule'] as List?;
    return ProSelfProfile(
      displayName: json['display_name'] as String? ?? '',
      bio: json['bio'] as String?,
      contactPhone: contact?['phone'] as String?,
      schedule: scheduleJson
              ?.map((e) => Timeslot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      scheduleNote: json['schedule_note'] as String?,
    );
  }
}

@riverpod
Future<ProSelfProfile> myProfessionalProfile(
  Ref ref,
  String professionalId,
) async {
  final response = await Supabase.instance.client
      .from('professional')
      .select('display_name, bio, contact_details, schedule, schedule_note')
      .eq('id', professionalId)
      .single()
      .timeout(const Duration(seconds: 5));

  return ProSelfProfile.fromJson(response);
}

/// Commits bio/contact/schedule edits. RLS ("Linked users can manage their
/// own professional profile") already scopes writes to the caller's own row.
@riverpod
class ProProfileEditController extends _$ProProfileEditController {
  final supabase = Supabase.instance.client;

  @override
  bool build(String professionalId) => false; // in-flight flag

  Future<void> commit({
    required String? bio,
    required String? contactPhone,
    required List<Timeslot> schedule,
    required String? scheduleNote,
  }) async {
    state = true;
    try {
      await supabase
          .from('professional')
          .update({
            'bio': bio,
            'contact_details': contactPhone == null || contactPhone.isEmpty
                ? null
                : {'phone': contactPhone},
            'schedule': schedule.map((t) => t.toJson()).toList(),
            'schedule_note': scheduleNote,
          })
          .eq('id', professionalId)
          .timeout(const Duration(seconds: 5));
      ref.invalidate(myProfessionalProfileProvider(professionalId));
    } finally {
      state = false;
    }
  }
}
