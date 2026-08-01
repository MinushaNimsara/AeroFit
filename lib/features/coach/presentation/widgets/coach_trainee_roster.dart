import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/coach/domain/coach_trainee_member.dart';
import 'package:aerofit/features/coach/presentation/widgets/assign_routine_dialog.dart';
import 'package:aerofit/features/coach/presentation/widgets/trainee_profile_sheet.dart';
import 'package:aerofit/features/coach/providers/coach_dashboard_providers.dart';
import 'package:aerofit/shared/widgets/active_pulse_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoachTraineeRoster extends ConsumerStatefulWidget {
  const CoachTraineeRoster({
    super.key,
    required this.members,
    required this.totalCount,
    required this.isLoading,
    this.error,
  });

  final List<CoachTraineeMember> members;
  final int totalCount;
  final bool isLoading;
  final Object? error;

  @override
  ConsumerState<CoachTraineeRoster> createState() => _CoachTraineeRosterState();
}

class _CoachTraineeRosterState extends ConsumerState<CoachTraineeRoster> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(traineeSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(traineeSearchQueryProvider);
    final hasActiveSearch = searchQuery.trim().isNotEmpty;

    return Card(
      color: AppColors.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'My Trainees / Clan Members',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (!widget.isLoading)
                  Text(
                    hasActiveSearch
                        ? '${widget.members.length} / ${widget.totalCount}'
                        : '${widget.totalCount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(traineeSearchQueryProvider.notifier).state = value,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search trainees by name…',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: hasActiveSearch
                    ? IconButton(
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close_rounded, size: 20),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF252B38)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF252B38)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (widget.error != null)
              Text(
                'Could not load roster: ${widget.error}',
                style: const TextStyle(color: AppColors.danger),
              )
            else if (widget.totalCount == 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF252B38)),
                ),
                child: Text(
                  'No trainees enrolled yet. Scan Gym Pass QR codes from Coach Settings.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
              )
            else if (widget.members.isEmpty && hasActiveSearch)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF252B38)),
                ),
                child: Text(
                  'No trainees match "${searchQuery.trim()}".',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _TraineeListTile(member: widget.members[index]);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TraineeListTile extends StatelessWidget {
  const _TraineeListTile({required this.member});

  final CoachTraineeMember member;

  String get _resolvedName {
    final label = member.displayLabel.trim();
    if (label.isNotEmpty) return label;
    return 'Member';
  }

  String get _avatarInitial => member.avatarInitial;

  @override
  Widget build(BuildContext context) {
    final progress = member.calorieProgress;
    final progressColor = progress > 1
        ? AppColors.danger
        : progress >= 0.85
            ? AppColors.win
            : AppColors.primary;

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: member.isWorkingOut
              ? AppColors.win.withValues(alpha: 0.45)
              : const Color(0xFF252B38),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showTraineeProfileSheet(
            context,
            member.uid,
            _resolvedName,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        _avatarInitial,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (member.isWorkingOut)
                      const Positioned(
                        right: -1,
                        top: -1,
                        child: ActivePulseDot(size: 13),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _resolvedName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.liveStatusLabel != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: member.liveStatusLabel == 'Slacking'
                                    ? AppColors.danger.withValues(alpha: 0.2)
                                    : AppColors.win.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                member.liveStatusLabel!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: member.liveStatusLabel == 'Slacking'
                                      ? AppColors.warning
                                      : AppColors.win,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${member.caloriesConsumed} / ${member.calorieGoal} kcal today',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: AppColors.ringTrack,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Assign Schedule',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    showAssignRoutineDialog(
                      context,
                      traineeUid: member.uid,
                      traineeName: _resolvedName,
                    );
                  },
                  icon: Icon(
                    Icons.event_note_rounded,
                    color: AppColors.primary.withValues(alpha: 0.95),
                  ),
                ),
                IconButton(
                  tooltip: 'View Profile',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showTraineeProfileSheet(
                    context,
                    member.uid,
                    _resolvedName,
                  ),
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
