import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/shared/widgets/ui/app_card.dart';
import 'package:flutter/material.dart';

/// Square quick-action card: large tinted icon above a centered label.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    this.icon,
    this.iconWidget,
  }) : assert(icon != null || iconWidget != null);

  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: AppRadii.tileBr,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.32),
                  color.withValues(alpha: 0.06),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: iconWidget ?? Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
