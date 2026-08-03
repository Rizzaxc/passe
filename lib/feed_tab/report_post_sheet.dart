import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../ui/main.dart';
import 'feed_controller.dart';

/// Report reasons — must match the CHECK on `wall_post_report.reason`.
const _reasons = ['spam', 'harassment', 'nudity', 'violence', 'impersonation', 'other'];

void showReportPostSheet(BuildContext context, {required String postId}) {
  showPSheet(
    context: context,
    builder: (_) => _ReportPostSheet(postId: postId),
  );
}

class _ReportPostSheet extends ConsumerStatefulWidget {
  final String postId;

  const _ReportPostSheet({required this.postId});

  @override
  ConsumerState<_ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends ConsumerState<_ReportPostSheet> {
  String? _reason;
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _sending = true);

    try {
      await Supabase.instance.client.from('wall_post_report').insert({
        'post_id': widget.postId,
        'reason': _reason,
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      }).timeout(const Duration(seconds: 5));

      // A report may have crossed the auto-hide threshold, which drops the
      // post out of the feed for everyone — refetch rather than leave a
      // now-hidden post on screen.
      ref.invalidate(wallFeedControllerProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.check),
        title: Text('feed.reportSent'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'Report post failed');
      if (!mounted) return;
      // A second report from the same person trips the (post_id, reporter_id)
      // primary key — that's "already reported", not a failure.
      if (e.toString().contains('duplicate key')) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.info),
          title: Text('feed.reportAlready'.tr()),
          alignment: .bottomCenter,
        );
      } else {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('feed.reportFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'feed.reportPost'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          for (final reason in _reasons)
            FTile(
              title: Text('feed.reportReason.$reason'.tr()),
              suffix: _reason == reason
                  ? Icon(FLucideIcons.check,
                      color: context.theme.colors.primary)
                  : null,
              onPress: () => setState(() => _reason = reason),
            ),
          FTextField(
            hint: 'feed.reportNoteHint'.tr(),
            maxLines: 3,
            control: FTextFieldControl.managed(controller: _note),
          ),
          FButton(
            variant: .destructive,
            onPress: _reason == null || _sending ? null : _submit,
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('feed.reportSend'.tr()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
