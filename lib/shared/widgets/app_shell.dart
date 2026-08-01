import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/shared/widgets/gear_icon.dart';
import 'package:aerofit/shared/widgets/settings_gear_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _ShellDestination {
  const _ShellDestination({
    this.icon,
    this.selectedIcon,
    this.iconWidget,
    this.selectedIconWidget,
    required this.label,
    required this.path,
  }) : assert(
          (icon != null && iconWidget == null) ||
              (icon == null && iconWidget != null),
        );

  final IconData? icon;
  final IconData? selectedIcon;
  final Widget? iconWidget;
  final Widget? selectedIconWidget;
  final String label;
  final String path;

  Widget buildIcon({required bool selected}) {
    if (iconWidget != null) {
      if (selected) {
        return selectedIconWidget ?? iconWidget!;
      }
      return iconWidget!;
    }

    final data = selected ? (selectedIcon ?? icon) : icon;
    if (data == null) {
      return const SizedBox.shrink();
    }
    return Icon(data);
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _railDestinations = <_ShellDestination>[
    _ShellDestination(icon: Icons.dashboard_rounded, label: 'Hub', path: '/'),
    _ShellDestination(icon: Icons.checklist_rounded, label: 'Routine', path: '/routine'),
    _ShellDestination(icon: Icons.fitness_center_rounded, label: 'Gym', path: '/workouts'),
    _ShellDestination(icon: Icons.restaurant_rounded, label: 'Meals', path: '/meals'),
    _ShellDestination(icon: Icons.insights_rounded, label: 'Reports', path: '/reports'),
    _ShellDestination(
      iconWidget: GearIcon(
        color: AppColors.textSecondary,
        size: 24,
        holeColor: AppColors.surface,
      ),
      selectedIconWidget: GearIcon(
        color: AppColors.primary,
        size: 24,
        holeColor: AppColors.surface,
      ),
      label: 'Settings',
      path: '/settings',
    ),
  ];

  static const _bottomDestinations = <_ShellDestination>[
    _ShellDestination(icon: Icons.dashboard_rounded, label: 'Hub', path: '/'),
    _ShellDestination(icon: Icons.checklist_rounded, label: 'Routine', path: '/routine'),
    _ShellDestination(icon: Icons.fitness_center_rounded, label: 'Gym', path: '/workouts'),
    _ShellDestination(icon: Icons.restaurant_rounded, label: 'Meals', path: '/meals'),
    _ShellDestination(icon: Icons.insights_rounded, label: 'Reports', path: '/reports'),
  ];

  static const _settingsPath = '/settings';

  bool _isSettingsRoute(BuildContext context) {
    return GoRouterState.of(context).uri.path == _settingsPath;
  }

  int _selectedIndex(BuildContext context, List<_ShellDestination> destinations) {
    final location = GoRouterState.of(context).uri.path;
    final index = destinations.indexWhere((d) => d.path == location);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;
    final onSettings = _isSettingsRoute(context);

    if (useRail) {
      final selected = _selectedIndex(context, _railDestinations);
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: (i) =>
                  context.go(_railDestinations[i].path),
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primary.withValues(alpha: 0.2),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _railDestinations)
                  NavigationRailDestination(
                    icon: d.buildIcon(selected: false),
                    selectedIcon: d.buildIcon(selected: true),
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

    final selected = _selectedIndex(context, _bottomDestinations);
    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (!onSettings)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: SettingsGearButton(isActive: onSettings),
            ),
        ],
      ),
      bottomNavigationBar: onSettings
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) =>
                  context.go(_bottomDestinations[i].path),
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primary.withValues(alpha: 0.25),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final d in _bottomDestinations)
                  NavigationDestination(
                    icon: d.buildIcon(selected: false),
                    label: d.label,
                  ),
              ],
            ),
    );
  }
}
