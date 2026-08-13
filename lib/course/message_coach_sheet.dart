import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../router.dart';
import '../ui/main.dart';
import 'course_controller.dart';

/// The very first contact with a coach — deliberately NOT backed by a real
/// conversation yet. Nothing is written server-side until [_send] actually
/// succeeds: a student who opens this and backs out leaves no trace, no
/// course, no notification, nothing for the coach to see. Compare
/// `ConversationView`, which always has a real `conversationId` to load —
/// this sheet exists precisely because that one doesn't apply until this
/// first message lands.
///
/// `message_coach` does course-creation-if-needed and the send atomically —
/// "the first message creates the course thread", literally, not just in
/// spirit.
Future<void> showMessageCoachSheet(
  BuildContext context, {
  required String professionalId,
  required int sportId,
  required String coachName,
}) => showPSheet(
  context: context,
  maxHeightRatio: 1,
  builder: (_) => _MessageCoachSheet(
    professionalId: professionalId,
    sportId: sportId,
    coachName: coachName,
  ),
);

class _MessageCoachSheet extends ConsumerStatefulWidget {
  final String professionalId;
  final int sportId;
  final String coachName;

  const _MessageCoachSheet({
    required this.professionalId,
    required this.sportId,
    required this.coachName,
  });

  @override
  ConsumerState<_MessageCoachSheet> createState() =>
      _MessageCoachSheetState();
}

class _MessageCoachSheetState extends ConsumerState<_MessageCoachSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final courseId = await ref
          .read(courseActionControllerProvider.notifier)
          .messageCoach(widget.professionalId, widget.sportId, text);
      if (!mounted) return;
      Navigator.pop(context);
      // go(), not push(): CourseDetailRoute is nested under the Manage tab's
      // shell branch; this sheet was opened from the (root-level) coach
      // profile. See professional/main.dart's _messageCoach for the full
      // rationale — same collision this fix already applies to.
      CourseDetailRoute(id: courseId).go(context);
    } catch (e, st) {
      Talker().handle(e, st, 'Message coach failed');
      if (mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text('course.actionFailed'.tr()),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSheetTitle(
            label: widget.coachName,
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.pop(context),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'course.messageCoachIntro'.tr(namedArgs: {
                    'coach': widget.coachName,
                  }),
                  textAlign: TextAlign.center,
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(controller: _controller),
                  hint: 'messaging.messageHint'.tr(),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              FButton.icon(
                onPress: _sending ? null : _send,
                child: _sending
                    ? const FCircularProgress()
                    : const Icon(FLucideIcons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
