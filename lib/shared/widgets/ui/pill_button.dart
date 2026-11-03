import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Compact lime pill (e.g. "+ Gym") for headers and cards.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.onPrimary : AppColors.textPrimary;
    return Material(
      color: filled ? AppColors.primary : AppColors.surfaceElevated,
      shape: StadiumBorder(
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppColors.borderStrong),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular dark button holding an icon or custom widget.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.child,
    this.size = 44,
    this.semanticLabel,
    this.highlighted = false,
  }) : assert(icon != null || child != null);

  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;
  final double size;
  final String? semanticLabel;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.85),
        shape: CircleBorder(
          side: BorderSide(
            color: highlighted ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: child ??
                  Icon(icon, size: size * 0.5, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
