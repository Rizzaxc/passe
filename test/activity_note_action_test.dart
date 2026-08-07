import 'package:flutter_test/flutter_test.dart';
import 'package:passe/manage_tab/lobby_section/activity/feed.dart';
import 'package:passe/manage_tab/lobby_section/activity/feed_controller.dart';

void main() {
  group('activity note text', () {
    test('trims valid text', () {
      expect(normalizeActivityNote('  Mang áo trắng  '), 'Mang áo trắng');
    });

    test('rejects empty and messages longer than 72 characters', () {
      expect(() => normalizeActivityNote('   '), throwsArgumentError);
      expect(
        () => normalizeActivityNote(
          List.filled(maxActivityNoteLength + 1, 'a').join(),
        ),
        throwsArgumentError,
      );
    });

    test('accepts exactly 72 characters', () {
      final note = List.filled(maxActivityNoteLength, 'a').join();
      expect(normalizeActivityNote(note), note);
    });
  });

  test('note rows parse as activity-scoped personal items', () {
    final item = FeedItem.fromRow({
      'kind': 'personal',
      'payload': {'action_kind': 'note', 'detail': 'Tập trung ở cổng B'},
      'author_id': 'member-1',
      'author_username': 'An',
      'author_generated_avatar': null,
      'created_at': '2026-08-08T01:02:00Z',
      'activity_id': 'activity-1',
    });

    expect(item, isA<PersonalItem>());
    final note = item as PersonalItem;
    expect(note.action, PersonalActionKind.note);
    expect(note.detail, 'Tập trung ở cổng B');
    expect(note.activityId, 'activity-1');
    expect(perActivityFeedItems([note], 'activity-1'), [note]);
    expect(generalFeedItems([note]), isEmpty);
  });
}
