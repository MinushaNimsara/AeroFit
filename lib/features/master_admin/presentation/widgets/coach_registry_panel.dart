import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/master_admin/domain/coach_registry_entry.dart';
import 'package:aerofit/features/master_admin/presentation/widgets/edit_coach_dialog.dart';
import 'package:aerofit/features/master_admin/presentation/widgets/gym_management_detail_sheet.dart';
import 'package:aerofit/features/master_admin/presentation/widgets/registry_shimmer.dart';
import 'package:aerofit/features/master_admin/providers/platform_analytics_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CoachRegistryPanel extends ConsumerWidget {
  const CoachRegistryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registryAsync = ref.watch(coachRegistryStreamProvider);

    return Card(
      color: AppColors.surfaceElevated,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.06),
              AppColors.surfaceElevated,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.hub_rounded,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registered Network Registry',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live gyms and coach accounts across the platform.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            registryAsync.when(
              loading: () => const RegistryShimmer(rowCount: 6),
              error: (e, _) => Text(
                'Could not load registry: $e',
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return _EmptyRegistry();
                }
                return _RegistryTable(entries: entries);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRegistry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252B38)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'No gyms registered yet',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first gym and coach using the form.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RegistryTable extends ConsumerWidget {
  const _RegistryTable({required this.entries});

  final List<CoachRegistryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        if (isWide) {
          return Column(
            children: [
              const _TableHeader(),
              const SizedBox(height: 8),
              ...entries.map(
                (entry) => _RegistryRow(
                  entry: entry,
                  dateFormat: dateFormat,
                  isWide: true,
                  onOpen: () => showGymManagementDetailSheet(context, ref, entry),
                  onEdit: () => showEditCoachDialog(context, ref, entry),
                ),
              ),
            ],
          );
        }

        return Column(
          children: entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RegistryRow(
                    entry: entry,
                    dateFormat: dateFormat,
                    isWide: false,
                    onOpen: () =>
                        showGymManagementDetailSheet(context, ref, entry),
                    onEdit: () => showEditCoachDialog(context, ref, entry),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('GYM', style: style)),
          Expanded(flex: 3, child: Text('COACH', style: style)),
          Expanded(flex: 4, child: Text('EMAIL', style: style)),
          Expanded(flex: 2, child: Text('CREATED', style: style)),
          const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _RegistryRow extends StatelessWidget {
  const _RegistryRow({
    required this.entry,
    required this.dateFormat,
    required this.isWide,
    required this.onOpen,
    required this.onEdit,
  });

  final CoachRegistryEntry entry;
  final DateFormat dateFormat;
  final bool isWide;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final createdLabel = entry.createdAt != null
        ? dateFormat.format(entry.createdAt!)
        : '—';

    if (!isWide) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF252B38)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.gymName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                    _EditCoachButton(onPressed: onEdit),
                  ],
                ),
                const SizedBox(height: 6),
                Text(entry.coachName,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  entry.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  createdLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF252B38)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  entry.gymName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(entry.coachName),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  entry.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  createdLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              _EditCoachButton(onPressed: onEdit),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditCoachButton extends StatelessWidget {
  const _EditCoachButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Edit',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
