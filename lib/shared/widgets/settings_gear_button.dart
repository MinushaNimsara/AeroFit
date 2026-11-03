import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/shared/widgets/gear_icon.dart';
import 'package:aerofit/shared/widgets/ui/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsGearButton extends StatelessWidget {
  const SettingsGearButton({
    super.key,
    this.isActive = false,
    this.settingsPath = '/settings',
  });

  final bool isActive;
  final String settingsPath;

  @override
  Widget build(BuildContext context) {
    return IconCircleButton(
      semanticLabel: 'Settings',
      highlighted: isActive,
      onPressed: () => context.go(settingsPath),
      child: GearIcon(
        color: isActive ? AppColors.primary : AppColors.textPrimary,
        size: 22,
        holeColor: AppColors.surface,
      ),
    );
  }
}
