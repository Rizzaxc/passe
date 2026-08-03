import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/sport_selector.dart';
import '../ui/main.dart';
import 'challenger_section/main.dart';
import 'location_section/main.dart';
import 'professional_section/main.dart';
import 'teammate_section/main.dart';

/// Home ▸ Discover — four subtabs sharing one filter, all scoped to the
/// context sport. Feed (the social surface) moved out to its own main tab —
/// see `lib/feed_tab/` — so this is back to being a single-purpose screen.
class HomeTab extends ConsumerWidget {
  final int initialIndex;

  const HomeTab({super.key, this.initialIndex = 0})
    : assert(initialIndex >= 0 && initialIndex <= 3);

  static final instance = HomeTab();

  /// Deep-links a Discover subtab (`0` teammate, `1` challenger,
  /// `2` professional, `3` location — see the `Home*Route` classes in
  /// `router.dart`).
  factory HomeTab.withInitialTab(int initialIndex) {
    return HomeTab(initialIndex: initialIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FScaffold(
      header: FHeader(
        title: Text('nav.discover'.tr()),
        suffixes: [const NotificationIconButton(), const SportSelector()],
      ),
      child: _DiscoverView(initialIndex: initialIndex),
    );
  }
}

/// Four subtabs over a shared filter.
class _DiscoverView extends ConsumerStatefulWidget {
  final int initialIndex;

  const _DiscoverView({required this.initialIndex});

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

  static const _sections = [
    (titleKey: 'home.teammate', child: TeammateSubtab()),
    (titleKey: 'home.challenger', child: ChallengerSubtab()),
    (titleKey: 'home.professional', child: ProfessionalSubtab()),
    (titleKey: 'home.location', child: LocationSubtab()),
  ];

  static const _icons = [
    Icon(CupertinoIcons.person_2_fill),
    FaIcon(FontAwesomeIcons.fireFlameCurved),
    FaIcon(FontAwesomeIcons.flagCheckered),
    FaIcon(FontAwesomeIcons.locationDot),
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
    return List.generate(_sections.length, (index) {
      final section = _sections[index];
      final built = _builtIndices.contains(index);

      return FTabEntry(
        label: KeyedSubtree(key: const ValueKey('icon'), child: _icons[index]),
        child: built ? section.child : const SizedBox.shrink(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
