import 'package:flutter/material.dart';

class ManageTab extends StatefulWidget {
  final int initialIndex;

  const ManageTab({super.key, this.initialIndex = 0});

  static final instance = ManageTab();

  factory ManageTab.withInitialTab(int initialIndex) {
    return ManageTab(initialIndex: initialIndex);
  }

  @override
  State<ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<ManageTab> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
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
        title: const Text('Manage'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Schedule'),
            Tab(text: 'Lobby'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Center(child: Text('Schedule Content')),
          Center(child: Text('Lobby Content')),
        ],
      ),
    );
  }
}
