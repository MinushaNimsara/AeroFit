import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/shared/widgets/ui/app_card.dart';
import 'package:flutter/material.dart';

/// Small rounded square holding an icon, tinted with [color].
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.color,
    this.icon,
    this.child,
    this.size = 26,
  }) : assert(icon != null || child != null);

  final Color color;
  final IconData? icon;
  final Widget? child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: child ?? Icon(icon, size: size * 0.6, color: color),
    );
  }
}

/// Metric tile: icon chip + label, then a large colored value with a muted suffix.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.suffix,
    this.trailing,
    this.onTap,
    this.valueSize = 34,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final String? suffix;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return AppTile(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      IconChip(icon: icon, color: color, size: 24),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: valueSize,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (suffix != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          suffix!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
