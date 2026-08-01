import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/enrollment/providers/gym_enrollment_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EnrollScannerScreen extends ConsumerStatefulWidget {
  const EnrollScannerScreen({super.key});

  @override
  ConsumerState<EnrollScannerScreen> createState() =>
      _EnrollScannerScreenState();
}

class _EnrollScannerScreenState extends ConsumerState<EnrollScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    _handled = true;
    await _controller.stop();
    await ref.read(enrollmentScanProvider.notifier).enrollFromQr(raw);

    if (!mounted) return;
    final state = ref.read(enrollmentScanProvider);

    if (state.status == EnrollmentScanStatus.success) {
      await _showSuccessDialog(state);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message ?? 'Enrollment failed.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _handled = false;
      await _controller.start();
    }
  }

  Future<void> _showSuccessDialog(EnrollmentScanState state) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        icon: const Icon(Icons.verified_rounded, color: AppColors.win, size: 48),
        title: const Text('Member Enrolled'),
        content: Text(
          state.message ??
              'Successfully enrolled ${state.traineeName} into ${state.gymName}!',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(enrollmentScanProvider);
    final isProcessing = scanState.status == EnrollmentScanStatus.processing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan & Enroll Member'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.95),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isProcessing
                        ? 'Enrolling member…'
                        : 'Align the trainee\'s Gym Pass QR inside the frame',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(color: AppColors.primary),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
