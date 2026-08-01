import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifies [GoRouter] when auth or role changes — not on every stream tick.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      final prevUid = previous?.valueOrNull?.uid;
      final nextUid = next.valueOrNull?.uid;
      final loadingChanged = (previous?.isLoading ?? true) != next.isLoading;
      if (loadingChanged || prevUid != nextUid) {
        notifyListeners();
      }
    });
    _ref.listen(userProfileStreamProvider, (previous, next) {
      final loadingChanged = (previous?.isLoading ?? true) != next.isLoading;
      final prevRole = previous?.valueOrNull?.role;
      final nextRole = next.valueOrNull?.role;
      if (loadingChanged || prevRole != nextRole) {
        notifyListeners();
      }
    });
    _ref.listen(authRegistrationInProgressProvider, (previous, next) {
      if (previous != next) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
