import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_activity_booking_state.g.dart';

/// One-shot hand-off for lobby-scoped booking: a captain/coordinator tapping
/// "Đặt HLV / Trọng tài" on an activity sets this to that activity's id
/// before navigating to professional discovery (there's no lobby-scoped
/// booking screen — the general discovery flow is reused, per the grill-me
/// decision). The booking sheet reads and immediately clears it on submit,
/// so it can only ever attach to the very next booking created — if the
/// user wanders off and books something unrelated first, that consumes and
/// clears the flag instead of misattaching a later one.
@riverpod
class PendingActivityBookingState extends _$PendingActivityBookingState {
  @override
  String? build() => null;

  void set(String? activityId) => state = activityId;

  /// Reads and clears in one step.
  String? consume() {
    final id = state;
    state = null;
    return id;
  }
}
