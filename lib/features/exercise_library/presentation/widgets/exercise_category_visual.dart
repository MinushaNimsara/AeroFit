import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Maps a catalog category to an icon + accent color. Used as a visual
/// placeholder wherever a real exercise photo isn't available yet — the
/// underlying [Exercise.image] path is preserved so real photos can be
/// dropped into `assets/exercises/images/...` later without further code
/// changes.
class ExerciseCategoryVisual {
  const ExerciseCategoryVisual._(this.icon, this.color);

  final IconData icon;
  final Color color;

  static const _fallback = ExerciseCategoryVisual._(
    Icons.fitness_center_rounded,
    AppColors.primary,
  );

  static const Map<String, ExerciseCategoryVisual> _byCategory = {
    'Chest':
        ExerciseCategoryVisual._(Icons.fitness_center_rounded, AppColors.info),
    'Back': ExerciseCategoryVisual._(Icons.rowing_rounded, AppColors.accent),
    'Biceps': ExerciseCategoryVisual._(
        Icons.sports_gymnastics_rounded, AppColors.warning),
    'Triceps': ExerciseCategoryVisual._(
        Icons.sports_martial_arts_rounded, Color(0xFFFF7A59)),
    'Shoulders': ExerciseCategoryVisual._(
        Icons.accessibility_new_rounded, Color(0xFF5EEAD4)),
    'Legs': ExerciseCategoryVisual._(
        Icons.directions_walk_rounded, AppColors.violet),
    'Core': ExerciseCategoryVisual._(
        Icons.self_improvement_rounded, Color(0xFFFFD84D)),
    'Forearms': ExerciseCategoryVisual._(
        Icons.back_hand_rounded, AppColors.textSecondary),
    'Cardio':
        ExerciseCategoryVisual._(Icons.monitor_heart_rounded, AppColors.danger),
    'Full Body': ExerciseCategoryVisual._(
        Icons.accessibility_rounded, AppColors.primary),
    'Bodyweight/Calisthenics': ExerciseCategoryVisual._(
        Icons.sports_gymnastics_rounded, AppColors.accent),
    'Mobility/Stretching': ExerciseCategoryVisual._(
        Icons.self_improvement_rounded, Color(0xFF38BDF8)),
    'Athletic Performance':
        ExerciseCategoryVisual._(Icons.bolt_rounded, AppColors.warning),
  };

  static ExerciseCategoryVisual of(String category) =>
      _byCategory[category] ?? _fallback;
}

class ExerciseCategoryIcon extends StatelessWidget {
  const ExerciseCategoryIcon({
    super.key,
    required this.category,
    this.size = 44,
  });

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = ExerciseCategoryVisual.of(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: visual.color.withValues(alpha: 0.35)),
      ),
      child: Icon(visual.icon, color: visual.color, size: size * 0.5),
    );
  }
}
