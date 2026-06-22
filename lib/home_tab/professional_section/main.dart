import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/enum.dart';
import '../../core/model/professional_feed_item.dart';
import '../../ui/main.dart';
import '../filter.dart';
import 'feed_controller.dart';

// ─── Subtab root ───────────────────────────────────────────────

class ProfessionalSubtab extends ConsumerWidget {
  const ProfessionalSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(professionalFeedProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(professionalFeedProvider);
        await ref.read(professionalFeedProvider.future);
      },
      child: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _Sections(coaches: [], referees: []),
        data: (items) {
          final coaches = items
              .where((p) => p.role == ProfessionalRole.coach)
              .toList();
          final referees = items
              .where((p) => p.role == ProfessionalRole.referee)
              .toList();
          return _Sections(coaches: coaches, referees: referees);
        },
      ),
    );
  }
}

// ─── Two vertically stacked sections ───────────────────────────

class _Sections extends StatelessWidget {
  final List<ProfessionalFeedItem> coaches;
  final List<ProfessionalFeedItem> referees;

  const _Sections({
    required this.coaches,
    required this.referees,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _Section(
          title: 'homeTab.professional.filter.coach'.tr(),
          items: coaches,
          suffix: const FilterWidget(),
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'homeTab.professional.filter.referee'.tr(),
          items: referees,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// A single section: clickable title + carousel (PageView) of cards + dots
class _Section extends StatefulWidget {
  final String title;
  final List<ProfessionalFeedItem> items;
  final Widget? suffix;

  const _Section({
    required this.title,
    required this.items,
    this.suffix,
  });

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  static const double _viewportFraction = 0.92;
  // Fraction of the viewport width the user must drag past the last
  // card. Scales with screen size — 18% of a 390-wide phone is ~70 px,
  // 18% of a 600-wide tablet is ~108 px, etc.
  static const double _overscrollFraction = 0.18;

  late final PageController _controller =
      PageController(viewportFraction: _viewportFraction);
  int _page = 0;
  bool _sheetOpening = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openSheet() async {
    if (_sheetOpening) return;
    _sheetOpening = true;
    await showPSheet<void>(
      context: context,
      maxHeightRatio: 0.9,
      builder: (_) => _ProfessionalSheet(
        title: widget.title,
        items: widget.items,
      ),
    );
    if (mounted) _sheetOpening = false;
  }

  bool _onScroll(ScrollNotification n) {
    // Only count position updates that came from an active user drag —
    // a fling settle overshoots past `maxScrollExtent` too, but its
    // ScrollUpdateNotifications carry `dragDetails == null`.
    if (n is! ScrollUpdateNotification || n.dragDetails == null) return false;

    final m = n.metrics;
    final overscroll = m.pixels - m.maxScrollExtent;
    final threshold = m.viewportDimension * _overscrollFraction;
    if (overscroll > threshold && !_sheetOpening) {
      _openSheet();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    // height: 1.0 collapses the line box to the glyph height, so the
    // icon and text bounding boxes are the same size — center alignment
    // in the Row then produces actual visual centering instead of
    // sitting both items on the line's baseline.
    final titleStyle = context.theme.typography.body.xl2.copyWith(
      fontWeight: FontWeight.bold,
      height: 1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            FTappable(
              onPress: widget.items.isEmpty ? null : _openSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(widget.title, style: titleStyle),
                    const SizedBox(width: 4),
                    Icon(
                      FLucideIcons.chevronRight,
                      size: titleStyle.fontSize,
                      color: colors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ?widget.suffix,
          ],
        ),
        const SizedBox(height: 10),
        if (widget.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'homeTab.professional.empty.message'.tr(),
              textAlign: TextAlign.center,
              style: context.theme.typography.body.sm.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          )
        else ...[
          SizedBox(
            height: 332,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                padEnds: false,
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ProfessionalCard(item: widget.items[i]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _PageDots(count: widget.items.length, active: _page),
        ],
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int active;

  const _PageDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active
                  ? colors.primary
                  : colors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

// ─── Testimonial-style card (avatar-prominent) ─────────────────

class _ProfessionalCard extends StatelessWidget {
  final ProfessionalFeedItem item;

  const _ProfessionalCard({required this.item});

  String get _initials {
    final cleaned = item.displayName
        .replaceAll(
          RegExp(r'^(hlv|coach|trọng tài)\s+', caseSensitive: false),
          '',
        )
        .trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isCoach = item.role == ProfessionalRole.coach;
    final accent = isCoach ? colors.primary : pbBlue;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prominent avatar
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials,
                        style: TextStyle(
                          fontFamily: context.theme.typography.body.xl2.fontFamily,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryForeground,
                          height: 1,
                        ),
                      ),
                    ),
                    if (item.isVerified)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colors.card,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            FLucideIcons.badgeCheck,
                            size: 20,
                            color: pbBlue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                item.displayName,
                style: context.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    item.averageRating.toStringAsFixed(1),
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${item.reviewCount})',
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Bio (testimonial quote) — fixed height, no flex
              SizedBox(
                height: 64,
                child: Text(
                  item.bio == null || item.bio!.isEmpty
                      ? ''
                      : '"${item.bio!}"',
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              FButton(
                size: .sm,
                variant: .secondary,
                onPress: () {},
                child: Text('homeTab.professional.book'.tr()),
              ),
            ],
          ),
        ),
    );
  }
}

// ─── "See all" sheet ───────────────────────────────────────────

class _ProfessionalSheet extends StatefulWidget {
  final String title;
  final List<ProfessionalFeedItem> items;

  const _ProfessionalSheet({
    required this.title,
    required this.items,
  });

  @override
  State<_ProfessionalSheet> createState() => _ProfessionalSheetState();
}

class _ProfessionalSheetState extends State<_ProfessionalSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      primary: false,
      child: Column(
        spacing: 16,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: context.theme.typography.body.xl2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FButton.icon(
                variant: .ghost,
                onPress: () => Navigator.of(context).pop(),
                child: const Icon(FLucideIcons.x),
              ),
            ],
          ),
          for (final item in widget.items) _SheetRow(item: item),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Sheet row — surfaces full info: bio, sports, experience, verification
class _SheetRow extends StatelessWidget {
  final ProfessionalFeedItem item;

  const _SheetRow({required this.item});

  String get _initials {
    final cleaned = item.displayName
        .replaceAll(
          RegExp(r'^(hlv|coach|trọng tài)\s+', caseSensitive: false),
          '',
        )
        .trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isCoach = item.role == ProfessionalRole.coach;
    final accent = isCoach ? colors.primary : pbBlue;

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: avatar + name + stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials,
                      style: TextStyle(
                        fontFamily: context.theme.typography.body.xl2.fontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryForeground,
                        height: 1,
                      ),
                    ),
                  ),
                  if (item.isVerified)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colors.card,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FLucideIcons.badgeCheck,
                          size: 18,
                          color: pbBlue,
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      item.displayName,
                      style: context.theme.typography.body.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.averageRating.toStringAsFixed(1),
                              style: context.theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${item.reviewCount} đánh giá)',
                              style: context.theme.typography.body.sm.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        if (item.experienceYears != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FLucideIcons.briefcaseBusiness,
                                size: 13,
                                color: colors.mutedForeground,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.experienceYears} năm kinh nghiệm',
                                style: context.theme.typography.body.sm.copyWith(
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Verified chip
          if (item.isVerified) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: pbBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Icon(FLucideIcons.badgeCheck, size: 12, color: pbBlue),
                    Text(
                      'Đã xác minh',
                      style: context.theme.typography.body.xs.copyWith(
                        color: pbBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Sports
          if (item.sports.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Môn',
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final sportIdx in item.sports)
                  _SportChip(
                    sport: sportIdx >= 0 && sportIdx < Sport.values.length
                        ? Sport.values[sportIdx]
                        : Sport.others,
                  ),
              ],
            ),
          ],

          // Full bio
          if (item.bio != null && item.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Giới thiệu',
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.bio!,
              style: context.theme.typography.body.sm.copyWith(
                color: colors.foreground,
                height: 1.5,
              ),
            ),
          ],

          // Actions
          const SizedBox(height: 14),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: FButton(
                  variant: .outline,
                  onPress: () {},
                  child: const Text('Xem Hồ Sơ'),
                ),
              ),
              Expanded(
                child: FButton(
                  onPress: () {},
                  child: Text('homeTab.professional.book'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SportChip extends StatelessWidget {
  final Sport sport;

  const _SportChip({required this.sport});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          sport.getIcon(size: 12),
          Text(
            sport.getLocalizedName(context),
            style: context.theme.typography.body.xs.copyWith(
              color: colors.secondaryForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
