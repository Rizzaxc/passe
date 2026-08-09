import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../router.dart';
import '../ui/main.dart';
import 'model.dart';

class FreeplayCard extends StatelessWidget {
  final FreeplayActivity activity;
  final bool compact;

  const FreeplayCard({required this.activity, this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final day = DateFormat(
      'EEE, d/M',
      Localizations.localeOf(context).toString(),
    ).format(activity.startTime);
    final time =
        '${DateFormat('HH:mm').format(activity.startTime)}–${DateFormat('HH:mm').format(activity.endTime)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: POffsetFrame(
        offsetColor: pbAmber,
        borderRadius: BorderRadius.circular(16),
        child: FTappable(
          onPress: () => FreeplayDetailRoute(id: activity.id).push(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: pbAmber,
                      backgroundImage: activity.hostAvatarUrl == null
                          ? null
                          : NetworkImage(activity.hostAvatarUrl!),
                      child: activity.hostAvatarUrl == null
                          ? const Icon(FLucideIcons.ticket, size: 19)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.hostName.isEmpty
                                ? 'Xé vé'
                                : activity.hostName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.typography.body.md.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$day · $time',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.typography.body.sm.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${activity.acceptedCount}/${activity.capacity}',
                      style: context.theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(FLucideIcons.mapPin, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        activity.venueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (!compact && activity.description.isNotEmpty)
                  Text(
                    activity.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Pill(
                      label:
                          '${NumberFormat.decimalPattern('vi').format(activity.malePrice)}đ nam',
                    ),
                    _Pill(
                      label:
                          '${NumberFormat.decimalPattern('vi').format(activity.femalePrice)}đ nữ',
                    ),
                    ...activity.recommendedSkills.map(
                      (skill) => _Pill(label: _skillLabel(skill)),
                    ),
                    if (activity.myRequestStatus != null)
                      _Pill(label: _statusLabel(activity.myRequestStatus!)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _skillLabel(String value) => switch (value) {
    'beginner' => 'Mới chơi',
    'tryhard' => 'Cạnh tranh',
    _ => 'Phong trào',
  };

  static String _statusLabel(FreeplayRequestStatus status) => switch (status) {
    FreeplayRequestStatus.pending => 'Đang chờ',
    FreeplayRequestStatus.accepted => 'Đã nhận',
    FreeplayRequestStatus.declined => 'Bị từ chối',
    FreeplayRequestStatus.cancelled => 'Đã huỷ',
    FreeplayRequestStatus.hostCancelled => 'Host đã huỷ',
    FreeplayRequestStatus.lapsed => 'Hết hạn',
    FreeplayRequestStatus.blocked => 'Đã chặn',
  };
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: context.theme.colors.secondary,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: context.theme.typography.body.xs),
  );
}
