import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_category_visual.dart';
import 'package:aerofit/features/exercise_library/providers/exercise_library_providers.dart';
import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves exercise demo media in priority order:
/// 1. Network [imageUrl] (e.g. Cloudinary upload on a gym exercise)
/// 2. Bundled catalog asset from [exerciseId] → [Exercise.image]
/// 3. Category icon placeholder
///
/// Missing asset files fall back to the category icon — no crash.
/// Prefer wrapping with [ExerciseDemoStage] for on-screen presentation.
class ExerciseDemoMedia extends ConsumerWidget {
  const ExerciseDemoMedia({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.exerciseId,
    this.category,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.contain,
    this.clip = true,
  });

  /// Optional remote URL (Cloudinary / custom upload).
  final String? imageUrl;

  /// Bundled asset path (e.g. from [Exercise.image]) — skips catalog lookup.
  final String? assetPath;

  /// Catalog id used to resolve [Exercise.image] local asset path.
  final String? exerciseId;

  /// Optional category for placeholder when [exerciseId] is unknown.
  final String? category;

  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  /// When false, parent (e.g. [ExerciseDemoStage]) owns clipping.
  final bool clip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkUrl = imageUrl?.trim() ?? '';
    if (networkUrl.isNotEmpty) {
      return _framed(
        child: Image.network(
          networkUrl,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _loadingBox();
          },
          errorBuilder: (_, __, ___) => _catalogOrPlaceholder(ref),
        ),
      );
    }

    final directAsset = assetPath?.trim() ?? '';
    if (directAsset.isNotEmpty) {
      return _framed(
        child: Image.asset(
          directAsset,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              _placeholder(category ?? ''),
        ),
      );
    }

    return _catalogOrPlaceholder(ref);
  }

  Widget _catalogOrPlaceholder(WidgetRef ref) {
    final id = exerciseId?.trim() ?? '';
    if (id.isEmpty) {
      return _framed(child: _placeholder(category ?? ''));
    }

    final exerciseAsync = ref.watch(exerciseByIdProvider(id));
    return exerciseAsync.when(
      loading: () => _framed(child: _loadingBox()),
      error: (_, __) => _framed(child: _placeholder(category ?? '')),
      data: (exercise) {
        if (exercise == null) {
          return _framed(child: _placeholder(category ?? ''));
        }
        final path = exercise.image.trim();
        if (path.isEmpty) {
          return _framed(child: _placeholder(exercise.category));
        }
        return _framed(
          child: Image.asset(
            path,
            width: width,
            height: height,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _placeholder(exercise.category),
          ),
        );
      },
    );
  }

  Widget _framed({required Widget child}) {
    final Widget box = (width == null && height == null)
        ? SizedBox.expand(child: child)
        : SizedBox(width: width, height: height, child: child);
    if (!clip || borderRadius <= 0) return box;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: box,
    );
  }

  Widget _loadingBox() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _placeholder(String categoryName) {
    if (categoryName.trim().isNotEmpty) {
      return Center(
        child: ExerciseCategoryIcon(
          category: categoryName,
          size: (width ?? height ?? 72).clamp(40, 120),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: const Icon(
        Icons.fitness_center_rounded,
        color: AppColors.textSecondary,
        size: 28,
      ),
    );
  }
}
