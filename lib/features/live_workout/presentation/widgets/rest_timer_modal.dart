import 'dart:async';

import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/live_workout/providers/live_workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showRestTimerModal({
  required BuildContext context,
  required WidgetRef ref,
  required int durationMinutes,
  required String nextWorkoutLabel,
  required VoidCallback onStartNextSet,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    pageBuilder: (context, _, __) {
      return _RestTimerModal(
        durationMinutes: durationMinutes,
        nextWorkoutLabel: nextWorkoutLabel,
        onStartNextSet: onStartNextSet,
      );
    },
  );
}

class _RestTimerModal extends ConsumerStatefulWidget {
  const _RestTimerModal({
    required this.durationMinutes,
    required this.nextWorkoutLabel,
    required this.onStartNextSet,
  });

  final int durationMinutes;
  final String nextWorkoutLabel;
  final VoidCallback onStartNextSet;

  @override
  ConsumerState<_RestTimerModal> createState() => _RestTimerModalState();
}

class _RestTimerModalState extends ConsumerState<_RestTimerModal>
    with SingleTickerProviderStateMixin {
  late final int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _resolved = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimerExpired();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  Future<void> _onTimerExpired() async {
    if (_resolved) return;
    _resolved = true;
    await ref.read(liveWorkoutControllerProvider).markSlacking();
    if (mounted) {
      setState(() {});
    }
  }

  void _startNextSet() {
    if (_resolved) return;
    _resolved = true;
    _timer?.cancel();
    widget.onStartNextSet();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _displayTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isExpired => _remainingSeconds <= 0;

  @override
  Widget build(BuildContext context) {
    final expired = _isExpired;

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                expired ? 'Rest limit reached' : 'Rest Timer',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: expired ? AppColors.danger : AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                expired
                    ? 'Your coach has been notified. Get back to it!'
                    : 'Stay off your phone — recover, then hit the next set.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                  CurvedAnimation(
                    parent: _pulseController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (expired ? AppColors.danger : AppColors.primary)
                            .withValues(alpha: 0.25),
                        AppColors.surface,
                      ],
                    ),
                    border: Border.all(
                      color: (expired ? AppColors.danger : AppColors.primary)
                          .withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _displayTime,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: expired ? AppColors.danger : AppColors.textPrimary,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _MarkerRow(
                totalMinutes: widget.durationMinutes,
                remainingSeconds: _remainingSeconds,
              ),
              const Spacer(),
              if (expired)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'Status updated to SLACKING — coach alert sent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _startNextSet,
                  child: Text(
                    expired
                        ? 'Start Next Set'
                        : 'Start Next Set — ${widget.nextWorkoutLabel}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Next: ${widget.nextWorkoutLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkerRow extends StatelessWidget {
  const _MarkerRow({
    required this.totalMinutes,
    required this.remainingSeconds,
  });

  final int totalMinutes;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final markers = <int, String>{
      totalMinutes * 60: '${totalMinutes}m',
      120: '2m',
      60: '1m',
      30: '30s',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: markers.entries.map((entry) {
        final active = remainingSeconds <= entry.key && remainingSeconds > 0;
        final passed = remainingSeconds < entry.key;
        final color = passed
            ? AppColors.textSecondary.withValues(alpha: 0.4)
            : active
                ? AppColors.accent
                : AppColors.primary;

        return Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry.value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
