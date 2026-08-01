import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/meals/domain/meal_entry.dart';
import 'package:aerofit/features/meals/domain/meal_ingredient.dart';
import 'package:aerofit/features/meals/presentation/widgets/log_meal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

void showMealBreakdownSheet(
  BuildContext context, {
  required MealEntry meal,
  required int calorieGoal,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MealBreakdownSheet(
      meal: meal,
      calorieGoal: calorieGoal,
    ),
  );
}

class MealBreakdownSheet extends StatelessWidget {
  const MealBreakdownSheet({
    super.key,
    required this.meal,
    required this.calorieGoal,
  });

  final MealEntry meal;
  final int calorieGoal;

  @override
  Widget build(BuildContext context) {
    final macroGoals = MealMacroGoals.fromCalorieGoal(calorieGoal);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF252B38)),
              left: BorderSide(color: Color(0xFF252B38)),
              right: BorderSide(color: Color(0xFF252B38)),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  children: [
                    _HeaderRow(
                      mealType: meal.mealType,
                      onAddFood: () {
                        Navigator.of(context).pop();
                        showLogMealSheet(context);
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      meal.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        children: [
                          const TextSpan(text: 'Total Calories: '),
                          TextSpan(
                            text: '${meal.calories} kcal',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _MacroRow(
                      protein: meal.protein,
                      carbs: meal.carbs,
                      fats: meal.fats,
                      goals: macroGoals,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Ingredients',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.3,
                          ),
                    ),
                    const SizedBox(height: 12),
                    for (final ingredient in meal.displayIngredients)
                      _IngredientCard(ingredient: ingredient),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.mealType,
    required this.onAddFood,
  });

  final String mealType;
  final VoidCallback onAddFood;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF252B38)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mealType,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAddFood,
            borderRadius: BorderRadius.circular(12),
            child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: AppColors.accent),
              SizedBox(width: 4),
              Text(
                'Add Food',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.goals,
  });

  final double protein;
  final double carbs;
  final double fats;
  final MealMacroGoals goals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroRing(
            label: 'Protein',
            value: protein,
            goal: goals.proteinGrams,
            color: const Color(0xFF2196F3),
            icon: Icons.water_drop_outlined,
          ),
        ),
        Expanded(
          child: _MacroRing(
            label: 'Carbs',
            value: carbs,
            goal: goals.carbsGrams,
            color: const Color(0xFFFF9800),
            icon: Icons.grain_rounded,
          ),
        ),
        Expanded(
          child: _MacroRing(
            label: 'Fats',
            value: fats,
            goal: goals.fatsGrams,
            color: AppColors.accent,
            icon: Icons.opacity_rounded,
          ),
        ),
      ],
    );
  }
}

class _MacroRing extends StatelessWidget {
  const _MacroRing({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final double goal;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final percent = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    final valueLabel = _formatGrams(value);
    final goalLabel = _formatGrams(goal);

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 38,
          lineWidth: 7,
          percent: percent,
          animation: true,
          animationDuration: 700,
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: AppColors.ringTrack,
          progressColor: color,
          center: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          '$valueLabel / ${goalLabel}g',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  static String _formatGrams(double grams) {
    final rounded = (grams * 100).round() / 100;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(2);
  }
}

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({required this.ingredient});

  final MealIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    final caloriesLabel = _formatCalories(ingredient.calories);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF252B38)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    children: [
                      TextSpan(
                        text: '$caloriesLabel Kcal',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' / ${ingredient.portionLabel}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF252B38)),
            ),
            child: Text(
              ingredient.portionLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCalories(double calories) {
    final rounded = (calories * 100).round() / 100;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(2);
  }
}
