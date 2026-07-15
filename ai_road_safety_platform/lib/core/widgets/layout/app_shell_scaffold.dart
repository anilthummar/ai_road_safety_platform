import 'package:ai_road_safety_platform/core/constants/app_spacing.dart';
import 'package:ai_road_safety_platform/core/constants/route_names.dart';
import 'package:ai_road_safety_platform/core/di/injection_container.dart';
import 'package:ai_road_safety_platform/core/services/shell_branch_controller.dart';
import 'package:ai_road_safety_platform/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Adaptive shell: bottom nav on compact, navigation rail on larger windows.
///
/// Hosts GoRouter's [StatefulNavigationShell] for persistent chrome.
class AppShellScaffold extends StatelessWidget {
  /// Nested navigation shell from GoRouter.
  final StatefulNavigationShell navigationShell;

  /// Creates an [AppShellScaffold].
  const AppShellScaffold({
    required this.navigationShell,
    super.key,
  });

  void _onDestinationSelected(int index) {
    sl<ShellBranchController>().setIndex(index);
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep branch controller aligned with deep-links / back stack.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sl<ShellBranchController>().setIndex(navigationShell.currentIndex);
    });

    final useRail = Responsive.useNavigationRail(context);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              extended: Responsive.of(context) == AppWindowSize.large ||
                  Responsive.of(context) == AppWindowSize.expanded,
              labelType: (Responsive.of(context) == AppWindowSize.large ||
                      Responsive.of(context) == AppWindowSize.expanded)
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Icon(Icons.shield_moon_outlined),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history_rounded),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Branch indices aligned with [AppShellScaffold] destinations.
abstract final class AppShellBranches {
  static const int dashboard = 0;
  static const int history = 1;
  static const int analytics = 2;
  static const int settings = 3;

  /// Maps a route location to a shell branch when deep-linking.
  static int branchForLocation(String location) {
    if (location.startsWith(RouteNames.history)) return history;
    if (location.startsWith(RouteNames.analytics)) return analytics;
    if (location.startsWith(RouteNames.settings)) return settings;
    return dashboard;
  }
}
