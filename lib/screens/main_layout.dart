import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use NavigationRail for wider screens
        if (constraints.maxWidth > 600) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _calculateSelectedIndex(context),
                  onDestinationSelected: (index) => _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
                    NavigationRailDestination(icon: Icon(Icons.list), label: Text('Details')),
                    NavigationRailDestination(icon: Icon(Icons.account_balance_wallet), label: Text('Assets')),
                    NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Statistics')),
                    NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.go('/add-transaction'),
              child: const Icon(Icons.add),
            ),
          );
        }

        // Use BottomNavigationBar for smaller screens
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _calculateSelectedIndex(context),
            onTap: (index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Details'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Assets'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.go('/add-transaction'),
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/details')) return 1;
    if (location.startsWith('/assets')) return 2;
    if (location.startsWith('/statistics')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/details'); break;
      case 2: context.go('/assets'); break;
      case 3: context.go('/statistics'); break;
      case 4: context.go('/settings'); break;
    }
  }
}