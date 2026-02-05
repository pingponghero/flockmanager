import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Notifier to track current tab index for scroll reset, etc.
class TabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final tabChangeNotifierProvider = NotifierProvider<TabIndexNotifier, int>(
  TabIndexNotifier.new,
);

/// Shell widget that provides persistent bottom navigation bar.
class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final selectedIconColor = Theme.of(context).colorScheme.onSecondaryContainer;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Image.asset(
              'assets/icons/cute_hen.png',
              width: 24,
              height: 24,
              color: iconColor,
            ),
            selectedIcon: Image.asset(
              'assets/icons/cute_hen.png',
              width: 24,
              height: 24,
              color: selectedIconColor,
            ),
            label: 'Birds',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money),
            label: 'Expenses',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onDestinationSelected: (index) {
          // Notify listeners about tab change (for scroll reset)
          ref.read(tabChangeNotifierProvider.notifier).setIndex(index);
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
