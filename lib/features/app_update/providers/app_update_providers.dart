import 'package:aerofit/features/app_update/data/app_update_prefs.dart';
import 'package:aerofit/features/app_update/data/app_update_repository.dart';
import 'package:aerofit/features/app_update/domain/app_update_status.dart';
import 'package:aerofit/features/app_update/domain/app_version_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  return AppUpdateRepository();
});

final appUpdatePrefsProvider = Provider<AppUpdatePrefs>((ref) {
  return AppUpdatePrefs();
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Bump to force a fresh check (Settings "Check for updates").
final appUpdateCheckNonceProvider = StateProvider<int>((ref) => 0);

/// How many consecutive fetch failures for backoff scheduling.
final appUpdateFailCountProvider = StateProvider<int>((ref) => 0);

/// Resolves whether a soft/forced update is needed.
/// Runs before sign-in so sideload users see the dialog on the login screen.
final appUpdateStatusProvider = FutureProvider<AppUpdateStatus?>((ref) async {
  if (kIsWeb) return AppUpdateStatus.none;
  if (defaultTargetPlatform != TargetPlatform.android) {
    return AppUpdateStatus.none;
  }

  // Depend on nonce so Settings can force a re-check.
  ref.watch(appUpdateCheckNonceProvider);

  final info = await PackageInfo.fromPlatform();
  final localCode = int.tryParse(info.buildNumber) ?? 0;
  final localName = info.version;

  AppVersionConfig? config;
  try {
    final repo = ref.read(appUpdateRepositoryProvider);
    config = await repo.fetchVersionConfig();
    ref.read(appUpdateFailCountProvider.notifier).state = 0;
    debugPrint(
      'app_update: local=$localName+$localCode config='
      '${config == null ? "null" : "${config.latestVersionName}+${config.latestVersionCode} url=${config.apkUrl}"}',
    );
  } catch (e, st) {
    debugPrint('app_update: fetch failed $e\n$st');
    final fails = ref.read(appUpdateFailCountProvider) + 1;
    ref.read(appUpdateFailCountProvider.notifier).state = fails;
    // Backoff: 2s, 5s, 10s — then stop auto-retry (Settings can still force).
    final delays = <int>[2, 5, 10];
    if (fails <= delays.length) {
      final seconds = delays[fails - 1];
      Future<void>.delayed(Duration(seconds: seconds), () {
        ref.invalidateSelf();
      });
    }
    return AppUpdateStatus(
      kind: AppUpdateKind.checkFailed,
      localVersionCode: localCode,
      localVersionName: localName,
      checkError: '$e',
    );
  }

  if (config == null || localCode >= config.latestVersionCode) {
    return AppUpdateStatus(
      kind: AppUpdateKind.none,
      localVersionCode: localCode,
      localVersionName: localName,
      config: config,
    );
  }

  final forced = config.forceUpdate || localCode < config.minVersionCode;
  if (!forced) {
    final skipped = await ref.read(appUpdatePrefsProvider).skippedVersionCode();
    if (skipped != null && skipped == config.latestVersionCode) {
      return AppUpdateStatus(
        kind: AppUpdateKind.none,
        localVersionCode: localCode,
        localVersionName: localName,
        config: config,
      );
    }
  }

  return AppUpdateStatus(
    kind: forced ? AppUpdateKind.forced : AppUpdateKind.soft,
    localVersionCode: localCode,
    localVersionName: localName,
    config: config,
  );
});
