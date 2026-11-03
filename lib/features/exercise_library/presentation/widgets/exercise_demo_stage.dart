import 'dart:math' as math;

import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_demo_media.dart';
import 'package:flutter/material.dart';

/// Soft stage for white anatomical demo GIFs on the dark AeroFit UI.
///
/// Provides a single clip + cool off-white canvas so catalog demos read as
/// intentional product media instead of a raw white rectangle.
class ExerciseDemoStage extends StatelessWidget {
  const ExerciseDemoStage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.exerciseId,
    this.category,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.contain,
    this.square = false,
    this.maxSquareExtent,
  });

  final String? imageUrl;
  final String? assetPath;
  final String? exerciseId;
  final String? category;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  /// When true, builds a 1:1 stage (ideal for square GIFs).
  final bool square;

  /// Optional cap on the square side length when [square] is true.
  final double? maxSquareExtent;

  static const Color stageFill = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    final media = ExerciseDemoMedia(
      imageUrl: imageUrl,
      assetPath: assetPath,
      exerciseId: exerciseId,
      category: category,
      width: square ? null : width,
      height: square ? null : height,
      borderRadius: 0,
      fit: fit,
      clip: false,
    );

    Widget framed(Widget child) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: stageFill,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.borderStrong),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: ColoredBox(
            color: stageFill,
            child: child,
          ),
        ),
      );
    }

    if (square) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : (maxSquareExtent ?? 420);
          final side = math.min(
            maxW,
            maxSquareExtent ?? maxW,
          );
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: side,
              height: side,
              child: framed(media),
            ),
          );
        },
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: framed(media),
    );
  }
}
