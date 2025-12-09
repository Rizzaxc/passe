import 'package:flutter/material.dart';

class HomeTab extends StatefulWidget {
  final int initialIndex;

  const HomeTab({super.key, this.initialIndex = 0});

  static final instance = HomeTab();

  factory HomeTab.withInitialTab(int initialIndex) {
    return HomeTab(initialIndex: initialIndex);
  }

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Teammate'),
            Tab(text: 'Challenger'),
            Tab(text: 'Neutral'),
            Tab(text: 'Location'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Center(child: Text('Teammate Content')),
          Center(child: Text('Challenger Content')),
          Center(child: Text('Neutral Content')),
          Center(child: Text('Location Content')),
        ],
      ),
    );
  }
}
