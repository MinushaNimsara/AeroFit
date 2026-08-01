import 'package:aerofit/core/config/env.dart';
import 'package:aerofit/features/auth/domain/activity_level.dart';
import 'package:aerofit/features/auth/domain/gender.dart';
import 'package:aerofit/features/auth/domain/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.role,
    this.email,
    this.gender,
    this.age,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.gymName,
    this.coachId,
    this.enrolledAt,
    required this.dailyCalorieGoal,
  });

  final String uid;
  final String displayName;
  final UserRole role;
  final String? email;
  final Gender? gender;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final ActivityLevel? activityLevel;
  final String? gymName;
  final String? coachId;
  final DateTime? enrolledAt;
  final int dailyCalorieGoal;

  bool get isMasterAdmin => role == UserRole.masterAdmin;
  bool get isCoach => role == UserRole.coach;
  bool get isTrainee => role == UserRole.trainee;

  bool get isEnrolledInGym {
    final coach = coachId?.trim();
    if (coach != null && coach.isNotEmpty) return true;

    final gym = gymName?.trim();
    return gym != null && gym.isNotEmpty;
  }

  String get rosterLabel => resolveRosterNameFromMap(toFirestoreMap());

  Map<String, dynamic> toFirestoreMap() => {
        'username': displayName,
        'displayName': displayName,
        if (email != null) 'email': email,
      };

  /// Reads the member-facing name directly from a Firestore user document map.
  static String resolveRosterNameFromMap(Map<String, dynamic> data) {
    final name = _findNameField(data);
    if (name != null) return name;

    final email = parseEmail(data);
    final prefix = emailPrefix(email);
    if (prefix.isNotEmpty) return prefix;

    return _scanDocumentForHumanName(data);
  }

  static String _scanDocumentForHumanName(Map<String, dynamic> data) {
    const skipKeys = {
      'role',
      'coachid',
      'gymname',
      'gender',
      'activitylevel',
      'uid',
      'id',
      'coachId',
      'gymName',
      'activityLevel',
    };

    for (final entry in data.entries) {
      if (skipKeys.contains(entry.key.toLowerCase())) continue;

      final value = _readStringValue(entry.value);
      if (value == null ||
          value.contains('@') ||
          _looksLikeUid(value) ||
          value.length < 2 ||
          value.length > 64) {
        continue;
      }

      if (RegExp(r'^[A-Za-z]').hasMatch(value)) {
        return value;
      }
    }

    for (final entry in data.entries) {
      if (entry.value is Map) {
        final nested = _scanDocumentForHumanName(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (nested.isNotEmpty) return nested;
      }
    }

    return '';
  }

  static String? _findNameField(Map<String, dynamic> data) {
    const orderedKeys = [
      'rosterDisplayName',
      'username',
      'userName',
      'displayName',
      'display_name',
      'name',
      'fullName',
      'traineeName',
      'nickName',
      'nickname',
      'firstName',
    ];

    for (final key in orderedKeys) {
      final value = _readStringFieldIgnoreCase(data, key);
      if (value != null && !_looksLikeUid(value)) {
        return value;
      }
    }

    final first = _readStringFieldIgnoreCase(data, 'firstName');
    final last = _readStringFieldIgnoreCase(data, 'lastName');
    if (first != null || last != null) {
      final combined = [first, last]
          .whereType<String>()
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .join(' ')
          .trim();
      if (combined.isNotEmpty && !_looksLikeUid(combined)) {
        return combined;
      }
    }

    for (final entry in data.entries) {
      if (entry.value is Map) {
        final nested = _findNameField(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (nested != null) return nested;
      }
    }

    return null;
  }

  static String? readStringField(Map<String, dynamic> data, String key) {
    return _readStringFieldIgnoreCase(data, key);
  }

  static String? _readStringField(Map<String, dynamic> data, String key) {
    return _readStringValue(data[key]);
  }

  static String? _readStringFieldIgnoreCase(
    Map<String, dynamic> data,
    String targetKey,
  ) {
    final direct = _readStringField(data, targetKey);
    if (direct != null) return direct;

    final lowerTarget = targetKey.toLowerCase();
    for (final entry in data.entries) {
      if (entry.key.toLowerCase() == lowerTarget) {
        return _readStringValue(entry.value);
      }
    }
    return null;
  }

  static String? _readStringValue(Object? raw) {
    if (raw == null) return null;
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String parseDisplayName(Map<String, dynamic> data) {
    return _findNameField(data) ?? '';
  }

  static String? parseEmail(Map<String, dynamic> data) {
    const orderedKeys = ['email', 'userEmail', 'mail', 'emailAddress'];

    for (final key in orderedKeys) {
      final value = _readStringFieldIgnoreCase(data, key);
      if (value != null && value.contains('@')) {
        return value;
      }
    }

    for (final entry in data.entries) {
      final value = _readStringValue(entry.value);
      if (value != null && value.contains('@')) {
        return value;
      }
      if (entry.value is Map) {
        final nested = parseEmail(Map<String, dynamic>.from(entry.value as Map));
        if (nested != null) return nested;
      }
    }

    return null;
  }

  static int parseCalorieGoal(
    Map<String, dynamic> data, {
    int fallback = Env.dailyCalorieGoal,
  }) {
    final target = (data['targetCalories'] as num?)?.round();
    if (target != null && target > 0) return target;

    final daily = (data['dailyCalorieGoal'] as num?)?.round();
    if (daily != null && daily > 0) return daily;

    return fallback > 0 ? fallback : Env.dailyCalorieGoal;
  }

  static String emailPrefix(String? email) {
    final value = email?.trim() ?? '';
    if (value.isEmpty) return '';
    final atIndex = value.indexOf('@');
    if (atIndex <= 0) return value;
    return value.substring(0, atIndex);
  }

  static bool looksLikeUid(String value) => _looksLikeUid(value);

  static bool _looksLikeUid(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 20) return false;
    return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(trimmed);
  }

  static String resolveRosterLabel({
    required String displayName,
    String? email,
  }) {
    return resolveRosterNameFromMap({
      'username': displayName,
      'displayName': displayName,
      if (email != null) 'email': email,
    });
  }

  /// Merges live Firestore data onto a seed snapshot without wiping known fields.
  static Map<String, dynamic> mergeUserData(
    Map<String, dynamic> seed,
    Map<String, dynamic>? live,
  ) {
    final merged = Map<String, dynamic>.from(seed);
    if (live == null) return merged;

    for (final entry in live.entries) {
      final value = entry.value;
      if (value == null) continue;

      if (value is String && value.trim().isEmpty) {
        continue;
      }

      merged[entry.key] = value;
    }

    return merged;
  }

  static String resolveRosterNameFromSources(
    Iterable<Map<String, dynamic>> sources,
  ) {
    for (final source in sources) {
      final label = resolveRosterNameFromMap(source);
      if (label.isNotEmpty) return label;
    }
    return '';
  }

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    final goal = UserProfile.parseCalorieGoal(data);

    DateTime? enrolledAt;
    final enrolledRaw = data['enrolledAt'];
    if (enrolledRaw is Timestamp) {
      enrolledAt = enrolledRaw.toDate();
    }

    return UserProfile(
      uid: uid,
      displayName: parseDisplayName(data),
      email: parseEmail(data),
      role: UserRole.fromString(data['role'] as String?),
      gender: data['gender'] != null
          ? Gender.fromString(data['gender'] as String?)
          : null,
      age: (data['age'] as num?)?.toInt(),
      heightCm: (data['height'] as num?)?.toDouble(),
      weightKg: (data['weight'] as num?)?.toDouble(),
      activityLevel: data['activityLevel'] != null
          ? ActivityLevel.fromString(data['activityLevel'] as String?)
          : null,
      gymName: _trimOrNull(data['gymName'] as String?),
      coachId: _trimOrNull(data['coachId'] as String?),
      enrolledAt: enrolledAt,
      dailyCalorieGoal: goal > 0 ? goal : Env.dailyCalorieGoal,
    );
  }

  static String? _trimOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
