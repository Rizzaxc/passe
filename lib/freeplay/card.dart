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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FTappable(
        onPress: () => FreeplayDetailRoute(id: activity.id).push(context),
        child: FreeplayActivitySummaryCard(
          activity: activity,
          compact: compact,
        ),
      ),
    );
  }
}

/// Shared freeplay session surface. It deliberately follows Lobby Hub's
/// activity-card hierarchy while keeping freeplay's Host, gender pricing and
/// recommended-level metadata.
class FreeplayActivitySummaryCard extends StatelessWidget {
  final FreeplayActivity activity;
  final bool compact;
  final bool showHost;
  final bool showAddress;
  final bool showMetadata;

  const FreeplayActivitySummaryCard({
    required this.activity,
    this.compact = false,
    this.showHost = true,
    this.showAddress = false,
    this.showMetadata = true,
    super.key,
  });

  static String skillLabel(String value) => switch (value) {
    'beginner' => 'freeplay.skill.beginner',
    'fair' => 'freeplay.skill.fair',
    'good' => 'freeplay.skill.good',
    'advanced' => 'freeplay.skill.advanced',
    _ => 'freeplay.skill.casual',
  };

  static String statusLabel(FreeplayRequestStatus status) => switch (status) {
    FreeplayRequestStatus.pending => 'freeplay.status.pending',
    FreeplayRequestStatus.accepted => 'freeplay.status.accepted',
    FreeplayRequestStatus.declined => 'freeplay.status.declined',
    FreeplayRequestStatus.cancelled => 'freeplay.status.cancelled',
    FreeplayRequestStatus.hostCancelled => 'freeplay.status.hostCancelled',
    FreeplayRequestStatus.lapsed => 'freeplay.status.lapsed',
    FreeplayRequestStatus.blocked => 'freeplay.status.blocked',
  };

  String _money(BuildContext context, num amount) =>
      NumberFormat.simpleCurrency(
        locale: context.locale.toLanguageTag(),
        name: 'VND',
        decimalDigits: 0,
      ).format(amount);

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final day = DateFormat(
      'EEE, d/M',
      context.locale.toLanguageTag(),
    ).format(activity.startTime);
    final time =
        '${DateFormat('HH:mm').format(activity.startTime)} – '
        '${DateFormat('HH:mm').format(activity.endTime)}';

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 3, color: pbAmber),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: colors.foreground,
                    letterSpacing: -0.5,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC58A1A),
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      FLucideIcons.mapPin,
                      size: 14,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.venueName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (showAddress &&
                              activity.streetAddress.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              activity.streetAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.theme.typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (showMetadata) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Tag(
                        icon: FLucideIcons.users,
                        label: 'freeplay.peopleCount'.tr(
                          namedArgs: {
                            'accepted': '${activity.acceptedCount}',
                            'capacity': '${activity.capacity}',
                          },
                        ),
                      ),
                      _Tag(
                        label: 'freeplay.malePrice'.tr(
                          namedArgs: {
                            'amount': _money(context, activity.malePrice),
                          },
                        ),
                      ),
                      _Tag(
                        label: 'freeplay.femalePrice'.tr(
                          namedArgs: {
                            'amount': _money(context, activity.femalePrice),
                          },
                        ),
                      ),
                      ...activity.recommendedSkills.map(
                        (skill) => _Tag(label: skillLabel(skill).tr()),
                      ),
                      if (activity.myRequestStatus != null)
                        _Tag(
                          icon: FLucideIcons.circleCheck,
                          label: statusLabel(activity.myRequestStatus!).tr(),
                          emphasized: true,
                        ),
                    ],
                  ),
                ],
                if (!compact && activity.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    activity.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.sm.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
                if (showHost) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: colors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: pbAmber,
                        backgroundImage: activity.hostAvatarUrl == null
                            ? null
                            : NetworkImage(activity.hostAvatarUrl!),
                        child: activity.hostAvatarUrl == null
                            ? const Icon(FLucideIcons.ticket, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.hostName.isEmpty
                                  ? 'freeplay.title'.tr()
                                  : activity.hostName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'freeplay.verifiedHost'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.theme.typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool emphasized;

  const _Tag({required this.label, this.icon, this.emphasized = false});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width - 64,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? pbAmber.withValues(alpha: 0.18)
            : context.theme.colors.secondary,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.xs.copyWith(
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
