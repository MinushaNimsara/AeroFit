import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/analytics/domain/weekly_report.dart';
import 'package:aerofit/features/analytics/providers/analytics_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weeklyReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Reports'),
      ),
      body: reportAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Could not load reports: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (report) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(weeklyReportProvider);
          },
          child: _ReportsBody(report: report),
        ),
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final weekLabel = _weekRangeLabel(report.days);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                weekLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 6),
              Text(
                'Weekly Summary',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ).animate().fadeIn(delay: 60.ms, duration: 400.ms),
              const SizedBox(height: 16),
              _SummaryCards(report: report),
              const SizedBox(height: 28),
              Text(
                '7-Day Activity Matrix',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Routine completion & calorie target per day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              _ActivityMatrix(days: report.days),
              const SizedBox(height: 28),
              Text(
                'Streaks & Achievements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              _StreaksSection(report: report),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  String _weekRangeLabel(List<DayMetrics> days) {
    if (days.isEmpty) return '';
    final start = days.first.date;
    final end = days.last.date;
    final fmt = DateFormat('MMM d');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.fitness_center_rounded,
            label: 'Workouts',
            value: '${report.totalWorkouts}',
            subtitle: 'this week',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Avg calories',
            value: '${report.averageCalories}',
            subtitle: 'kcal / day',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.checklist_rounded,
            label: 'Routine',
            value: '${(report.routineCompletionRate * 100).round()}%',
            subtitle: 'completion',
            color: AppColors.win,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 120.ms, duration: 450.ms);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF252B38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActivityMatrix extends StatelessWidget {
  const _ActivityMatrix({required this.days});

  final List<DayMetrics> days;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days) ...[
                  Expanded(child: _DayBar(day: day)),
                  if (day != days.last) const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                _LegendDot(color: AppColors.primary, label: 'Routine'),
                SizedBox(width: 14),
                _LegendDot(color: AppColors.accent, label: 'Calories'),
                SizedBox(width: 14),
                _LegendDot(color: AppColors.win, label: 'Gym'),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.day});

  final DayMetrics day;

  @override
  Widget build(BuildContext context) {
    const maxHeight = 100.0;
    final routineH = maxHeight * day.routineProgress;
    final calorieH = maxHeight * day.calorieProgress;
    final gymH = day.exerciseCount > 0 ? maxHeight * 0.85 : 0.0;

    return Column(
      children: [
        SizedBox(
          height: maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BarSegment(
                height: routineH,
                color: AppColors.primary,
                maxHeight: maxHeight,
              ),
              const SizedBox(width: 2),
              _BarSegment(
                height: calorieH,
                color: day.dietOnTarget ? AppColors.win : AppColors.accent,
                maxHeight: maxHeight,
              ),
              const SizedBox(width: 2),
              _BarSegment(
                height: gymH,
                color: AppColors.win,
                maxHeight: maxHeight,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day.dayLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: day.isToday ? AppColors.primary : AppColors.textSecondary,
                fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _BarSegment extends StatelessWidget {
  const _BarSegment({
    required this.height,
    required this.color,
    required this.maxHeight,
  });

  final double height;
  final Color color;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      width: 8,
      height: height.clamp(4, maxHeight),
      decoration: BoxDecoration(
        color: height > 4 ? color : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _StreaksSection extends StatelessWidget {
  const _StreaksSection({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StreakCard(
                icon: Icons.local_fire_department_rounded,
                title: 'Diet streak',
                value: '${report.dietStreak} days',
                subtitle: 'At or under ${report.calorieGoal} kcal',
                active: report.dietStreak > 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StreakCard(
                icon: Icons.task_alt_rounded,
                title: 'Routine streak',
                value: '${report.routineStreak} days',
                subtitle: 'All tasks complete',
                active: report.routineStreak > 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...report.achievements.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AchievementTile(message: entry.value)
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 80 * entry.key),
                      duration: 400.ms,
                    )
                    .slideX(begin: 0.03, end: 0),
              ),
            ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.win : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? AppColors.win.withValues(alpha: 0.35)
              : const Color(0xFF252B38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.surface,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252B38)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.35,
            ),
      ),
    );
  }
}
