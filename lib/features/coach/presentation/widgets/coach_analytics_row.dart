import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/shared/widgets/members_icon.dart';
import 'package:flutter/material.dart';

class CoachAnalyticsRow extends StatelessWidget {
  const CoachAnalyticsRow({
    super.key,
    required this.totalMembers,
    required this.activeNow,
    required this.totalLoading,
    required this.activeLoading,
  });

  final int totalMembers;
  final int activeNow;
  final bool totalLoading;
  final bool activeLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        final children = [
          Expanded(
            child: _StatPill(
              label: 'Total Members',
              value: totalLoading ? '—' : '$totalMembers',
              icon: const MembersIcon(color: AppColors.primary, size: 22),
              accent: AppColors.primary,
              loading: totalLoading,
            ),
          ),
          SizedBox(width: isNarrow ? 10 : 14),
          Expanded(
            child: _StatPill(
              label: 'Active Now',
              value: activeLoading ? '—' : '$activeNow',
              icon: const Icon(Icons.bolt_rounded, color: AppColors.win, size: 22),
              accent: AppColors.win,
              loading: activeLoading,
              pulse: activeNow > 0,
            ),
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              children[0],
              const SizedBox(height: 10),
              children[2],
            ],
          );
        }

        return Row(children: children);
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.loading = false,
    this.pulse = false,
  });

  final String label;
  final String value;
  final Widget icon;
  final Color accent;
  final bool loading;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            AppColors.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                if (loading)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: pulse ? accent : AppColors.textPrimary,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
