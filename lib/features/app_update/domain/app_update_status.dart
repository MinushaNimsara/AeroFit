import 'package:aerofit/features/app_update/domain/app_version_config.dart';

enum AppUpdateKind {
  /// Successfully checked; no update needed (or soft-skipped).
  none,

  /// Soft update available (Later allowed).
  soft,

  /// Forced update (cannot dismiss).
  forced,

  /// Could not reach / parse remote config. Not the same as up-to-date.
  checkFailed,
}

class AppUpdateStatus {
  const AppUpdateStatus({
    required this.kind,
    required this.localVersionCode,
    required this.localVersionName,
    this.config,
    this.checkError,
  });

  final AppUpdateKind kind;
  final int localVersionCode;
  final String localVersionName;
  final AppVersionConfig? config;
  final String? checkError;

  bool get needsUpdate =>
      kind == AppUpdateKind.soft || kind == AppUpdateKind.forced;

  bool get checkFailed => kind == AppUpdateKind.checkFailed;

  static const none = AppUpdateStatus(
    kind: AppUpdateKind.none,
    localVersionCode: 0,
    localVersionName: '',
  );
}
