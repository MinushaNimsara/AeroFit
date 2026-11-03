import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/shared/widgets/qr_code_icon.dart';
import 'package:aerofit/shared/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GymPassCard extends ConsumerWidget {
  const GymPassCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final uid = authAsync.valueOrNull?.uid?.trim();
    final profileAsync = ref.watch(userProfileStreamProvider);
    final profile = profileAsync.valueOrNull;

    // Not signed in → nothing to show.
    if (uid == null || uid.isEmpty) {
      return const SizedBox.shrink();
    }

    // Coach / master admin don't get a trainee Gym Pass.
    if (profile != null && !profile.isTrainee) {
      return const SizedBox.shrink();
    }

    // Profile still loading, missing, or trainee → always show pass + QR.
    // Previously `profile == null` hid the whole card (looked like QR was deleted).
    final enrolled = profile?.isEnrolledInGym ?? false;
    final dateFormat = DateFormat('MMM d, yyyy');
    final profileLoading = profileAsync.isLoading && profile == null;

    return AppCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: 0.1),
          AppColors.surface,
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrCodeIcon(
                  color: AppColors.primary,
                  backgroundColor: Color.lerp(
                    AppColors.surfaceElevated,
                    AppColors.primary,
                    0.15,
                  ),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'My Gym Pass',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          if (profileLoading) ...[
            const SizedBox(height: 12),
            Text(
              'Loading profile… QR below still works for enrollment.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          if (enrolled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.win.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.win.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.win),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enrolled in ${profile?.gymName ?? 'gym'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            if (profile?.enrolledAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Member since ${dateFormat.format(profile!.enrolledAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: uid,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.background,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            enrolled
                ? 'Your Gym Pass QR (UID). Coaches can re-scan if needed.'
                : 'Show this QR to your Gym Coach to get enrolled into the gym.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
