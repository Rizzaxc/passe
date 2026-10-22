import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/legacy.dart';

import '../ui/main.dart';
import 'challenger_section/main.dart';
import 'filter.dart';
import 'freeplay_section/main.dart';
import 'location_section/main.dart';
import 'professional_section/main.dart';
import 'teammate_section/main.dart';

/// Set (then immediately consumed) to switch the Discover subtab from a
/// widget that isn't `_DiscoverView` itself — e.g. a CTA inside one subtab
/// that wants to send the user to another (`0` freeplay, `1` teammate, then
/// the enabled discovery sections). Do NOT navigate via the `Discover*Route`s
/// for this — those are nested routes *within* the Discover branch, so
/// `.go()`ing between them from inside Discover pushes a new stacked page
/// instead of just switching the tab (the `Discover*Route`s exist for
/// deep-linking into Discover *from another tab*, where crossing branches is
/// the correct, expected nav).
final discoverSubtabRequestProvider = StateProvider<int?>((ref) => null);

/// Discover — five subtabs, switched by a labelled chip rail, sharing one
/// filter whose summary sits under the rail. All scoped to the context
/// sport. Feed (the social surface) moved out to its own main tab — see
/// `lib/feed_tab/` — so this is back to being a single-purpose screen.
class DiscoverTab extends ConsumerWidget {
  final int initialIndex;

  /// Auto-opens the shared filter sheet once the teammate subtab has laid
  /// out — used by the onboarding Get Started sheet's "Tìm đồng đội" tile so
  /// a new user sets real search criteria instead of landing on whatever
  /// the default (profile-seeded) filter happens to return. Only wired for
  /// the teammate subtab; ignored on any other `initialIndex`.
  final bool openFilter;

  const DiscoverTab({super.key, this.initialIndex = 0, this.openFilter = false})
    : assert(initialIndex >= 0 && initialIndex < tabCount);

  static final instance = DiscoverTab();

  /// Challenger ships as the friendly (referee-free) mode, so the subtab is
  /// always present. `ClientFeatureFlags.challengerFlow` now gates only the
  /// REFEREED variant's extra affordances (hiring an official, pro-mode result
  /// entry) — not whether a lobby can challenge another at all.
  static const tabCount = 5;
  // Teammates first (the default landing), Freeplay third. Always go through
  // these names — never a literal index — so a reorder is a one-place change.
  static const teammateIndex = 0;
  static const challengerIndex = 1;
  static const freeplayIndex = 2;
  static const professionalIndex = 3;
  static int get locationIndex => tabCount - 1;

  /// Deep-links a Discover subtab using one of the indices above.
  factory DiscoverTab.withInitialTab(int initialIndex, {bool openFilter = false}) {
    return DiscoverTab(initialIndex: initialIndex, openFilter: openFilter);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FScaffold(
      header: FHeader(
        title: Text('nav.discover'.tr()),
        suffixes: [const NotificationIconButton()],
      ),
      child: _DiscoverView(initialIndex: initialIndex, openFilter: openFilter),
    );
  }
}

/// Chip rail + filter summary over the active subtab. Replaced a 5-icon
/// `FTabs`: five unlabelled icons from three icon sets read as noise, and the
/// filter was a separate icon on every subtab header.
class _DiscoverView extends ConsumerStatefulWidget {
  final int initialIndex;
  final bool openFilter;

  const _DiscoverView({required this.initialIndex, this.openFilter = false});

  @override
  ConsumerState<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends ConsumerState<_DiscoverView> {
  late int _currentIndex = widget.initialIndex;

  List<PRailTab> get _tabs => [
    PRailTab(
      icon: FLucideIcons.users,
      label: 'discover.rail.teammate'.tr(),
      build: () => TeammateSubtab(openFilter: widget.openFilter),
    ),
    PRailTab(
      icon: FLucideIcons.swords,
      label: 'discover.rail.challenger'.tr(),
      build: () => const ChallengerSubtab(),
    ),
    PRailTab(
      icon: FLucideIcons.ticket,
      label: 'discover.rail.freeplay'.tr(),
      build: () => const FreeplaySubtab(),
    ),
    PRailTab(
      icon: FLucideIcons.graduationCap,
      label: 'discover.rail.professional'.tr(),
      build: () => const ProfessionalSubtab(),
    ),
    PRailTab(
      icon: FLucideIcons.mapPin,
      label: 'discover.rail.location'.tr(),
      build: () => const LocationSubtab(),
    ),
  ];

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(discoverSubtabRequestProvider, (_, requested) {
      if (requested == null) return;
      ref.read(discoverSubtabRequestProvider.notifier).state = null;
      _onTabChanged(requested);
    });

    final tabs = _tabs;
    assert(tabs.length == DiscoverTab.tabCount);

    return PRailTabs(
      tabs: tabs,
      index: _currentIndex,
      onChanged: _onTabChanged,
      header: FilterSummaryChip(
        showRoleFilter: _currentIndex == DiscoverTab.professionalIndex,
      ),
    );
  }
}
