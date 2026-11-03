import 'dart:ui';

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

  Widget buildIcon({required bool selected, Color? color}) {
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
    return Icon(data, color: color);
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabDestinations = <_ShellDestination>[
    _ShellDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Hub',
      path: '/',
    ),
    _ShellDestination(
      icon: Icons.checklist_rounded,
      label: 'Routine',
      path: '/routine',
    ),
    _ShellDestination(
      icon: Icons.fitness_center_rounded,
      label: 'Gym',
      path: '/workouts',
    ),
    _ShellDestination(
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant_rounded,
      label: 'Meals',
      path: '/meals',
    ),
    _ShellDestination(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: 'Reports',
      path: '/reports',
    ),
  ];

  static const _railDestinations = <_ShellDestination>[
    ..._tabDestinations,
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

  static const _settingsPath = '/settings';

  bool _isSettingsRoute(BuildContext context) {
    return GoRouterState.of(context).uri.path == _settingsPath;
  }

  /// The hub renders its own gear inside the greeting card.
  bool _isHubRoute(BuildContext context) {
    return GoRouterState.of(context).uri.path == '/';
  }

  int _selectedIndex(
      BuildContext context, List<_ShellDestination> destinations) {
    final location = GoRouterState.of(context).uri.path;
    final index = destinations.indexWhere(
      (d) => d.path == '/' ? location == '/' : location.startsWith(d.path),
    );
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
              labelType: NavigationRailLabelType.all,
              groupAlignment: -0.85,
              destinations: [
                for (final d in _railDestinations)
                  NavigationRailDestination(
                    icon: d.buildIcon(selected: false),
                    selectedIcon: d.buildIcon(selected: true),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    final selected = _selectedIndex(context, _tabDestinations);
    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (!onSettings && !_isHubRoute(context))
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: SettingsGearButton(isActive: onSettings),
            ),
        ],
      ),
      bottomNavigationBar: onSettings
          ? null
          : _FloatingNavBar(
              destinations: _tabDestinations,
              selectedIndex: selected,
              onSelected: (i) => context.go(_tabDestinations[i].path),
            ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(12, 4, 12, bottomInset > 0 ? bottomInset : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightShape: BoxShape.circle,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: selected ? 1 : 0,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.22),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 24),
                  child:
                      destination.buildIcon(selected: selected, color: color),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(destination.label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
