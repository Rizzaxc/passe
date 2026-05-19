import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../ui/theme.dart';

class AchievementsSubtab extends StatelessWidget {
  const AchievementsSubtab({super.key});

  static const _achievements = [
    _Achievement(
      title: 'Người chơi tích cực',
      detail: '12 hoạt động tháng này',
      progress: 0.80,
    ),
    _Achievement(
      title: 'Đồng đội tin cậy',
      detail: '5 lobby đã ghép thành',
      progress: 1.0,
    ),
    _Achievement(
      title: 'Champion',
      detail: '3/10 trận thắng',
      progress: 0.30,
    ),
    _Achievement(
      title: 'Xã giao vui vẻ',
      detail: '8/20 người bạn mới',
      progress: 0.40,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _achievements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _AchievementCard(achievement: _achievements[index]),
    );
  }
}

class _Achievement {
  final String title;
  final String detail;
  final double progress; // 0.0 – 1.0

  const _Achievement({
    required this.title,
    required this.detail,
    required this.progress,
  });
}

class _AchievementCard extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isComplete = achievement.progress >= 1.0;
    final barColor = isComplete ? pbGreen : const Color(0xFF959D54);
    final pct = (achievement.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: context.theme.style.borderRadius.md,
        boxShadow: context.theme.style.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 10,
            children: [
              // Badge icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: pbGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(FIcons.badgeCheck, size: 20, color: pbGreen),
              ),

              // Title + detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      achievement.title,
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      achievement.detail,
                      style: context.theme.typography.xs.copyWith(
                        color: colors.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Percentage
              Text(
                '$pct%',
                style: TextStyle(
                  fontFamily: context.theme.typography.sm.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                  height: 1,
                ),
              ),
            ],
          ),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: achievement.progress,
              minHeight: 6,
              backgroundColor: colors.secondary,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
