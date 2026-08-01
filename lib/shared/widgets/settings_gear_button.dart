import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/shared/widgets/gear_icon.dart';
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
    return Semantics(
      button: true,
      label: 'Settings',
      child: InkWell(
        onTap: () => context.go(settingsPath),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.65),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: GearIcon(
              color: AppColors.primary,
              size: 24,
              holeColor: AppColors.surfaceElevated,
            ),
          ),
        ),
      ),
    );
  }
}
