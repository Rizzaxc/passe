import 'package:flutter_test/flutter_test.dart';
import 'package:passe/core/pending_destination.dart';

void main() {
  test('an invite link survives sign-up and onboarding', () {
    final pending = PendingDestination();

    // Cold start from a tapped passe.vn/invite/CODE, signed out: the router
    // sees the deep link, then detours through welcome/auth, then the
    // onboarding sport pick.
    pending.observe(Uri.parse('/invite/AbC123'));
    pending.observe(Uri.parse('/welcome'));
    pending.observe(Uri.parse('/auth'));
    pending.observe(Uri.parse('/onboarding'));
    pending.observe(Uri.parse('/splash'));

    // Leaving onboarding spends it instead of the default landing tab.
    expect(pending.take('/discover/teammate'), '/invite/AbC123');
  });

  test('falls back to the landing tab when nothing was asked for', () {
    final pending = PendingDestination();
    pending.observe(Uri.parse('/splash'));
    pending.observe(Uri.parse('/onboarding'));
    expect(pending.take('/manage'), '/manage');
  });

  test('is spent once', () {
    final pending = PendingDestination()..observe(Uri.parse('/invite/X1Y2'));
    expect(pending.take('/feed'), '/invite/X1Y2');
    expect(pending.take('/feed'), '/feed');
  });

  test('keeps the query string', () {
    final pending = PendingDestination()
      ..observe(Uri.parse('/manage/lobby/abc?tab=1'));
    expect(pending.take('/feed'), '/manage/lobby/abc?tab=1');
  });

  test('every detour screen is skipped', () {
    for (final path in [
      '/splash',
      '/auth',
      '/welcome',
      '/forgot-password',
      '/reset-password',
      '/onboarding',
    ]) {
      expect(PendingDestination.isDetour(path), isTrue, reason: path);
    }
    expect(PendingDestination.isDetour('/invite/abc'), isFalse);
  });
}
