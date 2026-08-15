import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/legacy.dart';
import '../core/feature_flags.dart';
import '../core/sport_selector.dart';
import '../ui/main.dart';
import 'challenger_section/main.dart';
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

/// Discover — four shipped subtabs sharing one filter, all scoped to
/// the context sport. Challenger is inserted only for explicitly enabled
/// builds. Feed (the social surface) moved out to its own main tab — see
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

  /// Indices after teammate shift down in default builds because Challenger
  /// is compiled as an opt-in client feature.
  static const tabCount = ClientFeatureFlags.challengerFlow ? 5 : 4;
  static int get challengerIndex => ClientFeatureFlags.challengerFlow ? 2 : 0;
  static int get professionalIndex => ClientFeatureFlags.challengerFlow ? 3 : 2;
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
        suffixes: [const NotificationIconButton(), const SportSelector()],
      ),
      child: _DiscoverView(initialIndex: initialIndex, openFilter: openFilter),
    );
  }
}

/// Shipped subtabs over a shared filter, plus opt-in Challenger.
class _DiscoverView extends ConsumerStatefulWidget {
  final int initialIndex;
  final bool openFilter;

  const _DiscoverView({required this.initialIndex, this.openFilter = false});

  @override
  ConsumerState<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends ConsumerState<_DiscoverView> {
  late int _currentIndex;
  // Which subtabs are actually inflated right now. TabBarView's sliver
  // viewport has a default 250px cache extent on both sides of the visible
  // page, so — since each subtab is a full-screen-width page — the tab next
  // to the active one gets fully built (including firing its own feed RPC)
  // even though none of it is on screen. Rendering everything but the
  // active + just-left index as a cheap SizedBox defeats that, while still
  // keeping both pages alive for the slide transition itself.
  late final Set<int> _builtIndices;
  Timer? _settleTimer;

  // Instance getter (not `static const`) because the teammate entry needs
  // `widget.openFilter` threaded in.
  List<({Widget icon, Widget child})> get _sections => [
    (icon: const Icon(FLucideIcons.ticket), child: const FreeplaySubtab()),
    (
      icon: const Icon(CupertinoIcons.person_2_fill),
      child: TeammateSubtab(openFilter: widget.openFilter),
    ),
    if (ClientFeatureFlags.challengerFlow)
      (
        icon: const FaIcon(FontAwesomeIcons.fireFlameCurved),
        child: const ChallengerSubtab(),
      ),
    (
      icon: const FaIcon(FontAwesomeIcons.flagCheckered),
      child: const ProfessionalSubtab(),
    ),
    (
      icon: const FaIcon(FontAwesomeIcons.locationDot),
      child: const LocationSubtab(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _builtIndices = {_currentIndex};
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged(int index) {
    _settleTimer?.cancel();
    setState(() {
      _currentIndex = index;
      _builtIndices.add(index);
    });
    // Drop the outgoing subtab once its slide-out animation has had time to
    // finish, rather than instantly — so the transition still shows real
    // content sliding out instead of blank space.
    _settleTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _builtIndices
          ..clear()
          ..add(_currentIndex);
      });
    });
  }

  List<FTabEntry> _buildTabEntries() {
    final sections = _sections;
    assert(sections.length == DiscoverTab.tabCount);
    return List.generate(sections.length, (index) {
      final section = sections[index];
      final built = _builtIndices.contains(index);

      return FTabEntry(
        label: KeyedSubtree(key: const ValueKey('icon'), child: section.icon),
        child: built ? section.child : const SizedBox.shrink(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(discoverSubtabRequestProvider, (_, requested) {
      if (requested == null) return;
      ref.read(discoverSubtabRequestProvider.notifier).state = null;
      if (requested != _currentIndex) _onTabChanged(requested);
    });

    return FTabs(
      expands: true,
      contentPhysics: const NeverScrollableScrollPhysics(),
      control: FTabControl.lifted(
        index: _currentIndex,
        onChange: _onTabChanged,
      ),
      children: _buildTabEntries(),
    );
  }
}
