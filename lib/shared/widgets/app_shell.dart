import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    (icon: Icons.dashboard_rounded, label: 'Hub', path: '/'),
    (icon: Icons.checklist_rounded, label: 'Routine', path: '/routine'),
    (icon: Icons.fitness_center_rounded, label: 'Gym', path: '/workouts'),
    (icon: Icons.restaurant_rounded, label: 'Meals', path: '/meals'),
    (icon: Icons.insights_rounded, label: 'Reports', path: '/reports'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _destinations.indexWhere((d) => d.path == location);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;
    final selected = _selectedIndex(context);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: (i) =>
                  context.go(_destinations[i].path),
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primary.withValues(alpha: 0.2),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, color: Color(0xFF252B38)),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.25),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
