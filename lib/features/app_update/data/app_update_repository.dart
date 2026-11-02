import 'dart:convert';
import 'dart:io';

import 'package:aerofit/features/app_update/domain/app_version_config.dart';
import 'package:aerofit/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AppUpdateRepository {
  AppUpdateRepository({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const configPath = 'config/app_version';

  /// Reads public `config/app_version` via Firestore REST.
  ///
  /// Uses [DefaultFirebaseOptions] — does **not** require [Firebase.app],
  /// so the check works even when Firebase SDK init is late or failed.
  Future<AppVersionConfig?> fetchVersionConfig() async {
    final options = defaultTargetPlatform == TargetPlatform.android
        ? DefaultFirebaseOptions.android
        : DefaultFirebaseOptions.currentPlatform;
    final projectId = options.projectId;
    final apiKey = options.apiKey;
    if (projectId.isEmpty || apiKey.isEmpty) {
      throw StateError('Firebase options missing projectId/apiKey');
    }

    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/$configPath',
      {'key': apiKey},
    );

    Object? lastError;
    for (var attempt = 0; attempt < 4; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
      try {
        final res = await _http.get(uri).timeout(const Duration(seconds: 12));
        if (res.statusCode == 404) {
          debugPrint('app_update: doc missing $configPath');
          return null;
        }
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw StateError('HTTP ${res.statusCode}: ${res.body}');
        }
        final decoded = jsonDecode(res.body);
        if (decoded is! Map<String, dynamic>) return null;
        final fields = decoded['fields'];
        if (fields is! Map<String, dynamic>) return null;
        final data = _decodeFirestoreFields(fields);
        final config = AppVersionConfig.fromMap(data);
        debugPrint(
          'app_update: rest ok valid=${config.isValid} '
          'code=${config.latestVersionCode} url=${config.apkUrl}',
        );
        return config.isValid ? config : null;
      } catch (e) {
        lastError = e;
        debugPrint('app_update: fetch attempt ${attempt + 1} failed $e');
      }
    }
    throw lastError ?? StateError('app_update fetch failed');
  }

  Map<String, dynamic> _decodeFirestoreFields(Map<String, dynamic> fields) {
    final out = <String, dynamic>{};
    fields.forEach((key, value) {
      if (value is! Map) return;
      if (value.containsKey('stringValue')) {
        out[key] = value['stringValue'];
      } else if (value.containsKey('integerValue')) {
        final raw = value['integerValue'];
        out[key] = raw is int ? raw : int.tryParse('$raw') ?? 0;
      } else if (value.containsKey('booleanValue')) {
        out[key] = value['booleanValue'] == true;
      } else if (value.containsKey('doubleValue')) {
        out[key] = value['doubleValue'];
      }
    });
    return out;
  }

  /// Downloads the APK from [config.apkUrl] into temp storage.
  Future<File> downloadApk({
    required AppVersionConfig config,
    required void Function(double progress) onProgress,
  }) async {
    if (!config.hasHttpsApk) {
      throw StateError('Missing or invalid apkUrl');
    }

    final uri = Uri.parse(config.apkUrl);
    final dir = await getTemporaryDirectory();
    final fileName = _fileNameFor(uri, config);
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }

    final request = http.Request('GET', uri);
    final response = await _http.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('APK download failed (${response.statusCode})');
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress((received / total).clamp(0.0, 1.0));
        } else {
          onProgress((0.15 + (received / (received + 5e6))).clamp(0.0, 0.9));
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    onProgress(1);
    return file;
  }

  String _fileNameFor(Uri uri, AppVersionConfig config) {
    final fromPath = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    if (fromPath.toLowerCase().endsWith('.apk')) return fromPath;
    final name = config.latestVersionName.isNotEmpty
        ? config.latestVersionName
        : '${config.latestVersionCode}';
    return 'aerofit-$name.apk';
  }
}
