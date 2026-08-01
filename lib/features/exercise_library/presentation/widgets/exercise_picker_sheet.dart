import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/exercise_library/domain/exercise.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_list_card.dart';
import 'package:aerofit/features/exercise_library/providers/exercise_library_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the picker in single-select mode — resolves with the tapped
/// exercise immediately, or `null` if dismissed.
Future<Exercise?> showSingleExercisePickerSheet(BuildContext context) async {
  final result = await showModalBottomSheet<List<Exercise>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ExercisePickerSheet(multiSelect: false),
  );
  return (result != null && result.isNotEmpty) ? result.first : null;
}

/// Opens the picker in multi-select mode — resolves with all checked
/// exercises once the coach taps "Done", or `null` if dismissed.
Future<List<Exercise>?> showMultiExercisePickerSheet(BuildContext context) {
  return showModalBottomSheet<List<Exercise>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ExercisePickerSheet(multiSelect: true),
  );
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet({required this.multiSelect});

  final bool multiSelect;

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  String _query = '';
  String? _category;
  final Map<String, Exercise> _selected = {};

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(exerciseLibraryProvider);
    final categories = ref.watch(exerciseCategoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.multiSelect
                      ? 'Add exercises from the library'
                      : 'Choose an exercise',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search exercises, muscles, equipment…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    const SizedBox(width: 8),
                    for (final category in categories) ...[
                      _CategoryChip(
                        label: category,
                        selected: _category == category,
                        onTap: () => setState(
                          () => _category = _category == category
                              ? null
                              : category,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFF252B38)),
              Expanded(
                child: libraryAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Could not load exercises: $e',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  data: (all) {
                    final query = _query.trim().toLowerCase();
                    final filtered = all.where((exercise) {
                      if (_category != null && exercise.category != _category) {
                        return false;
                      }
                      if (query.isEmpty) return true;
                      return exercise.name.toLowerCase().contains(query) ||
                          exercise.primaryMuscle.toLowerCase().contains(query) ||
                          exercise.equipment
                              .any((eq) => eq.toLowerCase().contains(query));
                    }).toList(growable: false);

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No exercises match your search.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        final isSelected = _selected.containsKey(exercise.id);
                        return ExerciseListCard(
                          exercise: exercise,
                          trailing: widget.multiSelect
                              ? Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.add_circle_outline_rounded,
                                  color: isSelected
                                      ? AppColors.win
                                      : AppColors.primary,
                                )
                              : null,
                          onTap: () {
                            if (widget.multiSelect) {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(exercise.id);
                                } else {
                                  _selected[exercise.id] = exercise;
                                }
                              });
                            } else {
                              Navigator.of(context).pop([exercise]);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              if (widget.multiSelect)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(context)
                            .pop(_selected.values.toList()),
                    child: Text(
                      _selected.isEmpty
                          ? 'Select at least one exercise'
                          : 'Add ${_selected.length} exercise${_selected.length == 1 ? '' : 's'}',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.18)
          : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : const Color(0xFF252B38),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
