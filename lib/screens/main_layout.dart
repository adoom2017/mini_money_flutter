import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({required this.child, super.key});

  final Widget child;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    // 添加日志来追踪刷新原因
    final location = GoRouterState.of(context).matchedLocation;
    print(
        'MainLayout.build() called - currentIndex: $currentIndex, location: $location');

    // 追踪LayoutBuilder的构建
    print('LayoutBuilder about to build for location: $location');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use NavigationRail for wider screens
        if (constraints.maxWidth > 600) {
          return CupertinoPageScaffold(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) =>
                      _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                        icon: Icon(CupertinoIcons.home), label: Text('Home')),
                    NavigationRailDestination(
                        icon: Icon(CupertinoIcons.list_bullet),
                        label: Text('Details')),
                    NavigationRailDestination(
                        icon: Icon(CupertinoIcons.creditcard),
                        label: Text('Assets')),
                    NavigationRailDestination(
                        icon: Icon(CupertinoIcons.chart_bar),
                        label: Text('Statistics')),
                    NavigationRailDestination(
                        icon: Icon(CupertinoIcons.settings),
                        label: Text('Settings')),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: widget.child),
              ],
            ),
          );
        }

        // Use CupertinoTabScaffold for smaller screens
        return CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            currentIndex: currentIndex,
            onTap: (index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.list_bullet),
                label: 'Details',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.creditcard),
                label: 'Assets',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chart_bar),
                label: 'Statistics',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                label: 'Settings',
              ),
            ],
          ),
          tabBuilder: (context, index) {
            // 只在当前选中的标签页显示内容
            if (index == currentIndex) {
              return widget.child;
            } else {
              // 其他标签页返回空容器
              return const SizedBox.shrink();
            }
          },
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
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/details');
        break;
      case 2:
        context.go('/assets');
        break;
      case 3:
        context.go('/statistics');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}
