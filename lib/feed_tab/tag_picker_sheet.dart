import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ui/main.dart';
import 'compose_controller.dart';

/// Pick up to 5 people to tag. The candidate list is the session's attendees
/// plus its lobby's members (attendees first) — tagging someone who didn't
/// RSVP is deliberate, so absentees can still be named.
///
/// Returns the chosen users, or null if dismissed.
Future<List<TaggableUser>?> showTagPickerSheet(
  BuildContext context, {
  String? activityId,
  required List<TaggableUser> initial,
}) {
  return showPSheet<List<TaggableUser>>(
    context: context,
    maxHeightRatio: 1.0,
    builder: (_) => _TagPickerSheet(
      activityId: activityId,
      initial: initial,
    ),
  );
}

const _maxTags = 5;

class _TagPickerSheet extends ConsumerStatefulWidget {
  final String? activityId;
  final List<TaggableUser> initial;

  const _TagPickerSheet({
    required this.initial,
    this.activityId,
  });

  @override
  ConsumerState<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends ConsumerState<_TagPickerSheet> {
  late final Set<String> _selected = {...widget.initial.map((t) => t.userId)};

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(taggableUsersProvider(
      activityId: widget.activityId,
    ));

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'feed.tagPeople'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          Text(
            'feed.tagLimit'.tr(namedArgs: {'max': '$_maxTags'}),
            style: context.theme.typography.body.xs
                .copyWith(color: context.theme.colors.mutedForeground),
            textAlign: TextAlign.center,
          ),
          candidatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) =>
                PEmptySectionPlaceholder(subtitle: 'feed.tagsError'.tr()),
            data: (candidates) {
              if (candidates.isEmpty) {
                return PEmptySectionPlaceholder(
                  subtitle: 'feed.noTagCandidates'.tr(),
                );
              }
              return Column(
                children: [
                  for (final c in candidates)
                    FTile(
                      prefix: PUserAvatar(
                        userId: c.userId,
                        username: c.username,
                        generatedAvatar: c.generatedAvatar,
                        radius: 16,
                      ),
                      title: Text(
                        c.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(c.attended
                          ? 'feed.tagAttended'.tr()
                          : 'feed.tagMember'.tr()),
                      suffix: _selected.contains(c.userId)
                          ? Icon(FLucideIcons.circleCheck,
                              color: context.theme.colors.primary)
                          : const Icon(FLucideIcons.circle),
                      onPress: () => setState(() {
                        if (_selected.contains(c.userId)) {
                          _selected.remove(c.userId);
                        } else if (_selected.length < _maxTags) {
                          _selected.add(c.userId);
                        }
                      }),
                    ),
                  FButton(
                    onPress: () => Navigator.of(context).pop(
                      candidates
                          .where((c) => _selected.contains(c.userId))
                          .toList(),
                    ),
                    child: Text('feed.tagConfirm'
                        .tr(namedArgs: {'count': '${_selected.length}'})),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
