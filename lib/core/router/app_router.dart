import 'package:aerofit/core/router/auth_session.dart';
import 'package:aerofit/core/router/router_refresh_notifier.dart';
import 'package:aerofit/features/analytics/presentation/reports_screen.dart';
import 'package:aerofit/features/auth/presentation/login_screen.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/coach/presentation/coach_dashboard_screen.dart';
import 'package:aerofit/features/coach/presentation/coach_settings_screen.dart';
import 'package:aerofit/features/dashboard/presentation/dashboard_screen.dart';
import 'package:aerofit/features/exercise_library/presentation/exercise_detail_screen.dart';
import 'package:aerofit/features/exercise_library/presentation/exercise_library_screen.dart';
import 'package:aerofit/features/master_admin/presentation/master_admin_dashboard_screen.dart';
import 'package:aerofit/features/master_admin/presentation/master_admin_login_screen.dart';
import 'package:aerofit/features/meals/presentation/meals_screen.dart';
import 'package:aerofit/features/routine/presentation/routine_screen.dart';
import 'package:aerofit/features/settings/presentation/settings_screen.dart';
import 'package:aerofit/features/workouts/presentation/workouts_screen.dart';
import 'package:aerofit/shared/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

const _loginPath = '/login';
const _masterAdminLoginPath = '/master-admin';
const _masterAdminDashboardPath = '/master-admin/dashboard';
const _coachDashboardPath = '/coach/dashboard';
const _coachSettingsPath = '/coach/settings';

bool _isCoachRoute(String location) {
  return location == _coachDashboardPath || location == _coachSettingsPath;
}

bool _isTraineeShellRoute(String location) {
  return location == '/' ||
      location.startsWith('/routine') ||
      location.startsWith('/workouts') ||
      location.startsWith('/meals') ||
      location.startsWith('/reports') ||
      location.startsWith('/settings');
}

bool _isPublicRoute(String location) {
  return location == _loginPath || location == _masterAdminLoginPath;
}

/// Returns a redirect path only when [location] differs from the target.
String? _redirectTo(String location, String target) {
  return location == target ? null : target;
}

String? _redirectForAuthSession({
  required AuthSession session,
  required String location,
  required bool isMasterAdmin,
  required bool isCoach,
  required bool profileLoading,
  required bool registrationInProgress,
  required bool awaitingProfile,
}) {
  final isOnLogin = location == _loginPath;
  final isOnMasterAdminLogin = location == _masterAdminLoginPath;
  final isOnMasterAdminDashboard = location == _masterAdminDashboardPath;
  final isOnCoachRoute = _isCoachRoute(location);
  final isOnTraineeShell = _isTraineeShellRoute(location);

  if (session.isLoading) {
    return _isPublicRoute(location) ? null : _redirectTo(location, _loginPath);
  }

  final user = session.user;
  if (user == null) {
    if (_isPublicRoute(location)) return null;
    if (isOnMasterAdminDashboard) {
      return _redirectTo(location, _masterAdminLoginPath);
    }
    return _redirectTo(location, _loginPath);
  }

  // Block navigation until sign-up finishes saving the Firestore profile.
  if (registrationInProgress || awaitingProfile) {
    if (isOnLogin) return null;
    if (isOnTraineeShell || isOnCoachRoute || isOnMasterAdminDashboard) {
      return _redirectTo(location, _loginPath);
    }
    return null;
  }

  if (profileLoading) {
    if (isOnMasterAdminDashboard || isOnCoachRoute) {
      return _redirectTo(location, '/');
    }
    if (isOnLogin) {
      return null;
    }
    return null;
  }

  if (isMasterAdmin) {
    if (isOnLogin ||
        isOnMasterAdminLogin ||
        isOnCoachRoute ||
        isOnTraineeShell) {
      return _redirectTo(location, _masterAdminDashboardPath);
    }
    return null;
  }

  if (isCoach) {
    if (isOnLogin || isOnMasterAdminLogin || isOnMasterAdminDashboard) {
      return _redirectTo(location, _coachDashboardPath);
    }
    if (isOnTraineeShell) {
      return _redirectTo(location, _coachDashboardPath);
    }
    return null;
  }

  if (isOnMasterAdminLogin || isOnMasterAdminDashboard) {
    return _redirectTo(location, '/');
  }
  if (isOnCoachRoute) return _redirectTo(location, '/');
  if (isOnLogin) return _redirectTo(location, '/');
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  final refresh = ref.watch(routerRefreshNotifierProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: _loginPath,
    refreshListenable: refresh,
    redirect: (context, state) {
      try {
        final location = state.matchedLocation;
        final session = readAuthSession(ref);

        final user = session.user;
        final profileAsync =
            user == null ? null : ref.read(userProfileStreamProvider);
        final profileLoading = profileAsync?.isLoading ?? false;
        final profile = profileAsync?.valueOrNull;
        final registrationInProgress =
            ref.read(authRegistrationInProgressProvider);
        final awaitingProfile = user != null &&
            (profileLoading ||
                ((profileAsync?.hasValue ?? false) && profile == null));

        final isMasterAdmin =
            user != null && ref.read(isMasterAdminAuthorizedProvider);
        final isCoach = profile?.isCoach == true;

        return _redirectForAuthSession(
          session: session,
          location: location,
          isMasterAdmin: isMasterAdmin,
          isCoach: isCoach,
          profileLoading: profileLoading,
          registrationInProgress: registrationInProgress,
          awaitingProfile: awaitingProfile,
        );
      } catch (_) {
        return _redirectTo(state.matchedLocation, _loginPath);
      }
    },
    errorBuilder: (context, state) => const LoginScreen(),
    routes: [
      GoRoute(
        path: _loginPath,
        name: 'login',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: _masterAdminLoginPath,
        name: 'master-admin-login',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MasterAdminLoginScreen(),
        ),
      ),
      GoRoute(
        path: _masterAdminDashboardPath,
        name: 'master-admin-dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MasterAdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: _coachDashboardPath,
        name: 'coach-dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: CoachDashboardScreen(),
        ),
      ),
      GoRoute(
        path: _coachSettingsPath,
        name: 'coach-settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: CoachSettingsScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/routine',
            name: 'routine',
            pageBuilder: (context, state) => const CustomTransitionPage(
              child: RoutineScreen(),
              transitionsBuilder: _fadeSlide,
            ),
          ),
          GoRoute(
            path: '/workouts',
            name: 'workouts',
            pageBuilder: (context, state) => const CustomTransitionPage(
              child: WorkoutsScreen(),
              transitionsBuilder: _fadeSlide,
            ),
            routes: [
              GoRoute(
                path: 'library',
                name: 'exercise-library',
                pageBuilder: (context, state) => const CustomTransitionPage(
                  child: ExerciseLibraryScreen(),
                  transitionsBuilder: _fadeSlide,
                ),
              ),
              GoRoute(
                path: 'exercise/:exerciseId',
                name: 'exercise-detail',
                pageBuilder: (context, state) => CustomTransitionPage(
                  child: ExerciseDetailScreen(
                    exerciseId: state.pathParameters['exerciseId']!,
                  ),
                  transitionsBuilder: _fadeSlide,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/meals',
            name: 'meals',
            pageBuilder: (context, state) => const CustomTransitionPage(
              child: MealsScreen(),
              transitionsBuilder: _fadeSlide,
            ),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            pageBuilder: (context, state) => const CustomTransitionPage(
              child: ReportsScreen(),
              transitionsBuilder: _fadeSlide,
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const CustomTransitionPage(
              child: SettingsScreen(),
              transitionsBuilder: _fadeSlide,
            ),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

Widget _fadeSlide(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.03, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
