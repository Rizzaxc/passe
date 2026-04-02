import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/sport_selector.dart';
import '../ui/main.dart';
import 'challenger_section/main.dart';
import 'filter.dart';
import 'location_section/main.dart';
import 'professional_section/main.dart';
import 'teammate_section/main.dart';

class HomeTab extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeTab({super.key, this.initialIndex = 0})
    : assert(initialIndex >= 0 && initialIndex <= 3);

  static final instance = HomeTab();

  factory HomeTab.withInitialTab(int initialIndex) {
    return HomeTab(initialIndex: initialIndex);
  }

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;

  static const _sections = [
    (
      titleKey: 'home.teammate',
      child: TeammateSubtab(),
    ),
    (
      titleKey: 'home.challenger',
      child: ChallengerSubtab(),
    ),
    (
      titleKey: 'home.professional',
      child: ProfessionalSubtab(),
    ),
    (
      titleKey: 'home.location',
      child: LocationSubtab(),
    ),
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
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<FTabEntry> _buildTabEntries() {
    return List.generate(_sections.length, (index) {
      final section = _sections[index];

      return FTabEntry(
        label: KeyedSubtree(key: const ValueKey('icon'), child: _icons[index]),
        child: section.child,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: Text('nav.home'.tr()),
        suffixes: [const NotificationIconButton(), const SportSelector()],
      ),
      child: FTabs(
        expands: true,
        control: FTabControl.lifted(
          index: _currentIndex,
          onChange: _onTabChanged,
        ),
        children: _buildTabEntries(),
      ),
    );
  }
}
