import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/meals/domain/meal_entry.dart';
import 'package:aerofit/features/meals/presentation/widgets/log_meal_sheet.dart';
import 'package:aerofit/features/meals/presentation/widgets/meal_breakdown_sheet.dart';
import 'package:aerofit/features/meals/providers/meals_providers.dart';
import 'package:aerofit/shared/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class MealsScreen extends ConsumerWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(todayMealsStreamProvider);
    final goal = ref.watch(dailyCalorieGoalProvider);
    final total = ref.watch(todayCaloriesTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meals & Calories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogMealSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Meal'),
      ),
      body: mealsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Could not load meals: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (meals) => _MealsBody(
          meals: meals,
          totalCalories: total,
          calorieGoal: goal,
          onDelete: (meal) => _deleteMeal(ref, meal),
          onMealTap: (meal) => showMealBreakdownSheet(
            context,
            meal: meal,
            calorieGoal: goal,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMeal(WidgetRef ref, MealEntry meal) async {
    final uid = ref.read(authStateProvider).value?.uid;
    final repo = ref.read(mealsRepositoryProvider);
    if (uid == null || repo == null) return;
    await repo.deleteMeal(uid: uid, mealId: meal.id);
  }
}

class _MealsBody extends StatelessWidget {
  const _MealsBody({
    required this.meals,
    required this.totalCalories,
    required this.calorieGoal,
    required this.onDelete,
    required this.onMealTap,
  });

  final List<MealEntry> meals;
  final int totalCalories;
  final int calorieGoal;
  final void Function(MealEntry meal) onDelete;
  final void Function(MealEntry meal) onMealTap;

  @override
  Widget build(BuildContext context) {
    final progress =
        calorieGoal > 0 ? (totalCalories / calorieGoal).clamp(0.0, 1.0) : 0.0;
    final remaining = (calorieGoal - totalCalories).clamp(0, calorieGoal);
    final overGoal = totalCalories > calorieGoal;
    final progressColor = overGoal ? AppColors.danger : AppColors.accent;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 58,
                    lineWidth: 10,
                    percent: progress,
                    animation: true,
                    animationDuration: 800,
                    circularStrokeCap: CircularStrokeCap.round,
                    backgroundColor: AppColors.ringTrack,
                    progressColor: progressColor,
                    center: Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calories today',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$totalCalories',
                                style: TextStyle(
                                  color: progressColor,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '/ $calorieGoal kcal',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (overGoal ? AppColors.danger : AppColors.accent)
                                    .withValues(alpha: 0.14),
                            borderRadius: AppRadii.pillBr,
                          ),
                          child: Text(
                            overGoal
                                ? '${totalCalories - calorieGoal} kcal over goal'
                                : '$remaining kcal remaining',
                            style: TextStyle(
                              color: overGoal
                                  ? AppColors.danger
                                  : AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),
        ),
        if (meals.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No meals logged today',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap Log Meal to add breakfast, lunch, dinner, or snacks.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final meal = meals[index];
                  return _MealCard(
                    meal: meal,
                    onDelete: () => onDelete(meal),
                    onTap: () => onMealTap(meal),
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 40 * index),
                        duration: 280.ms,
                      )
                      .slideX(begin: 0.03, end: 0);
                },
                childCount: meals.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.onDelete,
    required this.onTap,
  });

  final MealEntry meal;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm().format(meal.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(meal.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.2),
            borderRadius: AppRadii.tileBr,
          ),
          child:
              const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        ),
        onDismissed: (_) => onDelete(),
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadii.tileBr,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.tileBr,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadii.tileBr,
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _mealIcon(meal.mealType),
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${meal.mealType} · $time',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${meal.calories}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                  ),
                  Text(
                    ' kcal',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _mealIcon(String type) {
    return switch (type) {
      'Breakfast' => Icons.free_breakfast_rounded,
      'Lunch' => Icons.lunch_dining_rounded,
      'Dinner' => Icons.dinner_dining_rounded,
      _ => Icons.cookie_rounded,
    };
  }
}
