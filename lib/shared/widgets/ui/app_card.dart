import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Outer rounded surface (radius 24) with a hairline border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? radius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final br = radius ?? AppRadii.cardBr;
    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? AppColors.surface) : null,
      gradient: gradient,
      borderRadius: br,
      border: Border.all(color: borderColor ?? AppColors.border),
    );

    if (onTap == null) {
      return Container(
        decoration: decoration,
        padding: padding,
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Inner tile (radius 18) used inside an [AppCard] or in grids.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      onTap: onTap,
      color: color ?? AppColors.surfaceElevated,
      borderColor: Colors.transparent,
      radius: AppRadii.tileBr,
      child: child,
    );
  }
}
