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
    'Chest': ExerciseCategoryVisual._(Icons.fitness_center_rounded, Color(0xFF6C9EFF)),
    'Back': ExerciseCategoryVisual._(Icons.rowing_rounded, Color(0xFF7EE787)),
    'Biceps': ExerciseCategoryVisual._(Icons.sports_gymnastics_rounded, Color(0xFFFFB454)),
    'Triceps': ExerciseCategoryVisual._(Icons.sports_martial_arts_rounded, Color(0xFFFF8A65)),
    'Shoulders': ExerciseCategoryVisual._(Icons.accessibility_new_rounded, Color(0xFF64D8CB)),
    'Legs': ExerciseCategoryVisual._(Icons.directions_walk_rounded, Color(0xFFBA68C8)),
    'Core': ExerciseCategoryVisual._(Icons.self_improvement_rounded, Color(0xFFFFD54F)),
    'Forearms': ExerciseCategoryVisual._(Icons.back_hand_rounded, Color(0xFF90A4AE)),
    'Cardio': ExerciseCategoryVisual._(Icons.monitor_heart_rounded, Color(0xFFE85D75)),
    'Full Body': ExerciseCategoryVisual._(Icons.accessibility_rounded, Color(0xFF6C9EFF)),
    'Bodyweight/Calisthenics': ExerciseCategoryVisual._(Icons.sports_gymnastics_rounded, Color(0xFF7EE787)),
    'Mobility/Stretching': ExerciseCategoryVisual._(Icons.self_improvement_rounded, Color(0xFF4FC3F7)),
    'Athletic Performance': ExerciseCategoryVisual._(Icons.bolt_rounded, Color(0xFFFFB454)),
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
