class AppVersionConfig {
  const AppVersionConfig({
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.apkUrl,
    required this.forceUpdate,
    required this.minVersionCode,
    this.releaseNotes,
    this.apkStoragePath = '',
  });

  final int latestVersionCode;
  final String latestVersionName;
  /// Public HTTPS URL to the APK (GitHub Releases, CDN, etc.). Preferred on Spark.
  final String apkUrl;
  /// Optional Firebase Storage path — only usable on Blaze with Storage enabled.
  final String apkStoragePath;
  final bool forceUpdate;
  final int minVersionCode;
  final String? releaseNotes;

  factory AppVersionConfig.fromMap(Map<String, dynamic> data) {
    final rawLatest = data['latestVersionCode'];
    final rawMin = data['minVersionCode'];
    return AppVersionConfig(
      latestVersionCode: rawLatest is int
          ? rawLatest
          : rawLatest is num
              ? rawLatest.toInt()
              : 0,
      latestVersionName: (data['latestVersionName'] as String?)?.trim() ?? '',
      apkUrl: (data['apkUrl'] as String?)?.trim() ?? '',
      apkStoragePath: (data['apkStoragePath'] as String?)?.trim() ?? '',
      forceUpdate: data['forceUpdate'] == true,
      minVersionCode: rawMin is int
          ? rawMin
          : rawMin is num
              ? rawMin.toInt()
              : 0,
      releaseNotes: (data['releaseNotes'] as String?)?.trim(),
    );
  }

  bool get hasHttpsApk {
    final u = Uri.tryParse(apkUrl);
    return u != null &&
        u.hasScheme &&
        (u.scheme == 'https' || u.scheme == 'http') &&
        u.host.isNotEmpty;
  }

  bool get isValid => latestVersionCode > 0 && hasHttpsApk;
}
