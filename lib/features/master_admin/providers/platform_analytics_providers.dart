import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/master_admin/domain/coach_registry_entry.dart';
import 'package:aerofit/features/master_admin/domain/platform_analytics.dart';
import 'package:aerofit/features/master_admin/providers/master_admin_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final platformAnalyticsStreamProvider =
    StreamProvider<PlatformAnalytics>((ref) {
  final authorized = ref.watch(isMasterAdminAuthorizedProvider);
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(masterAdminRepositoryProvider);

  if (!authorized || auth == null || repo == null) {
    return Stream.value(PlatformAnalytics.empty);
  }

  return repo.watchPlatformAnalytics();
});

final coachRegistryStreamProvider =
    StreamProvider<List<CoachRegistryEntry>>((ref) {
  final authorized = ref.watch(isMasterAdminAuthorizedProvider);
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(masterAdminRepositoryProvider);

  if (!authorized || auth == null || repo == null) {
    return Stream.value(const []);
  }

  return repo.watchCoachRegistry();
});
