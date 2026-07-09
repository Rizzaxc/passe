import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/format.dart';
import '../../core/model/enum.dart';
import '../../core/model/professional_feed_item.dart';
import '../../professional/booking_sheet.dart';
import '../../router.dart';
import '../../ui/main.dart';
import '../filter.dart';
import 'feed_controller.dart';

// ─── Shared helpers ────────────────────────────────────────────

/// Opens the full-page profile for a coach / referee. The model is passed as
/// `$extra` so the detail page renders immediately without a refetch.
void _openDetail(BuildContext context, ProfessionalFeedItem item) {
  ProfessionalDetailRoute(id: item.id, $extra: item).push(context);
}

String _initialsOf(String displayName) {
  final cleaned = displayName
      .replaceAll(
        RegExp(r'^(hlv|coach|trọng tài)\s+', caseSensitive: false),
        '',
      )
      .trim();
  final parts = cleaned.split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

// ─── Subtab root ───────────────────────────────────────────────

class ProfessionalSubtab extends ConsumerWidget {
  const ProfessionalSubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surface load errors as a toast (matching the schedule feed) rather than
    // silently rendering empty sections.
    ref.listen(professionalFeedProvider, (_, next) {
      if (next is AsyncError && context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('error'.tr()),
          description: Text('errorGeneric'.tr()),
          alignment: .bottomCenter,
        );
      }
    });

    final feed = ref.watch(professionalFeedProvider);
    // Role visibility lives in the shared filter (checkboxes in the filter
    // sheet), each role toggled independently.
    final visibleRoles = ref.watch(
      filterStateProvider.select((f) => f.visibleRoles),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(professionalFeedProvider);
        await ref.read(professionalFeedProvider.future);
      },
      child: feed.when(
        loading: () => const _LoadingSkeleton(),
        error: (_, _) => _Sections(
          coaches: const [],
          referees: const [],
          visibleRoles: visibleRoles,
        ),
        data: (items) {
          final coaches = items
              .where((p) => p.role == ProfessionalRole.coach)
              .toList();
          final referees = items
              .where((p) => p.role == ProfessionalRole.referee)
              .toList();
          return _Sections(
            coaches: coaches,
            referees: referees,
            visibleRoles: visibleRoles,
          );
        },
      ),
    );
  }
}

// ─── The (role-filtered) sections ──────────────────────────────

class _Sections extends StatelessWidget {
  final List<ProfessionalFeedItem> coaches;
  final List<ProfessionalFeedItem> referees;
  final Set<ProfessionalRole> visibleRoles;

  const _Sections({
    required this.coaches,
    required this.referees,
    required this.visibleRoles,
  });

  @override
  Widget build(BuildContext context) {
    final showCoaches = visibleRoles.contains(ProfessionalRole.coach);
    final showReferees = visibleRoles.contains(ProfessionalRole.referee);

    // Each role can now be hidden independently (checkboxes, not a single
    // either/or toggle), so the filter needs to stay reachable from
    // whichever section(s) are actually on screen — every visible role
    // header gets its own suffix, not just the first one.
    const filterSuffix = FilterWidget(showRoleFilter: true);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      children: [
        if (showCoaches)
          _Section(
            title: 'homeTab.professional.filter.coach'.tr(),
            items: coaches,
            filterSuffix: filterSuffix,
          ),
        if (showCoaches && showReferees) const SizedBox(height: 24),
        if (showReferees)
          _Section(
            title: 'homeTab.professional.filter.referee'.tr(),
            items: referees,
            filterSuffix: filterSuffix,
          ),
      ],
    );
  }
}

// A single role section: header (tappable + "see all") + carousel + dots.
// This header is this screen's equivalent of the teammate/challenger/
// location subtabs' single PSectionHeader — there are two of them (one per
// role) instead of one, so [filterSuffix] (the subtab-wide filter) is on
// every visible one, same as PSectionHeader's own title+suffix shape.
class _Section extends StatefulWidget {
  final String title;
  final List<ProfessionalFeedItem> items;
  final Widget? filterSuffix;

  const _Section({required this.title, required this.items, this.filterSuffix});

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  static const double _viewportFraction = 0.92;
  // Fraction of the viewport width the user must drag past the last card
  // before the full-list sheet opens. Kept low so the gesture is easy to
  // trigger; the explicit "Xem tất cả" header action is the primary path.
  static const double _overscrollFraction = 0.10;

  late final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
  );
  int _page = 0;
  bool _sheetOpening = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openSheet() async {
    if (_sheetOpening || widget.items.isEmpty) return;
    _sheetOpening = true;
    await showPSheet<void>(
      context: context,
      maxHeightRatio: 0.9,
      builder: (_) =>
          _ProfessionalSheet(title: widget.title, items: widget.items),
    );
    if (mounted) _sheetOpening = false;
  }

  bool _onScroll(ScrollNotification n) {
    // Only react to an active user drag past the end (a fling settle also
    // overshoots, but carries dragDetails == null).
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
    final titleStyle = context.theme.typography.body.xl2.copyWith(
      fontWeight: FontWeight.bold,
      height: 1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // Same shape as PSectionHeader: Expanded(title) + suffix. Title
          // and chevron are one tappable unit; only the title itself is
          // Flexible/ellipsized so the chevron (and the filter suffix,
          // when present) never get squeezed off — that race between the
          // title and a trailing element is what overflowed on iPhone 13
          // when this used an unguarded "Xem tất cả" label instead.
          child: Row(
            children: [
              Expanded(
                child: FTappable(
                  onPress: widget.items.isEmpty ? null : _openSheet,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: titleStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.items.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Icon(
                            FLucideIcons.chevronRight,
                            size: 20,
                            color: colors.mutedForeground,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              ?widget.filterSuffix,
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (widget.items.isEmpty)
          PEmptySectionPlaceholder(
            subtitle: 'homeTab.professional.empty.message'.tr(),
          )
        else ...[
          SizedBox(
            height: 320,
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
                  child: Center(
                    child: _ProfessionalCard(item: widget.items[i]),
                  ),
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
              color: i == active ? colors.primary : colors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

// ─── Avatar (initials fallback; ready for a real photo) ────────

class _ProAvatar extends StatelessWidget {
  final ProfessionalFeedItem item;
  final double size;

  const _ProAvatar({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary,
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.24),
                blurRadius: size * 0.18,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            _initialsOf(item.displayName),
            style: TextStyle(
              fontFamily: context.theme.typography.body.xl2.fontFamily,
              fontSize: size * 0.38,
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
                size: size * 0.26,
                color: pbBlue,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Discovery card ────────────────────────────────────────────

class _ProfessionalCard extends StatelessWidget {
  final ProfessionalFeedItem item;

  const _ProfessionalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return FTappable(
      onPress: () => _openDetail(context, item),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _ProAvatar(item: item, size: 76)),
              const SizedBox(height: 12),
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
              // Rating + price on one line. A high review count or a long
              // price both push this wide enough to overflow a narrow phone
              // (this exact row overflowed on iPhone 13) — a single
              // Text.rich in a Flexible truncates instead of ever
              // rendering past the card's edge.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FLucideIcons.star, size: 13, color: pbStar),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: item.averageRating.toStringAsFixed(1),
                            style: context.theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' (${item.reviewCount})',
                            style: context.theme.typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                          if (item.priceFrom != null) ...[
                            TextSpan(
                              text: '  ·  ',
                              style: context.theme.typography.body.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                            TextSpan(
                              text: 'từ ${formatVnd(item.priceFrom!)}₫/giờ',
                              style: context.theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: Text(
                  item.bio ?? '',
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              FButton(
                variant: .secondary,
                onPress: () => _openDetail(context, item),
                child: Text('homeTab.professional.viewProfile'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loading skeleton ──────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      children: [
        bar(double.infinity, 40),
        const SizedBox(height: 20),
        for (var s = 0; s < 2; s++) ...[
          bar(160, 24),
          const SizedBox(height: 12),
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: colors.muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  bar(140, 16),
                  const SizedBox(height: 8),
                  bar(180, 12),
                  const SizedBox(height: 16),
                  bar(double.infinity, 36),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

// ─── "See all" sheet ───────────────────────────────────────────

class _ProfessionalSheet extends StatefulWidget {
  final String title;
  final List<ProfessionalFeedItem> items;

  const _ProfessionalSheet({required this.title, required this.items});

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

// Sheet row — surfaces full info: bio, sports, experience, verification, price.
class _SheetRow extends StatelessWidget {
  final ProfessionalFeedItem item;

  const _SheetRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return FTappable(
      onPress: () => _openDetail(context, item),
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [
                _ProAvatar(item: item, size: 64),
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
                              Icon(FLucideIcons.star, size: 15, color: pbStar),
                              const SizedBox(width: 3),
                              Text(
                                item.averageRating.toStringAsFixed(1),
                                style: context.theme.typography.body.sm
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${item.reviewCount} đánh giá)',
                                style: context.theme.typography.body.sm
                                    .copyWith(color: colors.mutedForeground),
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
                                  style: context.theme.typography.body.sm
                                      .copyWith(color: colors.mutedForeground),
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

            if (item.priceFrom != null) ...[
              const SizedBox(height: 12),
              Text(
                'từ ${formatVnd(item.priceFrom!)}₫/giờ',
                style: context.theme.typography.body.lg.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],

            if (item.sports.isNotEmpty) ...[
              const SizedBox(height: 12),
              _RowLabel('Môn'),
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

            if (item.bio != null && item.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _RowLabel('Giới thiệu'),
              const SizedBox(height: 4),
              Text(
                item.bio!,
                style: context.theme.typography.body.sm.copyWith(
                  color: colors.foreground,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 14),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FButton(
                    variant: .outline,
                    onPress: () => _openDetail(context, item),
                    child: Text('homeTab.professional.viewProfile'.tr()),
                  ),
                ),
                Expanded(
                  child: FButton(
                    onPress: () => showProfessionalBookingSheet(context, item),
                    child: Text('homeTab.professional.book'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  final String text;

  const _RowLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.theme.typography.body.xs.copyWith(
        color: context.theme.colors.mutedForeground,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
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
