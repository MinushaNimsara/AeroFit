import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/core/router/go_router_refresh_stream.dart';
import 'package:aerofit/features/analytics/presentation/reports_screen.dart';
import 'package:aerofit/features/auth/presentation/login_screen.dart';
import 'package:aerofit/features/dashboard/presentation/dashboard_screen.dart';
import 'package:aerofit/features/meals/presentation/meals_screen.dart';
import 'package:aerofit/features/routine/presentation/routine_screen.dart';
import 'package:aerofit/features/workouts/presentation/workouts_screen.dart';
import 'package:aerofit/shared/widgets/app_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterRefreshProvider = Provider<GoRouterRefreshStream>((ref) {
  final Stream<dynamic> stream;
  if (FirebaseBootstrap.isReady) {
    stream = FirebaseAuth.instance.authStateChanges();
  } else {
    stream = Stream<dynamic>.value(null);
  }

  final refresh = GoRouterRefreshStream(stream);
  ref.onDispose(refresh.dispose);
  return refresh;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(goRouterRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = FirebaseBootstrap.isReady
          ? FirebaseAuth.instance.currentUser
          : null;

      final isOnLogin = state.matchedLocation == '/login';

      if (user == null) {
        return isOnLogin ? null : '/login';
      }

      if (isOnLogin) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
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
        ],
      ),
    ],
  );
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
