import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/live_workout/providers/live_workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Listens for coach nudges and shows a full-screen alert on the workout screen.
class CoachNudgeListener extends ConsumerStatefulWidget {
  const CoachNudgeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CoachNudgeListener> createState() => _CoachNudgeListenerState();
}

class _CoachNudgeListenerState extends ConsumerState<CoachNudgeListener> {
  var _overlayOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(liveWorkoutStatusProvider, (previous, next) {
      final triggered = next.valueOrNull?.nudgeTriggered == true;
      final wasTriggered = previous?.valueOrNull?.nudgeTriggered == true;
      if (triggered && !wasTriggered && !_overlayOpen) {
        _showNudgeOverlay();
      }
    });

    return widget.child;
  }

  Future<void> _showNudgeOverlay() async {
    if (!mounted || _overlayOpen) return;
    _overlayOpen = true;

    HapticFeedback.heavyImpact();
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}

    if (!mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (dialogContext, _, __) {
        return Material(
          color: AppColors.background,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.7),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.warning,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '🚨 Coach is watching you!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Stop slacking and start your next set!',
                    textAlign: TextAlign.center,
                    style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: AppColors.background,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text(
                        "I'm back — let's go",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    await ref.read(liveWorkoutControllerProvider).acknowledgeNudge();
    _overlayOpen = false;
  }
}
