import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import '../core/sport_selector.dart';
import '../router.dart';
import '../ui/main.dart';
import 'challenger_section/main.dart';
import 'location_section/main.dart';
import 'neutral_section/main.dart';
import 'teammate_section/main.dart';

class HomeTab extends StatefulWidget {
  final int initialIndex;

  const HomeTab({super.key, this.initialIndex = 0})
    : assert(initialIndex >= 0 && initialIndex <= 3);

  static final instance = HomeTab();

  factory HomeTab.withInitialTab(int initialIndex) {
    return HomeTab(initialIndex: initialIndex);
  }

  static const homeSections = <FTabEntry>[
    FTabEntry(
      child: TeammateSubtab(),
      label: Icon(
        CupertinoIcons.person_2_fill,
      ),
    ),
    FTabEntry(
      child: ChallengerSubtab(),
      label: Icon(FontAwesomeIcons.fireFlameCurved),
    ),
    FTabEntry(
      child: NeutralSubtab(),
      label: Icon(FontAwesomeIcons.flagCheckered),
    ),
    FTabEntry(
      child: LocationSubtab(),
      label: Icon(FontAwesomeIcons.shieldHalved),
    ),
  ];

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  // late final FTabControl _tabControl;

  // @override
  // void initState() {
  //   super.initState();
  //   _tabControl = FTabControl.managed(
  //     length: 4,
  //     vsync: this,
  //     index: widget.initialIndex,
  //   );
  // }

  // @override
  // void dispose() {
  //   _tabController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: Text('nav.home'.tr()),
        suffixes: [
          const NotificationIconButton(),
          const SportSelector(),
        ],
      ),
      child: FTabs(
        children: HomeTab.homeSections,
      ),
    );
  }
}
