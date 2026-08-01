import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/domain/user_profile.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/coach/presentation/widgets/coach_analytics_row.dart';
import 'package:aerofit/features/coach/presentation/widgets/coach_routine_builder_section.dart';
import 'package:aerofit/features/coach/presentation/widgets/coach_slacking_section.dart';
import 'package:aerofit/features/coach/presentation/widgets/coach_trainee_roster.dart';
import 'package:aerofit/features/coach/providers/coach_dashboard_providers.dart';
import 'package:aerofit/features/settings/providers/settings_providers.dart';
import 'package:aerofit/shared/widgets/settings_gear_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  String _coachWelcomeName(UserProfile? profile) {
    if (profile == null) return '';
    final name = profile.displayName.trim();
    return name.isNotEmpty ? name : '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
    if (authUid == null || authUid.trim().isEmpty) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    final gymName = profile?.gymName?.trim();
    final coachName = _coachWelcomeName(profile);

    final totalAsync = ref.watch(coachTotalMembersProvider);
    final activeAsync = ref.watch(coachActiveNowProvider);
    final rosterAsync = ref.watch(filteredCoachGymRosterProvider);
    final fullRosterAsync = ref.watch(coachGymRosterProvider);
    final templatesAsync = ref.watch(coachWorkoutTemplatesProvider);
    final alertsAsync = ref.watch(coachSlackingAlertsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateRoutineDialog(context, () {}),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Routine'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0C12), Color(0xFF151C2E), Color(0xFF0D0F14)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                actions: [
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SettingsGearButton(
                      settingsPath: '/coach/settings',
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(settingsControllerProvider).logout(),
                    child: const Text('Log out'),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      coachName.isEmpty
                          ? 'Welcome, Coach'
                          : 'Welcome, Coach $coachName',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ).animate().fadeIn(duration: 350.ms),
                    if (gymName != null && gymName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        gymName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ],
                    const SizedBox(height: 20),
                    CoachAnalyticsRow(
                      totalMembers: totalAsync.valueOrNull ?? 0,
                      activeNow: activeAsync.valueOrNull ?? 0,
                      totalLoading: totalAsync.isLoading,
                      activeLoading: activeAsync.isLoading,
                    ).animate().fadeIn(delay: 60.ms, duration: 400.ms),
                    const SizedBox(height: 20),
                    CoachSlackingSection(alertsAsync: alertsAsync)
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 400.ms),
                    const SizedBox(height: 20),
                    CoachTraineeRoster(
                      members: rosterAsync.valueOrNull ?? const [],
                      totalCount: fullRosterAsync.valueOrNull?.length ?? 0,
                      isLoading:
                          rosterAsync.isLoading && rosterAsync.valueOrNull == null,
                      error: rosterAsync.error,
                    ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
                    const SizedBox(height: 20),
                    CoachRoutineBuilderSection(
                      templates: templatesAsync.valueOrNull ?? const [],
                      isLoading: templatesAsync.isLoading,
                      error: templatesAsync.error,
                      onCreate: () => showCreateRoutineDialog(context, () {}),
                    ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
