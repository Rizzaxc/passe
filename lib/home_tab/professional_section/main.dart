import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/enum.dart';
import '../../core/model/professional_feed_item.dart';
import '../../ui/main.dart';
import '../filter.dart';
import 'feed_controller.dart';

class ProfessionalSubtab extends ConsumerWidget {
  const ProfessionalSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(professionalFeedProvider);
    final roleFilter = ref.watch(professionalRoleFilterProvider);

    return Column(
      children: [
        PSectionHeader(
          title: 'home.professional'.tr(),
          suffix: const FilterWidget(),
        ),
        const SizedBox(height: 8),
        _RoleFilterBar(),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(professionalFeedProvider);
              await ref.read(professionalFeedProvider.future);
            },
            child: feed.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  PEmptySectionPlaceholder(
                    hero: Icon(
                      FIcons.searchX,
                      size: 64,
                      color: context.theme.colors.mutedForeground,
                    ),
                    title: 'homeTab.professional.empty.title'.tr(),
                    subtitle: 'homeTab.professional.empty.message'.tr(),
                  ),
                ],
              ),
              data: (items) {
                final filtered = roleFilter == null
                    ? items
                    : items.where((p) => p.role == roleFilter).toList();
                return filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          PEmptySectionPlaceholder(
                            hero: Icon(
                              FIcons.searchX,
                              size: 64,
                              color: context.theme.colors.mutedForeground,
                            ),
                            title: 'homeTab.professional.empty.title'.tr(),
                            subtitle: 'homeTab.professional.empty.message'.tr(),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _ProfessionalCard(item: filtered[index]),
                      );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleFilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(professionalRoleFilterProvider);
    final notifier = ref.read(professionalRoleFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          _FilterChip(
            label: 'homeTab.professional.filter.all'.tr(),
            selected: selected == null,
            onTap: () => notifier.set(null),
          ),
          _FilterChip(
            label: 'homeTab.professional.filter.coach'.tr(),
            selected: selected == ProfessionalRole.coach,
            onTap: () => notifier.set(ProfessionalRole.coach),
          ),
          _FilterChip(
            label: 'homeTab.professional.filter.referee'.tr(),
            selected: selected == ProfessionalRole.referee,
            onTap: () => notifier.set(ProfessionalRole.referee),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? context.theme.colors.primary
              : context.theme.colors.secondary,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: context.theme.typography.sm.copyWith(
            color: selected
                ? context.theme.colors.primaryForeground
                : context.theme.colors.secondaryForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final ProfessionalFeedItem item;

  const _ProfessionalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          // Name + verified + role badge
          Row(
            children: [
              Expanded(
                child: Row(
                  spacing: 4,
                  children: [
                    Flexible(
                      child: Text(
                        item.displayName,
                        style: context.theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isVerified)
                      Icon(FIcons.badgeCheck, size: 14, color: pbBlue),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RoleBadge(role: item.role),
            ],
          ),

          // Rating + reviews
          Row(
            spacing: 4,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
              Text(
                item.averageRating.toStringAsFixed(1),
                style: context.theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'homeTab.professional.reviews'
                    .tr(namedArgs: {'count': '${item.reviewCount}'}),
                style: context.theme.typography.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),

          // Experience
          if (item.experienceYears != null)
            Text(
              'homeTab.professional.experience'
                  .tr(namedArgs: {'years': '${item.experienceYears}'}),
              style: context.theme.typography.sm.copyWith(
                color: colors.mutedForeground,
              ),
            ),

          // Bio snippet
          if (item.bio != null && item.bio!.isNotEmpty)
            Text(
              item.bio!,
              style: context.theme.typography.sm.copyWith(
                color: colors.mutedForeground,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          FDivider(),

          Align(
            alignment: Alignment.centerRight,
            child: FButton(
              size: .sm,
              variant: .secondary,
              onPress: null, // TODO: booking flow TBD
              child: Text('homeTab.professional.book'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final ProfessionalRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pbBlue.withValues(alpha: 0.12),
        borderRadius: context.theme.style.borderRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          role.getLocalizedName(context),
          style: context.theme.typography.xs.copyWith(
            color: pbBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

