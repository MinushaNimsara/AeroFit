import 'package:aerofit/features/exercise_library/domain/exercise.dart';

/// Case/punctuation-insensitive token search for the exercise catalog.
class ExerciseSearch {
  ExerciseSearch._();

  static final _nonAlnum = RegExp(r'[^a-z0-9]+');
  static final _spaces = RegExp(r'\s+');

  /// Lowercase, strip punctuation to spaces, collapse whitespace.
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(_nonAlnum, ' ')
        .replaceAll(_spaces, ' ')
        .trim();
  }

  static List<String> tokens(String rawQuery) {
    final n = normalize(rawQuery);
    if (n.isEmpty) return const [];
    return n.split(' ').where((t) => t.isNotEmpty).toList(growable: false);
  }

  /// True when every query token appears somewhere in the exercise fields
  /// (order-independent). Empty query always matches.
  static bool matches(Exercise exercise, String rawQuery) {
    final queryTokens = tokens(rawQuery);
    if (queryTokens.isEmpty) return true;

    final haystack = normalize(
      [
        exercise.name,
        exercise.primaryMuscle,
        ...exercise.equipment,
        ...exercise.tags,
      ].join(' '),
    );

    for (final token in queryTokens) {
      if (!haystack.contains(token)) return false;
    }
    return true;
  }
}
