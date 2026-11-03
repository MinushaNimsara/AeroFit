import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/shared/widgets/qr_code_icon.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/shared/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GymMembershipBanner extends ConsumerWidget {
  const GymMembershipBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final profile = profileAsync.valueOrNull;
    // Hide only for known non-trainees. Missing profile still shows join CTA.
    if (profile != null && !profile.isTrainee) {
      return const SizedBox.shrink();
    }

    final calorieGoal = ref.watch(dailyCalorieGoalProvider);
    final enrolled = profile?.isEnrolledInGym ?? false;

    if (!enrolled) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const IconChip(
              icon: Icons.group_off_rounded,
              color: AppColors.warning,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Not joined any gym',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Show your Gym Pass QR to your coach to unlock live routines.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: AppColors.primary,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => context.push('/settings'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrCodeIcon(color: AppColors.onPrimary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Gym Pass',
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.12),
          AppColors.surface,
        ],
      ),
      child: Row(
        children: [
          const IconChip(
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.gymName ?? 'your gym',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Daily target: $calorieGoal kcal · Gym network active',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.win.withValues(alpha: 0.15),
              borderRadius: AppRadii.pillBr,
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: AppColors.win,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
