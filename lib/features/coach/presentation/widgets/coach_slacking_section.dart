import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/live_workout/domain/slacking_alert.dart';
import 'package:aerofit/shared/widgets/alert_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoachSlackingSection extends StatelessWidget {
  const CoachSlackingSection({super.key, required this.alertsAsync});

  final AsyncValue<List<SlackingAlert>> alertsAsync;

  @override
  Widget build(BuildContext context) {
    final hasAlerts = alertsAsync.valueOrNull?.isNotEmpty == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasAlerts
              ? AppColors.warning.withValues(alpha: 0.95)
              : const Color(0xFF252B38),
          width: hasAlerts ? 2.5 : 1,
        ),
        boxShadow: hasAlerts
            ? [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AlertIcon(
                      color: hasAlerts ? AppColors.warning : AppColors.danger,
                      backgroundColor:
                          AppColors.danger.withValues(alpha: 0.15),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Active Alerts / Slacking Trainees',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (hasAlerts)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${alertsAsync.value!.length} LIVE',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              alertsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Text(
                  'Could not load alerts: $e',
                  style: const TextStyle(color: AppColors.danger),
                ),
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF252B38)),
                      ),
                      child: Text(
                        'All trainees are on track — no rest violations right now.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    );
                  }

                  return Column(
                    children: alerts
                        .map(
                          (alert) => _SlackingAlertCard(alert: alert)
                              .animate(
                                onPlay: (c) => c.repeat(reverse: true),
                              )
                              .shimmer(
                                duration: 1400.ms,
                                color: AppColors.danger.withValues(alpha: 0.18),
                              ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlackingAlertCard extends StatelessWidget {
  const _SlackingAlertCard({required this.alert});

  final SlackingAlert alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withValues(alpha: 0.22),
            AppColors.warning.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.75),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AlertIcon(
            color: AppColors.warning,
            backgroundColor: Color(0x33FF6B6B),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Alert: ${alert.traineeName} is resting too long during ${alert.workoutName.isNotEmpty ? alert.workoutName : 'their workout'}! Go check on them.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
