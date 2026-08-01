import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/routine/domain/routine_task.dart';
import 'package:aerofit/features/routine/providers/tasks_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _quickAddTasks = [
  '12-Hour Deep Work Block',
  '15-Min Walking Break',
  'Drink 1L Water',
];

class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  final _taskController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _addTask(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a task before adding it to your routine.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uid = ref.read(authStateProvider).value?.uid;
    final repo = ref.read(tasksRepositoryProvider);
    if (uid == null || repo == null) return;

    setState(() => _isAdding = true);
    try {
      await repo.addTask(uid: uid, title: trimmed);
      _taskController.clear();
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _toggleTask(RoutineTask task, bool? value) async {
    if (value == null) return;
    final uid = ref.read(authStateProvider).value?.uid;
    final repo = ref.read(tasksRepositoryProvider);
    if (uid == null || repo == null) return;

    await repo.setCompleted(
      uid: uid,
      taskId: task.id,
      isCompleted: value,
    );
  }

  Future<void> _deleteTask(RoutineTask task) async {
    final uid = ref.read(authStateProvider).value?.uid;
    final repo = ref.read(tasksRepositoryProvider);
    if (uid == null || repo == null) return;

    await repo.deleteTask(uid: uid, taskId: task.id);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Routine'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick add',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final label in _quickAddTasks)
                      ActionChip(
                        label: Text(label),
                        avatar: const Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        backgroundColor: AppColors.surfaceElevated,
                        side: const BorderSide(color: Color(0xFF252B38)),
                        onPressed: _isAdding ? null : () => _addTask(label),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _isAdding ? null : _addTask,
                        decoration: InputDecoration(
                          hintText: 'Add a daily task…',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFF252B38)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFF252B38)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _isAdding
                          ? null
                          : () => _addTask(_taskController.text),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isAdding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Could not load tasks: $e',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 48,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add habits, work blocks, or walking breaks to track your day.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final completed = tasks.where((t) => t.isCompleted).length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '$completed of ${tasks.length} complete',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _TaskTile(
                            task: task,
                            onToggle: (v) => _toggleTask(task, v),
                            onDelete: () => _deleteTask(task),
                          )
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 40 * index),
                                duration: 280.ms,
                              )
                              .slideX(begin: 0.03, end: 0);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final RoutineTask task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onToggle(!task.isCompleted),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: task.isCompleted
                    ? AppColors.win.withValues(alpha: 0.35)
                    : const Color(0xFF252B38),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: onToggle,
                    activeColor: AppColors.win,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete task',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
