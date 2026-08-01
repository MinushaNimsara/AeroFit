import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/master_admin/presentation/widgets/platform_metric_card.dart';
import 'package:aerofit/features/master_admin/providers/platform_analytics_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlatformAnalyticsRow extends ConsumerWidget {
  const PlatformAnalyticsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(platformAnalyticsStreamProvider);

    return analyticsAsync.when(
      loading: () => const _MetricsGrid(
        metrics: [
          _MetricData('—', 'Total Registered Gyms', Icons.apartment_rounded,
              AppColors.primary),
          _MetricData('—', 'Active Systems / Coaches',
              Icons.sports_gymnastics_rounded, AppColors.accent),
          _MetricData('—', 'Total Network Trainees', Icons.groups_rounded,
              AppColors.warning),
        ],
      ),
      error: (e, _) => Text(
        'Could not load analytics: $e',
        style: const TextStyle(color: AppColors.danger),
      ),
      data: (analytics) => _MetricsGrid(
        metrics: [
          _MetricData(
            '${analytics.totalGyms}',
            'Total Registered Gyms',
            Icons.apartment_rounded,
            AppColors.primary,
          ),
          _MetricData(
            '${analytics.activeCoaches}',
            'Active Systems / Coaches',
            Icons.sports_gymnastics_rounded,
            AppColors.accent,
          ),
          _MetricData(
            '${analytics.totalTrainees}',
            'Total Network Trainees',
            Icons.groups_rounded,
            AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: _buildCard(metrics[i])),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildCard(metrics[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCard(_MetricData data) {
    return PlatformMetricCard(
      label: data.label,
      value: data.value,
      icon: data.icon,
      accent: data.accent,
    );
  }
}

class _MetricData {
  const _MetricData(this.value, this.label, this.icon, this.accent);

  final String value;
  final String label;
  final IconData icon;
  final Color accent;
}
